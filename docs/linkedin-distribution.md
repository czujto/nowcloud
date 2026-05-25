# LinkedIn Distribution Guide

This guide provides a repeatable, professional way to share new public Azure architecture articles without overstating claims or publishing sensitive context.

## Launch Post Template

```text
New architecture note: [Article title]

[One sentence describing the architecture problem.]

In this article I cover:
- [decision or pattern 1]
- [decision or pattern 2]
- [production consideration]

Read the full note: [URL with campaign tracking]

#Azure #AzureLandingZones #CloudArchitecture #PlatformEngineering #Terraform
```

## Follow-Up Insight Post Template

Publish this after readers have had time to engage with the initial article.

```text
One practical observation from [Article title]:

[Short architecture insight or trade-off in two to four sentences.]

The useful question for a platform team is: [decision question]?

Supporting architecture note: [URL with campaign tracking]

#Azure #AzureLandingZones #CloudArchitecture #PlatformEngineering #Terraform
```

## UTM Examples

Use campaign tracking consistently so that GA4 can distinguish distribution from organic discovery:

```text
https://nowcloud.pl/azure/landing-zones/2026/05/25/designing-azure-landing-zones-for-product-teams.html?utm_source=linkedin&utm_medium=social&utm_campaign=azure_policy_as_code
```

For a second LinkedIn post about the same article, keep the campaign stable and distinguish the creative where useful:

```text
?utm_source=linkedin&utm_medium=social&utm_campaign=azure_policy_as_code&utm_content=insight_followup
```

## Default Hashtags

- `#Azure`
- `#AzureLandingZones`
- `#CloudArchitecture`
- `#PlatformEngineering`
- `#Terraform`

Select three to five relevant hashtags rather than adding unrelated terms.

## Weekly Rhythm

- Publication day: share the article with its core problem and key decisions.
- Two to four days later: share one focused design insight or common failure mode.
- End of week: respond to public discussion and update relevant internal links if the topic connects to an existing note.
- After 7 to 14 days: review GA4 and Google Search Console signals to understand discovery and engagement.
