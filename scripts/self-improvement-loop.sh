#!/bin/bash
# Self-Improvement Loop
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"# Ensure PATH for cron compatibility
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
# Creates and maintains the self-improving agent system

set -euo pipefail

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
IMPROVEMENT_DIR="$VAULT_PATH/self-improvement"

echo "=== Self-Improvement System ==="

# Create directory structure
mkdir -p "$IMPROVEMENT_DIR"/{corrections,patterns,learnings,metrics}

# Initialize files if they don't exist
[ -f "$IMPROVEMENT_DIR/corrections/log.md" ] || cat > "$IMPROVEMENT_DIR/corrections/log.md" << 'EOF'
# Correction Log

Format:
- **Date**: When correction occurred
- **Context**: What was being discussed
- **What I Did**: My incorrect action/response
- **What You Wanted**: Correct intent/behavior
- **Root Cause**: Why I misunderstood
- **Pattern**: Generalizable rule

## Corrections

EOF

[ -f "$IMPROVEMENT_DIR/patterns/context-specific.md" ] || cat > "$IMPROVEMENT_DIR/patterns/context-specific.md" << 'EOF'
# Context-Specific Patterns

## Your Communication Patterns

### Intent Refinement
- When you say "X", you often mean "Y" (deeper capability)
- Pattern: Surface request → Constraint-aware implementation

### Frustration Signals
- "I don't want you to..." → Previous output missed intent
- "Obviously..." → I was being too literal
- Short/cold responses → Validation was skipped

## Your Constraint Profile
- Split attention: Warehouse + building
- Budget: $200/month hard ceiling
- Timeline: 90-day sprints
- Goal: 10K MRR

## Decision Preferences
- Prefer execution over theory
- Want leverage, not features
- Value reusable skills over one-offs

EOF

[ -f "$IMPROVEMENT_DIR/learnings/weekly.md" ] || cat > "$IMPROVEMENT_DIR/learnings/weekly.md" << 'EOF'
# Weekly Learnings

## Week of YYYY-MM-DD

### What Worked
- 

### What Didn't
- 

### Corrections Received
- 

### Patterns Emerging
- 

### Capability Upgrades
- 

EOF

[ -f "$IMPROVEMENT_DIR/metrics/accuracy.md" ] || cat > "$IMPROVEMENT_DIR/metrics/accuracy.md" << 'EOF'
# Accuracy Metrics

## Intent Detection
- Total interactions: 0
- Correct interpretations: 0
- Corrections needed: 0
- Accuracy rate: 0%

## By Category
| Category | Total | Correct | Accuracy |
|----------|-------|---------|----------|
| Build requests | 0 | 0 | 0% |
| Analysis requests | 0 | 0 | 0% |
| Clarification | 0 | 0 | 0% |

## Trend
- Week 1: 0%
- Week 2: 0%
- Week 3: 0%

EOF

echo "✓ Self-improvement structure initialized"
echo "  → $IMPROVEMENT_DIR/corrections/log.md"
echo "  → $IMPROVEMENT_DIR/patterns/context-specific.md"
echo "  → $IMPROVEMENT_DIR/learnings/weekly.md"
echo "  → $IMPROVEMENT_DIR/metrics/accuracy.md"

# Function: Log correction
if [ "${1:-}" = "--log-correction" ]; then
    shift
    CORRECTION="$*"
    
    cat >> "$IMPROVEMENT_DIR/corrections/log.md" << EOF

### $(date +%Y-%m-%d)
- **What I Did**: [Previous incorrect action]
- **What You Wanted**: $CORRECTION
- **Root Cause**: [To be analyzed]
- **Pattern**: [Generalizable insight]

EOF
    
    echo "✓ Correction logged"
fi

# Function: Daily surprise task (self-improvement)
if [ "${1:-}" = "--daily-surprise" ]; then
    echo "Generating daily improvement task..."
    
    # Pick random area to improve
    AREAS=("pattern-recognition" "constraint-handling" "intent-detection" "cost-optimization")
    AREA=${AREAS[$RANDOM % ${#AREAS[@]}]}
    
    # Create task
    TASK_FILE="$IMPROVEMENT_DIR/daily-tasks/$(date +%Y-%m-%d)-task.md"
    
    case "$AREA" in
        pattern-recognition)
            TASK="Review last 5 pattern notes and identify one connection I missed"
            ;;
        constraint-handling)
            TASK="Check last 3 build proposals for budget violations"
            ;;
        intent-detection)
            TASK="Review correction log and extract one pattern to watch for"
            ;;
        cost-optimization)
            TASK="Identify one analysis that could use local model instead of premium"
            ;;
    esac
    
    cat > "$TASK_FILE" << EOF
# Daily Self-Improvement Task — $(date +%Y-%m-%d)

## Task
$TASK

## Why
Build autonomous capability in: $AREA

## Success Criteria
- [ ] Task completed
- [ ] Learning logged
- [ ] Pattern extracted (if applicable)

## Learning
[To be filled after completion]

EOF
    
    echo "✓ Daily task created: $TASK_FILE"
    echo "  Task: $TASK"
    
    # Notify
    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=${TELEGRAM_CHAT_ID}" \
            -d "text=🎯 Daily Self-Improvement Task%0A%0A$TASK%0A%0ASee: self-improvement/daily-tasks/" \
            > /dev/null 2>&1 || true
    fi
fi

echo ""
echo "Usage:"
echo "  $0                    # Initialize structure"
echo "  $0 --log-correction 'what you wanted'  # Log correction"
echo "  $0 --daily-surprise    # Generate daily improvement task"
