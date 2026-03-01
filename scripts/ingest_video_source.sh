#!/usr/bin/env bash
set -euo pipefail

SOURCE_INPUT="${1:-}"
SLUG="${2:-}"
TITLE="${3:-}"

if [[ -z "$SOURCE_INPUT" || -z "$SLUG" ]]; then
  cat <<'USAGE' >&2
Usage: ingest_video_source.sh <youtube_url_or_id> <slug> [title]

Examples:
  ingest_video_source.sh QWzLPn164w0 nate-offer-design "Nate Offer Design Video"
  ingest_video_source.sh https://youtu.be/QWzLPn164w0 nate-offer-design
USAGE
  exit 1
fi

WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}"
TOOLS_DIR="$WORKSPACE_DIR/tools"
SCRIPTS_DIR="$WORKSPACE_DIR/scripts"
SOURCES_DIR="$WORKSPACE_DIR/memory/sources"
TRANSCRIPTS_DIR="$WORKSPACE_DIR/memory/transcripts"
DATE_STR="$(date +%Y-%m-%d)"

mkdir -p "$SOURCES_DIR" "$TRANSCRIPTS_DIR"

if [[ "$SOURCE_INPUT" =~ ^[A-Za-z0-9_-]{11}$ ]]; then
  VIDEO_ID="$SOURCE_INPUT"
  SOURCE_URL="https://youtu.be/$VIDEO_ID"
else
  VIDEO_ID="$(printf '%s' "$SOURCE_INPUT" | sed -nE 's/.*(youtu\.be\/|v=|embed\/|v\/)([A-Za-z0-9_-]{11}).*/\2/p')"
  SOURCE_URL="$SOURCE_INPUT"
fi

if [[ -z "${VIDEO_ID:-}" || ${#VIDEO_ID} -ne 11 ]]; then
  echo "Error: invalid YouTube input '$SOURCE_INPUT'" >&2
  exit 1
fi

TRANSCRIPT_PATH="$TRANSCRIPTS_DIR/$DATE_STR-$SLUG-$VIDEO_ID.txt"

"$TOOLS_DIR/yt-transcribe" "$VIDEO_ID" text > "$TRANSCRIPT_PATH"

"$SCRIPTS_DIR/new_source_card.sh" "$SLUG" "$SOURCE_URL" "${TITLE:-YouTube Video $VIDEO_ID}" >/dev/null
CARD_PATH="$SOURCES_DIR/$DATE_STR-$SLUG.md"

cat >> "$CARD_PATH" <<EOF

## 8) Transcript
- Video ID: $VIDEO_ID
- Transcript file: $TRANSCRIPT_PATH

## 9) Analysis TODO
- Fill sections 1-7 from transcript evidence.
- Add at least one concrete action under section 7.
EOF

echo "Transcript: $TRANSCRIPT_PATH"
echo "Source card: $CARD_PATH"
