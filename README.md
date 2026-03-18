# Claude Code Skills

Custom skills for [Claude Code](https://claude.ai/claude-code) that extend Claude's capabilities with Google Workspace workflows.

## Skills

### `gdoc-to-md`
Downloads a Google Doc as a local markdown file using the `gws` CLI.

**Triggers:** "pull from Docs", "download as markdown", "export Google Doc", "gdoc to md", "save doc locally"

**Usage:**
> "Download this Google Doc as markdown: https://docs.google.com/document/d/ABC123/edit"
> "Pull the latest version of this doc as a markdown file"

---

### `md-to-gdoc`
Uploads a local markdown file to Google Drive as a formatted Google Doc, or updates an existing Google Doc with new markdown content.

**Triggers:** "push to Drive", "create a Google Doc", "upload to Docs", "update the doc", "md to gdoc"

**Usage:**
> "Push report.md to Google Docs"
> "Update this Google Doc with the latest version of my markdown file"
> "Upload brand_guidelines.md to Drive and share it with the team"

---

### `gdoc-to-pdf`
Downloads a Google Doc as a PDF file using the `gws` CLI.

**Triggers:** "download as PDF", "export Google Doc to PDF", "gdoc to pdf"

**Usage:**
> "Export this Google Doc as a PDF: https://docs.google.com/document/d/ABC123/edit"
> "Download this doc as PDF and save it to ~/Downloads/report.pdf"

---

### `md-to-pdf`
Converts a local markdown file to a PDF by chaining two steps: uploading to Google Docs, then exporting as PDF. Uses Google's native rendering engine for high-quality output.

**Triggers:** "convert markdown to PDF", "export .md as PDF", "md to pdf"

**Usage:**
> "Convert report.md to PDF"
> "Export this markdown file as PDF and keep the Google Doc too"

---

### `site-analyzer`
Crawls and screenshots any website for UX analysis using the Cloudflare Browser Rendering API. Works with JS-heavy SPAs that normal fetch can't render. Captures full-page screenshots, section-specific screenshots (scrolled to each h2), and rendered HTML/Markdown content.

**Triggers:** "analyze this site", "screenshot this page", "crawl this URL", "UX analysis"

**Usage:**
> "Analyze the UX of https://deepgram.com"
> "Screenshot this competitor's pricing page"
> "Crawl this site and give me the rendered content"

---

## Requirements

- [Claude Code](https://claude.ai/claude-code) CLI installed
- [gws CLI](https://github.com/nicholasgasior/gws) installed and authenticated
  ```bash
  brew install gws
  ```
- Google Workspace credentials at `~/.config/gws/credentials.json` with `client_id`, `client_secret`, and `refresh_token`

## Installation

**Install all skills:**
```bash
git clone https://github.com/hasan-jilani/claude-skills /tmp/claude-skills
cp -r /tmp/claude-skills/gdoc-to-pdf ~/.claude/skills/
cp -r /tmp/claude-skills/md-to-pdf ~/.claude/skills/
```

**Install a single skill:**
```bash
# gdoc-to-pdf only
cp -r /tmp/claude-skills/gdoc-to-pdf ~/.claude/skills/

# md-to-pdf only
cp -r /tmp/claude-skills/md-to-pdf ~/.claude/skills/
```

Skills are picked up automatically — no restart required.
