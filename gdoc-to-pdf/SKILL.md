---
name: gdoc-to-pdf
description: Download a Google Doc as a PDF file using the gws CLI. Use when the user wants to export or save a Google Doc as PDF, mentions "download as PDF", "export Google Doc to PDF", "gdoc to pdf", or provides a Google Doc URL and wants a PDF output.
allowed-tools: Bash
---

# Download Google Doc as PDF

Export a Google Doc to PDF using the `gws` CLI.

## Command

```bash
gws drive files export \
  --params '{"fileId": "FILE_ID", "mimeType": "application/pdf"}' \
  -o output.pdf
```

## Steps

1. **Extract the file ID** from the Google Doc URL or use the provided ID directly.
   - URL format: `https://docs.google.com/document/d/FILE_ID/edit`
   - Extract the segment between `/d/` and the next `/`

2. **Determine output path** — use what the user specifies, or default to the current working directory using the doc's file ID as the filename: `FILE_ID.pdf`

3. **Run the export command** with the extracted file ID and output path.

4. **Confirm success** — report the output file path to the user.

## Example

User provides: `https://docs.google.com/document/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms/edit`

```bash
gws drive files export \
  --params '{"fileId": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms", "mimeType": "application/pdf"}' \
  -o my_doc.pdf
```
