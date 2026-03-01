#!/bin/bash
# Pre-Compaction Memory Hook
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"# Ensure PATH for cron compatibility
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
# Saves critical context before OpenClaw compacts conversation

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
COMPACTION_DIR="$VAULT_PATH/00-compaction-saves"

echo "=== Pre-Compaction Memory Save ==="
echo "Time: $(date)"

mkdir -p "$COMPACTION_DIR"

# Generate save file with timestamp
SAVE_FILE="$COMPACTION_DIR/compaction-$(date +%Y%m%d-%H%M%S).md"

cat > "$SAVE_FILE" << 'EOF'
# Pre-Compaction Save
Time: $(date)
Session: $OPENCLAW_SESSION_ID

## Critical Context
EOF

# Extract key information from current session
# This runs BEFORE compaction happens

# 1. Active decisions not yet implemented
if [ -d "$VAULT_PATH/04-decisions" ]; then
    echo "" >> "$SAVE_FILE"
    echo "## Pending Decisions" >> "$SAVE_FILE"
    grep -l "Status: Proposed\|Status: Queued" "$VAULT_PATH/04-decisions"/*.md 2>/dev/null | head -5 | while read f; do
        echo "- $(basename "$f")" >> "$SAVE_FILE"
    done
fi

# 2. Recent patterns (last 24h)
if [ -d "$VAULT_PATH/03-patterns" ]; then
    echo "" >> "$SAVE_FILE"
    echo "## Recent Patterns (Last 24h)" >> "$SAVE_FILE"
    find "$VAULT_PATH/03-patterns" -name "*.md" -mtime -1 -exec basename {} \; 2>/dev/null | head -5 >> "$SAVE_FILE"
fi

# 3. Active builds
if [ -f "$VAULT_PATH/04-decisions/build-queue.md" ]; then
    echo "" >> "$SAVE_FILE"
    echo "## Active Build Queue" >> "$SAVE_FILE"
    grep "^\-" "$VAULT_PATH/04-decisions/build-queue.md" 2>/dev/null | head -5 >> "$SAVE_FILE"
fi

# 4. User corrections (if any logged)
if [ -f "$VAULT_PATH/correction-log.md" ]; then
    echo "" >> "$SAVE_FILE"
    echo "## Recent Corrections" >> "$SAVE_FILE"
    tail -10 "$VAULT_PATH/correction-log.md" >> "$SAVE_FILE"
fi

# Update hot memory index
cat > "$VAULT_PATH/00-hot-memory.md" << EOF
# Hot Memory — Last Updated $(date)

This file contains the most critical context that must survive compaction.

## Current Focus
$(grep "^#" "$VAULT_PATH/PROJECTS.md" 2>/dev/null | head -3 || echo "See PROJECTS.md")

## Active Work
$(ls -1t "$VAULT_PATH/03-patterns"/*.md 2>/dev/null | head -3 | xargs -I {} basename {} || echo "No recent patterns")

## Pending Actions
$(grep "Status: Proposed" "$VAULT_PATH/03-patterns"/*.md 2>/dev/null | wc -l) build proposals awaiting approval

## Links
- Compaction saves: [[00-compaction-saves/]]
- Full memory: [[MEMORY.md]]
- Active context: [[ACTIVE_CONTEXT.md]]
EOF

echo "✓ Saved to: $SAVE_FILE"
echo "✓ Hot memory updated: $VAULT_PATH/00-hot-memory.md"

# Optional: Telegram notification
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=💾 Memory saved before compaction ($(date +%H:%M))" \
        > /dev/null 2>&1 || true
fi
