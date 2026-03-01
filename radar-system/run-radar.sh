#!/usr/bin/env bash
# Master Radar Script - Run all monitors and process signals
# Usage: ./run-radar.sh [--continuous]

set -euo pipefail

RADAR_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
QUEUE_DIR="$RADAR_DIR/queue"
LOG_DIR="$RADAR_DIR/logs"

mkdir -p "$QUEUE_DIR" "$LOG_DIR"

LOG_FILE="$LOG_DIR/radar-$(date +%Y%m%d).log"

count_lines() {
  local file="$1"
  if [ -f "$file" ]; then
    wc -l < "$file" | tr -d ' '
  else
    echo 0
  fi
}

echo "=== Radar Run: $(date) ===" | tee -a "$LOG_FILE"

# Run monitors
echo "Running monitors..." | tee -a "$LOG_FILE"

# GitHub (if authenticated)
if [ -f "$RADAR_DIR/monitors/github-trending.sh" ]; then
    echo "[GitHub]" | tee -a "$LOG_FILE"
    bash "$RADAR_DIR/monitors/github-trending.sh" 2>&1 | tee -a "$LOG_FILE" || true
fi

# Hacker News
echo "[HackerNews]" | tee -a "$LOG_FILE"
bash "$RADAR_DIR/monitors/hackernews.sh" 2>&1 | tee -a "$LOG_FILE" || true

# YouTube (if yt-dlp available)
if command -v yt-dlp &> /dev/null; then
    echo "[YouTube]" | tee -a "$LOG_FILE"
    bash "$RADAR_DIR/monitors/youtube.sh" 2>&1 | tee -a "$LOG_FILE" || true
fi

# Web source pages (Scrapling)
if [ -f "$RADAR_DIR/monitors/web-scrapling.sh" ]; then
    echo "[Web Signals]" | tee -a "$LOG_FILE"
    bash "$RADAR_DIR/monitors/web-scrapling.sh" 2>&1 | tee -a "$LOG_FILE" || true
fi

# Process signals through scorer and router
echo "Processing signals..." | tee -a "$LOG_FILE"

for signal_file in "$QUEUE_DIR"/*-signals-*.json; do
    [ -f "$signal_file" ] || continue
    
    echo "Processing: $(basename $signal_file)" | tee -a "$LOG_FILE"
    
    # Extract individual signals and score/route each
    # This is a simplified version - would need jq logic per source format
    
done

# Generate summary report
echo "" | tee -a "$LOG_FILE"
echo "=== Summary ===" | tee -a "$LOG_FILE"
echo "Urgent alerts: $(count_lines "$QUEUE_DIR/urgent-alerts.jsonl")"
echo "Asset queue: $(ls -1 "$QUEUE_DIR"/asset-*.json 2>/dev/null | wc -l)"
echo "Content ideas: $(count_lines "$QUEUE_DIR/content-ideas.jsonl")"
echo "Research queue: $(count_lines "$QUEUE_DIR/research-queue.jsonl")"

echo "" | tee -a "$LOG_FILE"
echo "Radar run complete: $(date)" | tee -a "$LOG_FILE"
