#!/usr/bin/env bash
# Route scored signals to appropriate action
# Usage: cat scored-signal.json | ./route-action.sh

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RADAR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUEUE_DIR="$RADAR_DIR/queue"
mkdir -p "$QUEUE_DIR"

SIGNAL=$(cat)
SCORE=$(echo "$SIGNAL" | jq -r '.total_score // 0')
ACTION=$(echo "$SIGNAL" | jq -r '.action // "LOG"')
SOURCE=$(echo "$SIGNAL" | jq -r '.source // "unknown"')

echo "Routing: $ACTION (score: $SCORE) from $SOURCE"

case "$ACTION" in
  "ALERT+BUILD")
    echo "$SIGNAL" >> "$QUEUE_DIR/urgent-alerts.jsonl"
    echo "🚨 URGENT: High-signal opportunity detected"
    ;;
  "CREATE_ASSET")
    SLUG=$(date +%Y%m%d)-$(echo "$SIGNAL" | jq -r '.title//.repo?.name//"signal"' | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | cut -c1-30)
    echo "$SIGNAL" > "$QUEUE_DIR/asset-${SLUG}.json"
    echo "📦 ASSET QUEUED: $SLUG"
    ;;
  "CONTENT")
    echo "$SIGNAL" >> "$QUEUE_DIR/content-ideas.jsonl"
    echo "✍️  CONTENT: Added to backlog"
    ;;
  "RESEARCH")
    echo "$SIGNAL" >> "$QUEUE_DIR/research-queue.jsonl"
    echo "🔍 RESEARCH: Queued"
    ;;
  *)
    echo "$SIGNAL" >> "$QUEUE_DIR/all-signals.jsonl"
    ;;
esac
