#!/usr/bin/env bash
# Monitor GitHub trending for TypeScript + AI/agentic repos
# Runs: Every 2 hours
# Output: JSON array of new repos with metadata

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RADAR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUEUE_DIR="$RADAR_DIR/queue"
LOG_DIR="$RADAR_DIR/logs"
CACHE_FILE="$QUEUE_DIR/github-seen.txt"
OUTPUT_FILE="$QUEUE_DIR/github-signals-$(date +%Y%m%d-%H%M).json"
mkdir -p "$QUEUE_DIR" "$LOG_DIR"

# Ensure cache exists
touch "$CACHE_FILE"

# Portable UTC date for "24 hours ago" (macOS + Linux).
CUTOFF_DATE="$(python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d"))
PY
)"

# Fetch trending TypeScript repos (last 24h)
# Using gh CLI if authenticated, otherwise curl
fetch_trending() {
    # Try gh CLI first
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        gh api search/repositories \
            --paginate \
            -f q="language:typescript created:>$CUTOFF_DATE" \
            -f sort="stars" \
            -f order="desc" \
            -f per_page="30" \
            --jq '.items[] | {name: .full_name, description: .description, stars: .stargazers_count, url: .html_url, topics: .topics, created_at: .created_at}' 2>/dev/null
    else
        # Fallback: just return empty, log warning
        echo "[]"
        echo "$(date): GitHub CLI not authenticated" >> "$LOG_DIR/monitor-errors.log"
    fi
}

# Filter for AI/agentic keywords
is_relevant() {
    local desc="$1"
    local topics="$2"
    local keywords="agent ai llm openai claude automation workflow bot assistant"
    
    for kw in $keywords; do
        if echo "$desc $topics" | grep -qi "$kw"; then
            return 0
        fi
    done
    return 1
}

# Main
signals="[]"

# For now, just create the structure - actual API call needs auth
# This is a scaffold that Cobi will configure
cat > "$OUTPUT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "source": "github-trending",
  "repos": [],
  "note": "Configure gh auth login to enable fetching"
}
EOF

echo "GitHub monitor ran: $OUTPUT_FILE"
