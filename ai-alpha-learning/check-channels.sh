#!/usr/bin/env bash
# Check all learning channels for new content

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "=== AI Alpha Learning System ==="
echo "Checking Tier 1 channels..."
echo ""

TOTAL_NEW=0

# Check YouTube channels
for channel_spec in "${TIER1_CHANNELS[@]}"; do
    IFS='|' read -r name channel_id channel_type <<< "$channel_spec"

    if [ "${channel_type:-}" != "youtube" ]; then
        continue
    fi
    
    echo "[$name]"
    
    if command -v yt-dlp &> /dev/null; then
        yt-dlp --flat-playlist --playlist-end 3 \
            --print "%(id)s|%(title)s|%(upload_date)s|%(webpage_url)s|%(duration_string)s" \
            "https://www.youtube.com/channel/$channel_id/videos" 2>/dev/null | while IFS='|' read -r vid_id title upload_date url duration; do
            
            # Check if already seen
            if ! grep -q "^youtube:$vid_id" "$SEEN_FILE" 2>/dev/null; then
                echo "  NEW: $title"
                echo "youtube:$vid_id|$name|$title|$upload_date|$url|$duration" >> "$INBOX_DIR/tier1-youtube.txt"
                echo "youtube:$vid_id" >> "$SEEN_FILE"
            fi
        done || true
    else
        echo "  yt-dlp not installed"
    fi
    echo ""
done

# Count new content
NEW_COUNT=$(wc -l < "$INBOX_DIR/tier1-youtube.txt" | tr -d ' ')
echo "Found $NEW_COUNT new Tier 1 videos"
echo ""

# Show priority
if [ "$NEW_COUNT" -gt 0 ]; then
    echo "=== Priority Queue ==="
    echo "Process these in order:"
    nl "$INBOX_DIR/tier1-youtube.txt" 2>/dev/null | head -5
fi
