#!/usr/bin/env bash
# Simple HN monitor - outputs text format (no jq required)

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RADAR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUEUE_DIR="$RADAR_DIR/queue"
OUTPUT_FILE="$QUEUE_DIR/hn-$(date +%Y%m%d-%H%M).txt"
CACHE_FILE="$QUEUE_DIR/hn-seen.txt"
mkdir -p "$QUEUE_DIR"
touch "$CACHE_FILE"

ONE_DAY_AGO=$(($(date +%s) - 86400))

# Fetch and parse (crude but works)
fetch_hn() {
    local url="https://hn.algolia.com/api/v1/search?tags=show_hn&numericFilters=created_at_i>$ONE_DAY_AGO"
    curl -s "$url" 2>/dev/null
}

# Extract signals (very basic parsing)
parse_signals() {
    local data="$1"
    # Look for objectID patterns and extract info
    echo "$data" | grep -o '"objectID":"[^"]*"' | sed 's/"objectID":"//;s/"$//' | while read id; do
        if ! grep -q "^$id" "$CACHE_FILE"; then
            echo "$id" >> "$CACHE_FILE"
            echo "SIGNAL|$id|hackernews|$(date -Iseconds)"
        fi
    done
}

echo "=== HN Monitor: $(date) ===" > "$OUTPUT_FILE"
DATA=$(fetch_hn)
parse_signals "$DATA" >> "$OUTPUT_FILE"
echo "Signals found: $(grep -c "^SIGNAL" "$OUTPUT_FILE" 2>/dev/null || echo 0)"
