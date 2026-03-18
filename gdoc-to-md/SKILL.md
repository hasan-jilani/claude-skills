---
name: gdoc-to-md
description: When the user wants to download a Google Doc as a local markdown file. Also use when the user mentions "pull from Docs," "download as markdown," "export Google Doc," "gdoc to md," "save doc locally," or wants to get the latest version of a Google Doc as markdown.
version: 1.0.0
tools: Bash, Write
---

# Google Doc to Markdown Skill

Download a Google Doc as a markdown file to the local filesystem. Uses Google Drive's native export to markdown format.

## Prerequisites

- Google Workspace CLI credentials must exist at `~/.config/gws/credentials.json` with `client_id`, `client_secret`, and `refresh_token` fields.
- The credentials file must have Drive API scope (`https://www.googleapis.com/auth/drive`).

## Process

### 1. Identify the Google Doc

The user may provide:
- A Google Doc URL (e.g., `https://docs.google.com/document/d/{fileId}/edit`)
- A file ID directly
- A document name to search for in Drive

**Extract file ID from URL:**
- `https://docs.google.com/document/d/{fileId}/edit` → extract `{fileId}`
- `https://docs.google.com/document/d/{fileId}/edit?usp=sharing` → extract `{fileId}`

**Search by name (if no URL/ID provided):**
```bash
curl -s "https://www.googleapis.com/drive/v3/files?q=name+contains+'SEARCH_TERM'+and+mimeType%3D'application/vnd.google-apps.document'&fields=files(id,name,modifiedTime)&orderBy=modifiedTime+desc&pageSize=5" \
  -H "Authorization: Bearer $TOKEN"
```

If multiple results, show them to the user and ask which one.

### 2. Determine local file path

Default behavior:
- Use the Google Doc's name, converted to a filename-safe format (lowercase, spaces to underscores, remove special chars), with `.md` extension
- Save to the current working directory

The user may override the filename or path.

### 3. Get an OAuth access token

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
```

### 4. Export the Google Doc as markdown

```bash
curl -s "https://www.googleapis.com/drive/v3/files/{fileId}/export?mimeType=text/markdown" \
  -H "Authorization: Bearer $TOKEN" \
  -o /path/to/output.md
```

**Other export formats available (if user requests):**
- `text/plain` — plain text
- `text/html` — HTML
- `application/pdf` — PDF
- `application/vnd.openxmlformats-officedocument.wordprocessingml.document` — DOCX

### 5. Verify and report

Check that the file was created and has content:

```bash
wc -l /path/to/output.md
```

Display:
```
Downloaded: "Document Name"
Saved to: /path/to/output.md (X lines)
```

If the file already exists locally, warn the user before overwriting.

## Error Handling

- **401 Unauthorized:** Credentials may be expired. Suggest re-authenticating.
- **404 Not Found:** File ID is invalid or user doesn't have access. Confirm the URL/ID.
- **Empty file:** The export succeeded but returned no content. The doc may be empty or in a format that doesn't export to markdown well (e.g., all images).
- **Multiple search results:** Show the user all matches with names and modified dates, ask them to pick.
