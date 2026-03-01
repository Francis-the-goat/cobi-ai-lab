#!/usr/bin/env bash
# Check Nate B Jones channel for new videos

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "Checking $NATE_CHANNEL_NAME for new videos..."

# Get latest 5 videos using yt-dlp (if available)
# Format: video_id|title|upload_date|url|duration
if command -v yt-dlp &> /dev/null; then
    yt-dlp --flat-playlist --playlist-end 5 \
        --print "%(id)s|%(title)s|%(upload_date)s|%(webpage_url)s|%(duration_string)s" \
        "https://www.youtube.com/channel/$NATE_CHANNEL_ID/videos" 2>/dev/null | while IFS='|' read -r vid_id title upload_date url duration; do
        
        # Check if already processed
        if ! grep -q "^$vid_id" "$SEEN_FILE"; then
            echo "NEW: $title"
            echo "$vid_id|$title|$upload_date|$url|$duration" >> "$INBOX_DIR/pending.txt"
            echo "$vid_id" >> "$SEEN_FILE"
        fi
    done || true
else
    echo "yt-dlp not installed. Install with: brew install yt-dlp"
fi

echo "Done. Pending videos: $(wc -l < "$INBOX_DIR/pending.txt" | tr -d ' ')"
