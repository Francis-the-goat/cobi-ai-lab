#!/usr/bin/env bash
# Monitor Hacker News for AI-related posts and Show HN
# Runs: Every 30 min
# Sources: /show, AI-tagged posts

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RADAR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUEUE_DIR="$RADAR_DIR/queue"
OUTPUT_FILE="$QUEUE_DIR/hn-signals-$(date +%Y%m%d-%H%M).json"
CACHE_FILE="$QUEUE_DIR/hn-seen.txt"
mkdir -p "$QUEUE_DIR"

touch "$CACHE_FILE"

# Fetch Show HN posts
fetch_show() {
    curl -s "https://hn.algolia.com/api/v1/search?tags=show_hn&numericFilters=created_at_i>$(($(date +%s) - 86400))" | \
        jq -r '.hits[] | select(.points > 10) | {id: .objectID, title: .title, url: .url, points: .points, comments: .num_comments, created: .created_at}'
}

# Fetch AI-tagged posts
fetch_ai() {
    curl -s "https://hn.algolia.com/api/v1/search?query=AI&tags=story&numericFilters=created_at_i>$(($(date +%s) - 86400))" | \
        jq -r '.hits[] | select(.points > 20) | {id: .objectID, title: .title, url: .url, points: .points, comments: .num_comments, created: .created_at}'
}

# Create output
cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "source": "hackernews",
  "show_hn": $(fetch_show 2>/dev/null | jq -s '.' || echo '[]'),
  "ai_posts": $(fetch_ai 2>/dev/null | jq -s '.' || echo '[]')
}
EOF

echo "HN monitor ran: $OUTPUT_FILE"
