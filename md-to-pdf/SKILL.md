---
name: md-to-pdf
description: "Convert a local markdown file to a PDF by chaining two steps: uploading to Google Docs then exporting as PDF. Use when the user wants to convert markdown to PDF, export a .md file as PDF, or generate a PDF from markdown content. Produces a high-quality PDF using Google's native rendering."
allowed-tools: Bash, Read, Glob
---

# Markdown to PDF

Convert a local markdown file to PDF by chaining two skills:
1. **md-to-gdoc** — upload the markdown file to Google Drive as a Google Doc
2. **gdoc-to-pdf** — export that Google Doc as a PDF using the `gws` CLI

This approach uses Google's native rendering engine, producing better formatting than local converters.

## Workflow

### Step 1: Upload markdown to Google Doc (md-to-gdoc)

Get an OAuth token and upload the markdown file as a new Google Doc:

```bash
TOKEN=$(python3 -c "
import json, urllib.request, urllib.parse
creds = json.load(open('$HOME/.config/gws/credentials.json'))
data = urllib.parse.urlencode({
    'client_id': creds['client_id'],
    'client_secret': creds['client_secret'],
    'refresh_token': creds['refresh_token'],
    'grant_type': 'refresh_token'
}).encode()
req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
resp = json.loads(urllib.request.urlopen(req).read())
print(resp['access_token'])
")

curl -s -X POST \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
  -H "Authorization: Bearer $TOKEN" \
  -F "metadata={\"name\": \"DOC_NAME\", \"mimeType\": \"application/vnd.google-apps.document\"};type=application/json;charset=UTF-8" \
  -F "file=@/path/to/file.md;type=text/markdown"
```

Capture the `id` field from the JSON response — this is the `FILE_ID` for step 2.

### Step 2: Export Google Doc as PDF (gdoc-to-pdf)

Use the file ID from step 1 to export as PDF:

```bash
gws drive files export \
  --params '{"fileId": "FILE_ID", "mimeType": "application/pdf"}' \
  -o output.pdf
```

Default output path: same directory as the input `.md` file, with `.pdf` extension.

### Step 3: Clean up (optional)

If the user only wants the PDF and not a permanent Google Doc, delete the intermediate doc:

```bash
gws drive files delete --params '{"fileId": "FILE_ID"}'
```

Ask the user whether to keep or delete the intermediate Google Doc — default is to **delete** it unless they say otherwise.

### Step 4: Confirm

Report the output PDF path to the user.

## Example

Input: `/Users/hjilani/projects/report.md`
Output: `/Users/hjilani/projects/report.pdf`

1. Upload `report.md` → Google Doc (captures file ID)
2. Export Google Doc → `report.pdf`
3. Delete the temporary Google Doc (unless user wants to keep it)
