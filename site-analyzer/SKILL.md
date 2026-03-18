---
name: site-analyzer
description: "Crawl and screenshot any website for UX analysis using the Cloudflare Browser Rendering API. Use when the user wants to analyze a website's UX, capture screenshots of a JS-rendered site, crawl a competitor's site, or says 'analyze this site,' 'screenshot this page,' 'crawl this URL,' or '/site-analyzer URL'. Captures full-page screenshots, section-specific screenshots (scrolled to each h2), and rendered HTML/Markdown content. Works with JS-heavy SPAs that normal fetch can't render."
---

# Site Analyzer

Capture screenshots and rendered content from any website via the Cloudflare Browser Rendering REST API. Works with JS-heavy sites that normal HTTP fetches can't render.

## Prerequisites

Environment variables (in `.env` or shell profile):
- `CLOUDFLARE_ACCOUNT_ID`
- `CLOUDFLARE_API_TOKEN` (needs "Browser Rendering - Edit" permission)

## How to Use

Run the bundled script with the target URL:

```bash
source .env 2>/dev/null  # load env vars if in .env
bash ~/.claude/skills/site-analyzer/scripts/analyze-site.sh <url> [output-dir]
```

Default output directory: `docs/site-analysis/<domain>/`

## What It Captures

1. **Full-page screenshot** — PNG, 1920x1080 viewport, full page scroll
2. **Above-fold screenshot** — viewport only, no scroll
3. **Section screenshots** — detects h2 headings from crawled markdown, scrolls to each, screenshots
4. **Rendered HTML** — full DOM after JS execution
5. **Rendered Markdown** — text content from rendered page
6. **Raw crawl JSON** — complete API response

## Output

```
docs/site-analysis/<domain>/
  screenshots/
    00-above-fold.png
    01-full-page.png
    02-<section-name>.png
    ...
  content.md
  content.html
  crawl-raw.json
```

## After Running

- Read screenshots with the Read tool to see visual design
- Read `content.md` for page structure, navigation, sections, text
- Read `content.html` for component hierarchy, CSS classes, interactive elements

## Rate Limits

Free Cloudflare plan: 12s delay between screenshots (built in), 5 crawl jobs/day.
