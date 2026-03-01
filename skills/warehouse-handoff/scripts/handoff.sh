#!/bin/bash
# Warehouse Shift Handoff — Runs during Cobi's shifts
# Processes backlog, surfaces priorities, writes to vault

set -euo pipefail

VAULT_DIR="$HOME/obsidian/openclaw"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
LOG_FILE="$HOME/.openclaw/workspace/logs/handoff-$DATE.log"

mkdir -p "$VAULT_DIR/01-daily" "$(dirname "$LOG_FILE")"

echo "[$TIME] Starting warehouse handoff..." >> "$LOG_FILE"

# 1. Process transcription queue
TRANSCRIPTION_COUNT=0
if [ -f "$HOME/.openclaw/workspace/scripts/transcription_queue.sh" ]; then
    OUTPUT=$("$HOME/.openclaw/workspace/scripts/transcription_queue.sh" process 2>&1) || true
    TRANSCRIPTION_COUNT=$(echo "$OUTPUT" | grep -c "Processing" || echo "0")
    echo "[$TIME] Transcription: $TRANSCRIPTION_COUNT files" >> "$LOG_FILE"
fi

# 2. Check value resource harvest
HARVEST_COUNT=0
if [ -f "$HOME/.openclaw/workspace/scripts/value_resource_harvest.sh" ]; then
    OUTPUT=$("$HOME/.openclaw/workspace/scripts/value_resource_harvest.sh" 2 2>&1) || true
    HARVEST_COUNT=$(echo "$OUTPUT" | grep -c "Harvested" || echo "0")
    echo "[$TIME] Harvest: $HARVEST_COUNT sources" >> "$LOG_FILE"
fi

# 3. Write handoff note to vault
HANDOFF_FILE="$VAULT_DIR/01-daily/$DATE-handoff.md"

cat > "$HANDOFF_FILE" << EOF
# Shift Handoff — $TIME

## Processed
- [$([ "$TRANSCRIPTION_COUNT" -gt 0 ] && echo "X" || echo " ")] Transcription queue ($TRANSCRIPTION_COUNT files)
- [$([ "$HARVEST_COUNT" -gt 0 ] && echo "X" || echo " ")] Value harvest ($HARVEST_COUNT sources)

## Priorities
1. Review processed content for patterns
2. Check [[00-README]] for active project alignment
3. Surface any urgent decisions

## Next Actions
- [ ] Review today's notes
- [ ] Update project files if insights emerged
- [ ] Clear transcription queue if pending

---
*Auto-generated during warehouse shift*
EOF

echo "[$TIME] Handoff written to $HANDOFF_FILE" >> "$LOG_FILE"
echo "✓ Warehouse handoff complete: $TRANSCRIPTION_COUNT transcriptions, $HARVEST_COUNT harvests"
