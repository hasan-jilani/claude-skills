#!/bin/bash
# Site Analyzer — Screenshots + crawls a JS-rendered website via Cloudflare Browser Rendering API
# Usage: ./analyze-site.sh <url> [output-dir]

set -e

URL="${1:?Usage: analyze-site.sh <url> [output-dir]}"
DOMAIN=$(echo "$URL" | sed -E 's|https?://([^/]+).*|\1|' | sed 's/[^a-zA-Z0-9.-]/_/g')
OUTPUT_DIR="${2:-docs/site-analysis/$DOMAIN}"
DELAY=12  # seconds between screenshot requests (free tier rate limit)

# Cloudflare config from environment
CF_ACCOUNT="${CLOUDFLARE_ACCOUNT_ID:?Set CLOUDFLARE_ACCOUNT_ID env var}"
CF_TOKEN="${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN env var}"
SS_URL="https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT}/browser-rendering/screenshot"
CRAWL_URL="https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT}/browser-rendering/crawl"
AUTH="Authorization: Bearer ${CF_TOKEN}"

mkdir -p "${OUTPUT_DIR}/screenshots"

echo "=== Site Analyzer ==="
echo "URL: $URL"
echo "Output: $OUTPUT_DIR"
echo ""

# 1. Full page screenshot
echo "[1] Full page screenshot..."
curl -s -X POST "$SS_URL" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d "{
    \"url\": \"$URL\",
    \"screenshotOptions\": {\"fullPage\": true},
    \"gotoOptions\": {\"waitUntil\": \"networkidle0\", \"timeout\": 45000},
    \"viewport\": {\"width\": 1920, \"height\": 1080}
  }" -o "${OUTPUT_DIR}/screenshots/01-full-page.png"

SIZE=$(wc -c < "${OUTPUT_DIR}/screenshots/01-full-page.png")
if [ "$SIZE" -lt 500 ]; then
  echo "  ERROR: Screenshot failed — $(cat "${OUTPUT_DIR}/screenshots/01-full-page.png")"
  exit 1
fi
echo "  Saved (${SIZE} bytes)"

# 2. Crawl for HTML + Markdown
echo "[2] Crawling rendered content..."
sleep "$DELAY"
CRAWL_RESPONSE=$(curl -s -X POST "$CRAWL_URL" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d "{
    \"url\": \"$URL\",
    \"limit\": 1,
    \"render\": true,
    \"formats\": [\"html\", \"markdown\"],
    \"gotoOptions\": {\"waitUntil\": \"networkidle0\", \"timeout\": 45000}
  }")

JOB_ID=$(echo "$CRAWL_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',''))" 2>/dev/null)
if [ -z "$JOB_ID" ] || [ "$JOB_ID" = "None" ]; then
  echo "  ERROR: Crawl failed — $CRAWL_RESPONSE"
  exit 1
fi
echo "  Job ID: $JOB_ID"

# Poll until complete
for i in $(seq 1 12); do
  sleep 5
  STATUS=$(curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT}/browser-rendering/crawl/${JOB_ID}?limit=1" \
    -H "$AUTH" | python3 -c "import sys,json; print(json.load(sys.stdin).get('result',{}).get('status','unknown'))" 2>/dev/null)
  echo "  Status: $STATUS"
  if [ "$STATUS" = "completed" ] || [ "$STATUS" = "errored" ]; then break; fi
done

# Fetch full results
curl -s "https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT}/browser-rendering/crawl/${JOB_ID}" \
  -H "$AUTH" -o "${OUTPUT_DIR}/crawl-raw.json"

# Extract markdown and HTML
python3 -c "
import json, sys
data = json.load(open('${OUTPUT_DIR}/crawl-raw.json'))
records = data.get('result', {}).get('records', [])
for r in records:
    if r.get('markdown'):
        open('${OUTPUT_DIR}/content.md', 'w').write(r['markdown'])
        print(f'  Saved content.md ({len(r[\"markdown\"])} chars)')
    if r.get('html'):
        open('${OUTPUT_DIR}/content.html', 'w').write(r['html'])
        print(f'  Saved content.html ({len(r[\"html\"])} chars)')
if not records:
    print('  WARNING: No records in crawl response')
"

# 3. Section screenshots — scroll to each h2
echo "[3] Section screenshots..."

# Extract h2 headings from markdown
HEADINGS=$(python3 -c "
import re
try:
    md = open('${OUTPUT_DIR}/content.md').read()
    headings = re.findall(r'^## (.+)$', md, re.MULTILINE)
    for h in headings:
        h = h.strip()
        if h and len(h) < 80:
            print(h)
except: pass
")

if [ -z "$HEADINGS" ]; then
  echo "  No h2 headings found, skipping section screenshots"
else
  N=2
  while IFS= read -r HEADING; do
    N=$((N + 1))
    SAFE_NAME=$(echo "$HEADING" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | head -c 40)
    echo "  [${N}] ${HEADING}..."
    sleep "$DELAY"

    ESCAPED_HEADING=$(echo "$HEADING" | sed 's/"/\\"/g')
    curl -s -X POST "$SS_URL" \
      -H "$AUTH" -H "Content-Type: application/json" \
      -d "{
        \"url\": \"$URL\",
        \"gotoOptions\": {\"waitUntil\": \"networkidle0\", \"timeout\": 45000},
        \"viewport\": {\"width\": 1920, \"height\": 1080},
        \"addScriptTag\": [{\"content\": \"document.querySelectorAll('h2').forEach(h => { if(h.textContent.includes('${ESCAPED_HEADING}')) h.scrollIntoView({behavior:'instant', block:'start'}); });\"}]
      }" -o "${OUTPUT_DIR}/screenshots/$(printf '%02d' $N)-${SAFE_NAME}.png"

    FSIZE=$(wc -c < "${OUTPUT_DIR}/screenshots/$(printf '%02d' $N)-${SAFE_NAME}.png")
    if [ "$FSIZE" -lt 500 ]; then
      echo "    WARN: May have failed (${FSIZE} bytes)"
    else
      echo "    Saved (${FSIZE} bytes)"
    fi
  done <<< "$HEADINGS"
fi

# 4. Above-fold viewport screenshot
echo "[$(($N + 1))] Above-fold viewport..."
sleep "$DELAY"
curl -s -X POST "$SS_URL" \
  -H "$AUTH" -H "Content-Type: application/json" \
  -d "{
    \"url\": \"$URL\",
    \"gotoOptions\": {\"waitUntil\": \"networkidle0\", \"timeout\": 45000},
    \"viewport\": {\"width\": 1920, \"height\": 1080}
  }" -o "${OUTPUT_DIR}/screenshots/00-above-fold.png"
echo "  Saved"

echo ""
echo "=== Complete ==="
echo "Screenshots: ${OUTPUT_DIR}/screenshots/"
echo "Markdown:    ${OUTPUT_DIR}/content.md"
echo "HTML:        ${OUTPUT_DIR}/content.html"
echo "Raw crawl:   ${OUTPUT_DIR}/crawl-raw.json"
ls -la "${OUTPUT_DIR}/screenshots/"
