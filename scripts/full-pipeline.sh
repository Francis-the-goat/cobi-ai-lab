#!/bin/bash
# Full Pipeline: Harvest → Analyze → Notify
# Runs sequentially with error handling

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
LOG_FILE="$VAULT_PATH/05-sessions/pipeline-$(date +%Y%m%d-%H%M%S).log"

mkdir -p "$VAULT_PATH/05-sessions"
mkdir -p ~/.openclaw/workspace/logs

exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "========================================="
echo "PIPELINE START: $(date)"
echo "========================================="

# Step 1: Harvest
echo ""
echo "[STEP 1/3] Running Harvester..."
if bash ~/.openclaw/workspace/scripts/orchestrate-agents.sh --harvester; then
    echo "✓ Harvester completed"
    
    # Step 2: Analyze
    echo ""
    echo "[STEP 2/3] Running Analyst..."
    sleep 30
    if bash ~/.openclaw/workspace/scripts/orchestrate-agents.sh --analyst; then
        echo "✓ Analyst completed"
        
        # Step 3: Opportunity detection
        echo ""
        echo "[STEP 3/3] Running Skill Opportunity Detector..."
        if bash ~/.openclaw/workspace/skills/skill-opportunity-detector/scripts/daily-scan.sh; then
            echo "✓ Opportunity detection completed"
            
            # Notification
            if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
                curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
                    -d "chat_id=$TELEGRAM_CHAT_ID" \
                    -d "text=✅ Pipeline Complete%0A%0AHarvest → Analyze → Detect%0A%0ALog: $LOG_FILE" \
                    > /dev/null 2>&1 || true
            fi
            
            echo ""
            echo "========================================="
            echo "PIPELINE SUCCESS: $(date)"
            echo "========================================="
            exit 0
        else
            echo "⚠ Opportunity detection failed"
            exit 3
        fi
    else
        echo "⚠ Analyst failed"
        exit 2
    fi
else
    echo "⚠ Harvester failed"
    exit 1
fi
