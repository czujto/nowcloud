# nowcloud.pl

Personal and professional blog of Kamil Lygas, focused on Azure platform architecture, landing zones, sovereign cloud, networking, Azure Virtual Desktop and infrastructure as code.

The site is built with Jekyll and Type Theme and is compatible with GitHub Pages.

## Run Locally

Install Ruby and Bundler, then install the GitHub Pages dependency set:

```bash
bundle install
```

Build the site:

```bash
bundle exec jekyll build
```

Run a local development server:

```bash
bundle exec jekyll serve
```

The generated site is written to `_site/` and the local server is available at `http://127.0.0.1:4000/`.

## Content QA

Run the lightweight source-content check from PowerShell:

```powershell
.\scripts\check-content.ps1
```

The script validates readable front matter, required post and topic-page metadata, common unfinished placeholders, title spelling and duplicated excerpt openings.

To add a new article, create a dated Markdown file under `_posts/` with `layout`, `date`, `title`, `description`, `categories` and `tags` front matter. Use an explicit `permalink` when a stable public route is required.

Existing published posts must retain their public permalinks. If a title, category or filename changes, preserve the current route with explicit `permalink` front matter before publishing.

## GitHub Pages Deployment

GitHub Pages builds this Jekyll repository using the `github-pages` gem declared in `Gemfile`. No custom GitHub Actions workflow is currently required.

The article set visible on the published site at the time of this refresh is present on the `workinprogress` branch. The SEO refresh branch `seo-refresh-nowcloud` is therefore based on `workinprogress` and should be merged through review into the branch selected as the GitHub Pages publishing source.

Before merging, confirm the Pages source branch in **Repository Settings > Pages** and ensure it corresponds to the intended production content.

## Domain Configuration

The intended primary domain is `nowcloud.pl`:

- `CNAME` sets the GitHub Pages custom domain.
- `_config.yml` sets the canonical `url` used for metadata, sitemap and feed generation.
- `robots.txt` advertises `https://nowcloud.pl/sitemap.xml`.

DNS records and the GitHub Pages custom-domain/HTTPS settings are configured outside this repository. Verify that DNS for `nowcloud.pl` points to GitHub Pages, that the custom domain in Pages settings is `nowcloud.pl`, that HTTPS is enforced once the certificate is available, and that any `nowcloud.co.uk` traffic is redirected to the primary domain if it is still retained.
