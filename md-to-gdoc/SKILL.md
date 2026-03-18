---
name: md-to-gdoc
description: When the user wants to upload a markdown file to Google Drive as a formatted Google Doc, or update an existing Google Doc with new markdown content. Also use when the user mentions "push to Drive," "create a Google Doc," "upload to Docs," "update the doc," "markdown to Google Doc," "md to gdoc," or wants to share a local markdown file as a Google Doc with collaborators.
version: 2.0.0
tools: Bash, Read, Glob
---

# Markdown to Google Doc Skill

Upload a local markdown file to Google Drive as a properly formatted Google Doc, or update an existing Google Doc with new markdown content. Uses Google's native markdown import for correct formatting (headings, bold, lists, nested bullets, horizontal rules, links, etc.).

## Modes

### Mode 1: Create new Google Doc (default)
Use when the user says "push to docs", "upload to drive", "create a google doc", etc.

### Mode 2: Update existing Google Doc
Use when the user says "update the doc", "push changes to [doc link]", "replace content on [doc]", or provides a Google Doc URL/ID to update. This replaces the document content but preserves the file ID, link, and permissions. Note: this will remove any comments on the doc (warn the user — suggest pulling comments first with /gdoc-comments).

## Prerequisites

- Google Workspace CLI credentials must exist at `~/.config/gws/credentials.json` with `client_id`, `client_secret`, and `refresh_token` fields.
- The credentials file must have Drive API scope (`https://www.googleapis.com/auth/drive`).

## Process

### 1. Identify the file

Determine which markdown file to upload. The user may specify:
- A file path (absolute or relative)
- A file name to search for in the current project
- "This file" referring to a file recently discussed

If the path is ambiguous, use Glob to find the file. Confirm with the user if multiple matches exist.

### 2. Determine create vs. update mode

- If the user provides a Google Doc URL or file ID → **update mode**
- Otherwise → **create mode**

Extract file ID from Google Doc URLs:
- `https://docs.google.com/document/d/{fileId}/edit` → extract `{fileId}`

### 3. Determine the Google Doc name (create mode only)

Default to the markdown file's name without the `.md` extension. The user may override this.

### 4. Optional: Target folder (create mode only)

If the user specifies a Drive folder (by name or ID), include the folder as a parent. To find a folder by name:

```bash
TOKEN=$(<get token as below>)
curl -s "https://www.googleapis.com/drive/v3/files?q=name%3D'FOLDER_NAME'+and+mimeType%3D'application/vnd.google-apps.folder'&fields=files(id,name)" \
  -H "Authorization: Bearer $TOKEN"
```

### 5. Get an OAuth access token

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

### 6a. Create new Google Doc

Upload with `mimeType: application/vnd.google-apps.document` (target format) and `type=text/markdown` (source format). Google Drive handles the markdown-to-Doc conversion natively.

**Without a target folder:**
```bash
curl -s -X POST \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
  -H "Authorization: Bearer $TOKEN" \
  -F "metadata={\"name\": \"DOC_NAME\", \"mimeType\": \"application/vnd.google-apps.document\"};type=application/json;charset=UTF-8" \
  -F "file=@/path/to/file.md;type=text/markdown"
```

**With a target folder:**
```bash
curl -s -X POST \
  "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
  -H "Authorization: Bearer $TOKEN" \
  -F "metadata={\"name\": \"DOC_NAME\", \"mimeType\": \"application/vnd.google-apps.document\", \"parents\": [\"FOLDER_ID\"]};type=application/json;charset=UTF-8" \
  -F "file=@/path/to/file.md;type=text/markdown"
```

### 6b. Update existing Google Doc

Replace the content of an existing file. This preserves file ID, link, permissions, and revision history. Comments will be lost.

**Important:** Before updating, warn the user if they haven't pulled comments yet.

```bash
curl -s -X PATCH \
  "https://www.googleapis.com/upload/drive/v3/files/{fileId}?uploadType=media" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: text/markdown" \
  --data-binary @/path/to/file.md
```

### 7. Report the result

**Create mode:**
```
Created Google Doc: "Document Name"
Link: https://docs.google.com/document/d/{id}/edit
```

**Update mode:**
```
Updated Google Doc: "Document Name"
Link: https://docs.google.com/document/d/{id}/edit
```

### 8. Optional: Set permissions (create mode, or if user requests)

If the user wants to share the doc, use the Drive permissions API:

**Share with specific people:**
```bash
curl -s -X POST \
  "https://www.googleapis.com/drive/v3/files/{fileId}/permissions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role": "writer", "type": "user", "emailAddress": "user@example.com"}'
```

**Share with entire domain:**
```bash
curl -s -X POST \
  "https://www.googleapis.com/drive/v3/files/{fileId}/permissions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role": "writer", "type": "domain", "domain": "deepgram.com"}'
```

**Share with anyone who has the link:**
```bash
curl -s -X POST \
  "https://www.googleapis.com/drive/v3/files/{fileId}/permissions" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"role": "reader", "type": "anyone"}'
```

Roles: `reader`, `commenter`, `writer`, `owner`.

## Error Handling

- **401 Unauthorized:** Credentials may be expired. Suggest running `gws auth login --no-encrypt` in a terminal, then exporting credentials with `gws auth export > ~/.config/gws/credentials.json`.
- **403 Forbidden:** Insufficient Drive scope. Suggest re-authenticating with Drive scope.
- **404 Folder not found:** If target folder ID is invalid, search for the folder by name and confirm with user.
- **File not found:** If the markdown file path doesn't exist, use Glob to search for it.
