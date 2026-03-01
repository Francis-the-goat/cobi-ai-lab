#!/usr/bin/env bash
# Monitor specific YouTube channels for new uploads
# Channels: Nate B Jones, Kyle Pathy, + others
# Runs: Every hour

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RADAR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$RADAR_DIR/config"
QUEUE_DIR="$RADAR_DIR/queue"
CHANNELS_FILE="$CONFIG_DIR/youtube-channels.txt"
CACHE_FILE="$QUEUE_DIR/youtube-seen.txt"
OUTPUT_FILE="$QUEUE_DIR/youtube-signals-$(date +%Y%m%d-%H%M).json"
mkdir -p "$CONFIG_DIR" "$QUEUE_DIR"

# Default channels if config doesn't exist
touch "$CACHE_FILE"

MIN_UPLOAD_DATE="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y%m%d"))
PY
)"

if [ ! -f "$CHANNELS_FILE" ]; then
cat > "$CHANNELS_FILE" << EOF
# Format: channel_id|channel_name
UCt8xK0wfUCn5YTCYEmIDa1g|Nate B Jones
UCR2btWn3i6e1S8iOQpR4V1A|Kyle Pathy
EOF
fi

# Check each channel (using yt-dlp --flat-playlist)
check_channel() {
    local channel_id="$1"
    local name="$2"
    
    # Get latest video (last 24h)
    yt-dlp --flat-playlist --playlist-end 3 \
        --print "%(id)s|%(title)s|%(upload_date)s|%(webpage_url)s" \
        "https://www.youtube.com/channel/$channel_id/videos" 2>/dev/null | \
        while IFS='|' read -r vid_id title upload_date url; do
            # Check if from last 24h
            if [ "${upload_date:-19700101}" -ge "$MIN_UPLOAD_DATE" ]; then
                if ! grep -q "^$vid_id" "$CACHE_FILE"; then
                    echo "$vid_id" >> "$CACHE_FILE"
                    echo "{\"channel\": \"$name\", \"id\": \"$vid_id\", \"title\": \"$title\", \"url\": \"$url\", \"date\": \"$upload_date\"}"
                fi
            fi
        done
}

# Build output
signals="[]"
while IFS='|' read -r channel_id name; do
    [ -z "$channel_id" ] && continue
    [[ "$channel_id" =~ ^# ]] && continue
    
    new_vids=$(check_channel "$channel_id" "$name")
    if [ -n "$new_vids" ]; then
        signals=$(echo "$signals" | jq --argjson vids "[$new_vids]" '. + $vids')
    fi
done < "$CHANNELS_FILE"

# Write output
cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "source": "youtube",
  "new_videos": $signals
}
EOF

echo "YouTube monitor ran: $(echo "$signals" | jq 'length') new videos"
