#!/usr/bin/env bash
# Quick status of radar system

set -euo pipefail

echo "=== Radar System Status ==="
echo "Time: $(date)"
echo ""

RADAR_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
QUEUE_DIR="$RADAR_DIR/queue"
mkdir -p "$QUEUE_DIR"

count_lines() {
  local file="$1"
  if [ -f "$file" ]; then
    wc -l < "$file" | tr -d ' '
  else
    echo 0
  fi
}

# Check queue sizes
echo "Queue Status:"
echo "  Urgent alerts:  $(count_lines "$QUEUE_DIR/urgent-alerts.jsonl")"
echo "  Asset packs:    $(ls -1 "$QUEUE_DIR"/asset-*.json 2>/dev/null | wc -l)"
echo "  Content ideas:  $(count_lines "$QUEUE_DIR/content-ideas.jsonl")"
echo "  Research queue: $(count_lines "$QUEUE_DIR/research-queue.jsonl")"
echo ""

# Check recent signals
echo "Recent Signals:"
ls -1t "$QUEUE_DIR"/*-signals-* 2>/dev/null | head -5 | while read f; do
    echo "  $(basename $f)"
done
echo ""

# Check dependencies
echo "Dependencies:"
command -v jq &> /dev/null && echo "  jq: ✅" || echo "  jq: ❌ (install: brew install jq)"
command -v yt-dlp &> /dev/null && echo "  yt-dlp: ✅" || echo "  yt-dlp: ❌ (install: brew install yt-dlp)"
command -v gh &> /dev/null && echo "  gh: ✅" || echo "  gh: ❌ (install: brew install gh)"
if command -v scrapling >/dev/null 2>&1 || [ -x "${OPENCLAW_SCRAPLING_VENV:-$HOME/.openclaw/scrapling-venv}/bin/scrapling" ]; then
  echo "  scrapling: ✅"
else
  echo "  scrapling: ❌ (install: bash ~/.openclaw/workspace/scripts/install_scrapling_runtime.sh)"
fi
echo ""

echo "Next: Run ./run-radar.sh to check for signals"
