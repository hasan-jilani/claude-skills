# Claude Code Skills

Custom skills for [Claude Code](https://claude.ai/claude-code) that extend Claude's capabilities with Google Workspace workflows.

## Skills

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
