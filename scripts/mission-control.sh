#!/bin/bash
# Mission Control CLI Dashboard
# Terminal-based monitoring for OpenClaw automation

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

clear

echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║${NC}          🦞 ${CYAN}OpenClaw Mission Control${NC} - CLI Dashboard         ${BOLD}║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# === SYSTEM STATUS ===
echo -e "${BOLD}SYSTEM STATUS${NC}"
echo "─────────────────────────────────────────────────────────────"

# Check Gateway
if openclaw gateway status 2>/dev/null | grep -q "Runtime: running"; then
    echo -e "  ${GREEN}●${NC} Gateway          ${GREEN}RUNNING${NC}"
else
    echo -e "  ${RED}●${NC} Gateway          ${RED}STOPPED${NC}"
fi

# Check Cron
CRON_JOBS=$(crontab -l 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l | tr -d ' ')
if [ "$CRON_JOBS" -gt 0 ]; then
    echo -e "  ${GREEN}●${NC} Automation       ${GREEN}ACTIVE${NC} ($CRON_JOBS jobs)"
else
    echo -e "  ${RED}●${NC} Automation       ${RED}INACTIVE${NC}"
fi

# Check Vault
if [ -d "$VAULT_PATH" ]; then
    VAULT_FILES=$(find "$VAULT_PATH" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    echo -e "  ${GREEN}●${NC} Vault            ${GREEN}OK${NC} ($VAULT_FILES files)"
else
    echo -e "  ${RED}●${NC} Vault            ${RED}MISSING${NC}"
fi

echo ""

# === TODAY'S PROGRESS ===
echo -e "${BOLD}TODAY'S PROGRESS ($(date +%Y-%m-%d))${NC}"
echo "─────────────────────────────────────────────────────────────"

# Morning briefing
TODAY_BRIEF="$VAULT_PATH/01-daily/$(date +%Y-%m-%d)-morning-briefing.md"
if [ -f "$TODAY_BRIEF" ]; then
    BRIEF_TIME=$(stat -f "%Sm" -t "%H:%M" "$TODAY_BRIEF" 2>/dev/null || stat -c "%y" "$TODAY_BRIEF" 2>/dev/null | cut -d' ' -f2 | cut -d':' -f1,2)
    echo -e "  ${GREEN}✓${NC} Morning Brief    ${GREEN}GENERATED${NC} at $BRIEF_TIME"
else
    echo -e "  ${YELLOW}○${NC} Morning Brief    ${YELLOW}PENDING${NC}"
fi

# Patterns today
PATTERNS_TODAY=$(find "$VAULT_PATH/03-patterns" -name "*.md" -mtime -1 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${CYAN}●${NC} Patterns         ${CYAN}$PATTERNS_TODAY${NC} extracted today"

# Self-improvement task
TODAY_TASK="$VAULT_PATH/self-improvement/daily-tasks/$(date +%Y-%m-%d)-task.md"
if [ -f "$TODAY_TASK" ]; then
    echo -e "  ${GREEN}✓${NC} Self-Improvement ${GREEN}TASK READY${NC}"
else
    echo -e "  ${YELLOW}○${NC} Self-Improvement ${YELLOW}PENDING${NC}"
fi

echo ""

# === VAULT OVERVIEW ===
echo -e "${BOLD}VAULT OVERVIEW${NC}"
echo "─────────────────────────────────────────────────────────────"
printf "  %-20s %10s %10s\n" "Directory" "Today" "Total"
echo "  ─────────────────────────────────────────"

for dir in 01-daily 03-patterns 04-decisions/skill-proposals 05-sessions self-improvement/daily-tasks; do
    DIR_PATH="$VAULT_PATH/$dir"
    if [ -d "$DIR_PATH" ]; then
        TOTAL=$(find "$DIR_PATH" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        TODAY=$(find "$DIR_PATH" -name "*.md" -mtime -1 2>/dev/null | wc -l | tr -d ' ')
        DIR_NAME=$(basename "$dir")
        printf "  ${CYAN}%-20s${NC} %10s %10s\n" "$DIR_NAME" "$TODAY" "$TOTAL"
    fi
done

echo ""

# === PENDING PROPOSALS ===
echo -e "${BOLD}PENDING BUILD PROPOSALS${NC}"
echo "─────────────────────────────────────────────────────────────"

PROPOSALS_DIR="$VAULT_PATH/04-decisions/skill-proposals"
if [ -d "$PROPOSALS_DIR" ]; then
    PENDING=$(find "$PROPOSALS_DIR" -name "*.md" -exec grep -l "Status: Proposed\|Status: Queued" {} \; 2>/dev/null)
    if [ -n "$PENDING" ]; then
        echo "$PENDING" | while read -r file; do
            NAME=$(basename "$file" .md | cut -d'-' -f1-3)
            echo -e "  ${YELLOW}●${NC} $NAME"
        done
        echo ""
        echo -e "  ${CYAN}Tip:${NC} Reply 'build [name]' to approve"
    else
        echo -e "  ${GREEN}✓${NC} No pending proposals"
    fi
else
    echo -e "  ${YELLOW}○${NC} No proposals directory"
fi

echo ""

# === SCHEDULE ===
echo -e "${BOLD}AUTOMATION SCHEDULE${NC}"
echo "─────────────────────────────────────────────────────────────"

if [ "$CRON_JOBS" -gt 0 ]; then
    echo -e "  ${CYAN}06:00${NC}  Morning Briefing"
    echo -e "  ${CYAN}09:00${NC}  Self-Improvement Task"
    echo -e "  ${CYAN}05:00${NC}  Full Pipeline (AM)"
    echo -e "  ${CYAN}17:00${NC}  Full Pipeline (PM)"
    echo -e "  ${CYAN}*/6h${NC}  Pre-Compaction Save"
else
    echo -e "  ${RED}⚠${NC}  No automation scheduled"
    echo -e "     Run: ${CYAN}crontab ~/.openclaw/workspace/crontab.openclaw${NC}"
fi

echo ""

# === QUICK ACTIONS ===
echo -e "${BOLD}QUICK ACTIONS${NC}"
echo "─────────────────────────────────────────────────────────────"
echo -e "  ${CYAN}1)${NC} Run Pipeline Now"
echo -e "  ${CYAN}2)${NC} Generate Morning Brief"
echo -e "  ${CYAN}3)${NC} Create Self-Improvement Task"
echo -e "  ${CYAN}4)${NC} View Recent Logs"
echo -e "  ${CYAN}5)${NC} Refresh Dashboard"
echo -e "  ${CYAN}q)${NC} Quit"
echo ""

# Read choice
read -p "Select action: " choice

case "$choice" in
    1)
        echo -e "\n${CYAN}Starting pipeline...${NC}"
        bash "$WORKSPACE_PATH/scripts/full-pipeline.sh" &
        echo -e "${GREEN}✓ Pipeline started in background${NC}"
        ;;
    2)
        echo -e "\n${CYAN}Generating morning brief...${NC}"
        bash "$WORKSPACE_PATH/scripts/morning-briefing.sh"
        echo -e "${GREEN}✓ Briefing generated${NC}"
        ;;
    3)
        echo -e "\n${CYAN}Creating self-improvement task...${NC}"
        bash "$WORKSPACE_PATH/scripts/self-improvement-loop.sh" --daily-surprise
        echo -e "${GREEN}✓ Task created${NC}"
        ;;
    4)
        echo -e "\n${BOLD}Recent Logs:${NC}"
        if [ -d "$WORKSPACE_PATH/logs" ]; then
            ls -lt "$WORKSPACE_PATH/logs" | head -10
        else
            echo "No logs directory yet"
        fi
        ;;
    5)
        exec "$0"  # Restart
        ;;
    q|Q)
        echo -e "\n${CYAN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "\n${YELLOW}Invalid choice${NC}"
        ;;
esac
