#!/bin/bash
# Full Pipeline: Harvest → Analyze → Detect
# Production-ready version with proper error handling

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$VAULT_PATH/05-sessions"
mkdir -p "$WORKSPACE_PATH/logs"

LOG_FILE="$WORKSPACE_PATH/logs/pipeline-${TIMESTAMP}.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              OPENCLAW PIPELINE - ${TIMESTAMP}                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Track results
HARVESTER_STATUS="SKIPPED"
ANALYST_STATUS="SKIPPED"
DETECTOR_STATUS="SKIPPED"
HARVESTER_SOURCES=0
HARVESTER_TRANSCRIPTS=0
ANALYST_TRANSCRIPTS=0
ANALYST_PATTERNS=0

# Step 1: Harvest
echo "[STEP 1/3] Running Harvester..."
echo "─────────────────────────────────────────────────────────────"

if [ -x "$WORKSPACE_PATH/scripts/harvester-agent.sh" ]; then
    if bash "$WORKSPACE_PATH/scripts/harvester-agent.sh" 2>&1; then
        HARVESTER_STATUS="SUCCESS"
        # Parse results from output
        HARVESTER_OUTPUT=$(grep "HARVESTER_RESULT:" "$LOG_FILE" | tail -1 || echo "")
        if [ -n "$HARVESTER_OUTPUT" ]; then
            HARVESTER_SOURCES=$(echo "$HARVESTER_OUTPUT" | grep -o "sources=[0-9]*" | cut -d= -f2 || echo "0")
            HARVESTER_TRANSCRIPTS=$(echo "$HARVESTER_OUTPUT" | grep -o "transcripts=[0-9]*" | cut -d= -f2 || echo "0")
        fi
        echo ""
        echo "✓ Harvester completed"
        echo "  Sources: $HARVESTER_SOURCES"
        echo "  Transcripts: $HARVESTER_TRANSCRIPTS"
    else
        HARVESTER_STATUS="FAILED"
        echo "⚠ Harvester failed (exit code: $?)"
    fi
else
    echo "⚠ Harvester script not found or not executable"
    echo "  Expected: $WORKSPACE_PATH/scripts/harvester-agent.sh"
fi

echo ""

# Step 2: Analyze (only if harvester succeeded or we're forcing)
echo "[STEP 2/3] Running Analyst..."
echo "─────────────────────────────────────────────────────────────"

if [ "$HARVESTER_STATUS" = "SUCCESS" ] || [ "${FORCE_ANALYZE:-false}" = "true" ]; then
    if [ -x "$WORKSPACE_PATH/scripts/analyst-agent.sh" ]; then
        if bash "$WORKSPACE_PATH/scripts/analyst-agent.sh" 2>&1; then
            ANALYST_STATUS="SUCCESS"
            # Parse results
            ANALYST_OUTPUT=$(grep "ANALYST_RESULT:" "$LOG_FILE" | tail -1 || echo "")
            if [ -n "$ANALYST_OUTPUT" ]; then
                ANALYST_TRANSCRIPTS=$(echo "$ANALYST_OUTPUT" | grep -o "transcripts=[0-9]*" | cut -d= -f2 || echo "0")
                ANALYST_PATTERNS=$(echo "$ANALYST_OUTPUT" | grep -o "patterns=[0-9]*" | cut -d= -f2 || echo "0")
            fi
            echo ""
            echo "✓ Analyst completed"
            echo "  Transcripts analyzed: $ANALYST_TRANSCRIPTS"
            echo "  Patterns extracted: $ANALYST_PATTERNS"
        else
            ANALYST_STATUS="FAILED"
            echo "⚠ Analyst failed (exit code: $?)"
        fi
    else
        echo "⚠ Analyst script not found or not executable"
        echo "  Expected: $WORKSPACE_PATH/scripts/analyst-agent.sh"
    fi
else
    echo "⊘ Skipped (harvester failed and FORCE_ANALYZE not set)"
fi

echo ""

# Step 3: Opportunity Detection
echo "[STEP 3/3] Running Skill Opportunity Detector..."
echo "─────────────────────────────────────────────────────────────"

if [ "$ANALYST_STATUS" = "SUCCESS" ]; then
    DETECTOR_SCRIPT="$WORKSPACE_PATH/skills/skill-opportunity-detector/scripts/daily-scan.sh"
    if [ -x "$DETECTOR_SCRIPT" ]; then
        if bash "$DETECTOR_SCRIPT" 2>&1; then
            DETECTOR_STATUS="SUCCESS"
            echo ""
            echo "✓ Opportunity detection completed"
        else
            DETECTOR_STATUS="FAILED"
            echo "⚠ Opportunity detector failed"
        fi
    else
        DETECTOR_STATUS="NOT_FOUND"
        echo "⊘ Detector not available (create at $DETECTOR_SCRIPT)"
    fi
else
    echo "⊘ Skipped (analyst not successful)"
fi

echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                      PIPELINE SUMMARY                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Step          Status      Details"
echo "─────────────────────────────────────────────────────────────"
printf "%-15s %-10s  %s\n" "Harvester" "$HARVESTER_STATUS" "Sources: $HARVESTER_SOURCES, Transcripts: $HARVESTER_TRANSCRIPTS"
printf "%-15s %-10s  %s\n" "Analyst" "$ANALYST_STATUS" "Transcripts: $ANALYST_TRANSCRIPTS, Patterns: $ANALYST_PATTERNS"
printf "%-15s %-10s  %s\n" "Detector" "$DETECTOR_STATUS" "-"
echo ""
echo "Log: $LOG_FILE"
echo "Session: $VAULT_PATH/05-sessions/"
echo ""

# Notification (if configured)
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
    MESSAGE="✅ Pipeline Complete%0A%0A"
    MESSAGE+="Harvester: $HARVESTER_STATUS ($HARVESTER_SOURCES sources, $HARVESTER_TRANSCRIPTS transcripts)%0A"
    MESSAGE+="Analyst: $ANALYST_STATUS ($ANALYST_PATTERNS patterns)%0A"
    MESSAGE+="Detector: $DETECTOR_STATUS%0A%0A"
    MESSAGE+="Log: $LOG_FILE"
    
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID" \
        -d "text=$MESSAGE" \
        > /dev/null 2>&1 || true
fi

# Update dashboard status
if [ -d "$WORKSPACE_PATH/logs" ]; then
    cat > "$WORKSPACE_PATH/logs/last-pipeline-status.json" << EOF
{
  "timestamp": "$TIMESTAMP",
  "harvester": {
    "status": "$HARVESTER_STATUS",
    "sources": $HARVESTER_SOURCES,
    "transcripts": $HARVESTER_TRANSCRIPTS
  },
  "analyst": {
    "status": "$ANALYST_STATUS",
    "transcripts": $ANALYST_TRANSCRIPTS,
    "patterns": $ANALYST_PATTERNS
  },
  "detector": {
    "status": "$DETECTOR_STATUS"
  },
  "log_file": "$LOG_FILE"
}
EOF
fi

echo "Pipeline finished: $(date)"
echo ""

# Exit with appropriate code
if [ "$HARVESTER_STATUS" = "SUCCESS" ] && [ "$ANALYST_STATUS" = "SUCCESS" ]; then
    echo "✅ ALL STEPS SUCCESSFUL"
    exit 0
elif [ "$HARVESTER_STATUS" = "SUCCESS" ]; then
    echo "⚠️  PARTIAL SUCCESS (harvester only)"
    exit 1
else
    echo "❌ PIPELINE FAILED"
    exit 2
fi
