[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([string]$Message)
    $failures.Add($Message)
}

function Get-FrontMatter {
    param([string]$Path)

    $content = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ($content -notmatch '\A---\r?\n(?<yaml>[\s\S]*?)\r?\n---\r?\n') {
        Add-Failure "Invalid or compressed front matter: $Path"
        return $null
    }

    return @{
        Content = $content
        Yaml = $Matches.yaml
        Body = $content.Substring($Matches[0].Length)
    }
}

function Assert-Key {
    param(
        [string]$Path,
        [string]$Yaml,
        [string]$Key
    )

    if ($Yaml -notmatch "(?m)^$([regex]::Escape($Key)):\s*\S") {
        Add-Failure "Missing '$Key' front matter in $Path"
    }
}

$textFiles = Get-ChildItem -LiteralPath $repositoryRoot -Recurse -File |
    Where-Object { $_.Extension -in ".md", ".html", ".yml", ".txt" -and $_.FullName -notmatch '[\\/](?:_site|\.git)[\\/]' }

foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if ($content -match '(?i)\bTODO\b|\bTBD\b|You Thanks|lorem ipsum') {
        Add-Failure "Placeholder or unfinished text detected: $($file.FullName)"
    }

    if ($content -match '(?m)^---[ \t]+layout:') {
        Add-Failure "Compressed front matter opening detected: $($file.FullName)"
    }

    if ($content -match '\A---(?:\r?\n|[ \t])') {
        $null = Get-FrontMatter -Path $file.FullName
    }
}

$postsPath = Join-Path $repositoryRoot "_posts"
foreach ($post in Get-ChildItem -LiteralPath $postsPath -Filter "*.md" -File) {
    $frontMatter = Get-FrontMatter -Path $post.FullName
    if ($null -eq $frontMatter) {
        continue
    }

    foreach ($key in "title", "description", "date", "categories", "tags") {
        Assert-Key -Path $post.FullName -Yaml $frontMatter.Yaml -Key $key
    }

    if ($frontMatter.Yaml -match '(?m)^title:\s*.*Continuos') {
        Add-Failure "Title contains the 'Continuos' typo: $($post.FullName)"
    }

    if ($frontMatter.Body -match '(?s)^(?<intro>.+?)\r?\n\s*<!--more-->\s*\r?\n(?<after>[\s\S]*)$') {
        $intro = ($Matches.intro -replace '\s+', ' ').Trim()
        $after = ($Matches.after -replace '\s+', ' ').Trim()
        if ($intro.Length -gt 30 -and $after.StartsWith($intro)) {
            Add-Failure "Duplicated opening text after excerpt marker: $($post.FullName)"
        }
    }
}

$topicPages = @(
    "azure-landing-zones.md",
    "sovereign-cloud.md",
    "azure-virtual-desktop.md",
    "azure-networking.md",
    "identity-security.md",
    "infrastructure-as-code.md",
    "platform-engineering.md"
)

foreach ($topic in $topicPages) {
    $path = Join-Path $repositoryRoot $topic
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "Missing topic page: $path"
        continue
    }

    $frontMatter = Get-FrontMatter -Path $path
    if ($null -ne $frontMatter) {
        Assert-Key -Path $path -Yaml $frontMatter.Yaml -Key "title"
        Assert-Key -Path $path -Yaml $frontMatter.Yaml -Key "description"
    }
}

$publishedPillarPosts = @(
    "2026-05-25-designing-azure-landing-zones-for-product-teams.md",
    "2026-05-25-private-dns-at-scale-in-azure-landing-zones.md"
)

foreach ($pillarPost in $publishedPillarPosts) {
    $path = Join-Path $postsPath $pillarPost
    $frontMatter = Get-FrontMatter -Path $path
    if ($null -ne $frontMatter -and $frontMatter.Yaml -match '(?m)^published:\s*false\s*$') {
        Add-Failure "Published pillar post is marked as draft: $path"
    }
}

$requiredDiscoveryFiles = @(
    "robots.txt",
    "llms.txt",
    "llms-full.txt"
)

foreach ($requiredFile in $requiredDiscoveryFiles) {
    $path = Join-Path $repositoryRoot $requiredFile
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "Missing discovery file: $path"
        continue
    }

    $frontMatter = Get-FrontMatter -Path $path
    if ($null -eq $frontMatter) {
        continue
    }

    Assert-Key -Path $path -Yaml $frontMatter.Yaml -Key "layout"
    Assert-Key -Path $path -Yaml $frontMatter.Yaml -Key "permalink"

    if ([string]::IsNullOrWhiteSpace($frontMatter.Body)) {
        Add-Failure "Discovery file has no readable body content: $path"
    }
}

$schemaIncludes = @(
    "schema-person.html",
    "schema-website.html",
    "schema-blogposting.html"
)

foreach ($schemaInclude in $schemaIncludes) {
    $path = Join-Path (Join-Path $repositoryRoot "_includes") $schemaInclude
    if (-not (Test-Path -LiteralPath $path)) {
        Add-Failure "Missing schema include: $path"
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($content) -or $content -notmatch 'application/ld\+json') {
        Add-Failure "Schema include is empty or does not contain JSON-LD: $path"
    }
}

$publicCrawlFiles = [System.Collections.Generic.List[string]]::new()
foreach ($publicFile in @(
    "_config.yml",
    "robots.txt",
    "index.html",
    "about.md",
    "contact.md",
    "topics.md",
    "author\kamil-lygas.md"
) + $topicPages) {
    $publicCrawlFiles.Add($publicFile)
}

foreach ($publicDirectory in "_posts", "_includes", "_layouts") {
    $directoryPath = Join-Path $repositoryRoot $publicDirectory
    foreach ($file in Get-ChildItem -LiteralPath $directoryPath -File) {
        $publicCrawlFiles.Add($file.FullName)
    }
}

foreach ($publicFile in $publicCrawlFiles) {
    if ([System.IO.Path]::IsPathRooted($publicFile)) {
        $path = $publicFile
    } else {
        $path = Join-Path $repositoryRoot $publicFile
    }
    if (-not (Test-Path -LiteralPath $path)) {
        continue
    }

    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($content -match '(?i)\bnoindex\b|\bnofollow\b') {
        Add-Failure "Index-blocking directive text detected in public source: $path"
    }
}

$robotsPath = Join-Path $repositoryRoot "robots.txt"
$robots = Get-Content -LiteralPath $robotsPath -Raw -Encoding UTF8
if ($robots -match '(?im)^\s*Disallow:\s*/\s*$') {
    Add-Failure "robots.txt blocks public crawling with Disallow: /"
}

$homePagePath = Join-Path $repositoryRoot "index.html"
$homePage = Get-Content -LiteralPath $homePagePath -Raw -Encoding UTF8
if ($homePage -match '(?m)^# Kamil Lygas[ \t]+##') {
    Add-Failure "Collapsed homepage headings detected: $homePagePath"
}

foreach ($requiredHeading in "<h1>Kamil Lygas</h1>", "<h2>What I Write About</h2>", "<h2>Featured Topics</h2>") {
    if ($homePage -notmatch [regex]::Escape($requiredHeading)) {
        Add-Failure "Missing rendered homepage heading '$requiredHeading': $homePagePath"
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "Content QA passed: front matter, metadata, placeholders and duplicate openings checked."
