#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <youtube_url_or_id> <slug> [title]"
  exit 1
fi

URL="$1"
SLUG="$2"
TITLE="${3:-}"
WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"

bash "$WS/scripts/ingest_video_source.sh" "$URL" "$SLUG" "$TITLE"
python3 "$WS/scripts/source_adapt_recommend.py" --latest 5 --queue 2

echo "Source ingestion + recommendation loop complete."
