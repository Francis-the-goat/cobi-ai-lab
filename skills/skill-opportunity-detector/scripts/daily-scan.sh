#!/bin/bash
# Daily Scan — Autonomous skill opportunity detection
# Runs daily via cron to analyze new patterns

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load config
VAULT_PATH="${SKILL_VAULT_PATH:-$HOME/obsidian/openclaw}"
CONFIG_FILE="$SKILL_DIR/config.yaml"

echo "=== Skill Opportunity Detector — Daily Scan ==="
echo "Vault: $VAULT_PATH"
echo "Date: $(date)"
echo ""

# Ensure directories exist
mkdir -p "$VAULT_PATH/04-decisions/skill-proposals"
mkdir -p "$VAULT_PATH/04-decisions/rejected-patterns"
mkdir -p "$VAULT_PATH/05-sessions"

# Find unanalyzed patterns
echo "Scanning for unanalyzed patterns..."

# Get list of pattern files without corresponding proposals
PATTERN_COUNT=0
PROPOSAL_COUNT=0
REJECT_COUNT=0

for pattern_file in "$VAULT_PATH/03-patterns"/*.md; do
    if [ ! -f "$pattern_file" ]; then
        continue
    fi
    
    basename=$(basename "$pattern_file" .md)
    
    # Skip if already analyzed
    if [ -f "$VAULT_PATH/04-decisions/skill-proposals/${basename}-proposal.md" ] || \
       [ -f "$VAULT_PATH/04-decisions/rejected-patterns/${basename}-rejected.md" ]; then
        continue
    fi
    
    ((PATTERN_COUNT++))
    
    echo ""
    echo "Analyzing: $basename"
    
    # Run analysis
    if python3 "$SKILL_DIR/scripts/evaluate-buildability.py" \
        --pattern "$pattern_file" \
        --vault "$VAULT_PATH" \
        --config "$CONFIG_FILE"; then
        
        result=$?
        if [ $result -eq 0 ]; then
            ((PROPOSAL_COUNT++))
            echo "  → Proposal generated"
        elif [ $result -eq 1 ]; then
            ((REJECT_COUNT++))
            echo "  → Rejected and logged"
        fi
    fi
done

# Generate session log
SESSION_FILE="$VAULT_PATH/05-sessions/skill-detector-$(date +%Y%m%d-%H%M).md"

cat > "$SESSION_FILE" << EOF
# Skill Opportunity Detector Session
Date: $(date)
Patterns Analyzed: $PATTERN_COUNT
Proposals Generated: $PROPOSAL_COUNT
Rejected Patterns: $REJECT_COUNT

## Files Created
EOF

# List new proposals
if [ $PROPOSAL_COUNT -gt 0 ]; then
    echo "" >> "$SESSION_FILE"
    echo "### Proposals" >> "$SESSION_FILE"
    ls -1 "$VAULT_PATH/04-decisions/skill-proposals"/*-proposal.md 2>/dev/null | while read f; do
        if [ "$(stat -f%m "$f")" -gt "$(date -v-1d +%s)" ]; then
            echo "- $(basename "$f")" >> "$SESSION_FILE"
        fi
    done
fi

echo "" >> "$SESSION_FILE"
echo "---" >> "$SESSION_FILE"
echo "Next: Review proposals in 04-decisions/skill-proposals/" >> "$SESSION_FILE"

echo ""
echo "=== Scan Complete ==="
echo "Patterns analyzed: $PATTERN_COUNT"
echo "Proposals generated: $PROPOSAL_COUNT"
echo "Rejected patterns: $REJECT_COUNT"
echo "Session log: $SESSION_FILE"

# Telegram notification
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=🔍 Skill Detector — $(date +%Y-%m-%d)%0A%0AAnalyzed: $PATTERN_COUNT patterns%0AProposals: $PROPOSAL_COUNT%0ARejected: $REJECT_COUNT%0A%0AReview: 04-decisions/skill-proposals/" \
        > /dev/null 2>&1 || true
fi
