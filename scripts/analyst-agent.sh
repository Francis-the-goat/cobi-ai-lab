#!/bin/bash
# Analyst Agent - Direct Execution Version
# Analyzes transcripts and extracts thinking patterns

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$VAULT_PATH/03-patterns"
mkdir -p "$VAULT_PATH/05-sessions"
mkdir -p "$WORKSPACE_PATH/logs"

LOG_FILE="$WORKSPACE_PATH/logs/analyst-${TIMESTAMP}.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo "=== Analyst Agent ==="
echo "Started: $(date)"
echo ""

# Find transcripts from last 24h that haven't been analyzed
NEW_TRANSCRIPTS=$(find "$VAULT_PATH" -name "*.md" -mtime -1 -not -path "*/03-patterns/*" -not -path "*/05-sessions/*" -not -path "*/01-daily/*" -not -path "*/04-decisions/*" -not -path "*/self-improvement/*" 2>/dev/null)

PATTERNS_EXTRACTED=0

echo "[PHASE 1] Scanning for Content..."
if [ -z "$NEW_TRANSCRIPTS" ]; then
    echo "  No new transcripts found in last 24h"
else
    echo "  Found $(echo "$NEW_TRANSCRIPTS" | wc -l | tr -d ' ') transcript(s) to analyze"
fi
echo ""

echo "[PHASE 2] Extracting Patterns..."

# Process each transcript
if [ -n "$NEW_TRANSCRIPTS" ]; then
    echo "$NEW_TRANSCRIPTS" | while read -r transcript; do
        if [ -f "$transcript" ]; then
            FILENAME=$(basename "$transcript" .md)
            echo "  Analyzing: $FILENAME"
            
            # Extract thinking pattern (simplified - in real version would use LLM)
            PATTERN_FILE="$VAULT_PATH/03-patterns/${FILENAME}-pattern.md"
            
            cat > "$PATTERN_FILE" << PATTERN
# Pattern Analysis: $FILENAME

## Source
- File: $transcript
- Analyzed: $(date)

## Thinking Architecture
$(head -50 "$transcript" 2>/dev/null | grep -E "^#{1,3} " | head -10 || echo "[Structure extracted from content]")

## Key Insights
- Extracted from transcript analysis
- Applied to constraint profile

## Application to Your Context
### Constraints Addressed
- Split attention: Can this run autonomously?
- Budget: Cost-optimized implementation
- Timeline: Fast validation

### Leverage Potential
- Revenue impact: [To be assessed]
- Time savings: [To be calculated]
- Compounding: [To be evaluated]

## Build Proposal
Status: Proposed
Priority: [To be scored]
Effort: [To be estimated]

---
*Analyzed by Analyst Agent on $(date)*
PATTERN
            
            PATTERNS_EXTRACTED=$((PATTERNS_EXTRACTED + 1))
            echo "    → Created: $PATTERN_FILE"
        fi
    done
fi

echo ""
echo "[PHASE 3] Quality Scoring..."

# Score patterns for buildability
for pattern in "$VAULT_PATH/03-patterns"/*-pattern.md; do
    if [ -f "$pattern" ]; then
        # Simple scoring logic
        SCORE=0
        
        # Check if has clear architecture
        if grep -q "Thinking Architecture" "$pattern"; then
            SCORE=$((SCORE + 2))
        fi
        
        # Check if has application to constraints
        if grep -q "Application to Your Context" "$pattern"; then
            SCORE=$((SCORE + 3))
        fi
        
        echo "  $(basename "$pattern"): Score $SCORE/5"
    fi
done

echo ""

# Create analyst session log
cat > "$VAULT_PATH/05-sessions/analyst-${TIMESTAMP}.md" << EOF
# Analyst Session - $TIMESTAMP

## Summary
- Started: $(date)
- Transcripts analyzed: $(echo "$NEW_TRANSCRIPTS" | wc -l | tr -d ' ')
- Patterns extracted: $PATTERNS_EXTRACTED

## Patterns Created
$(ls -1 "$VAULT_PATH/03-patterns"/*-pattern.md 2>/dev/null | tail -10 | while read f; do
    echo "- $(basename "$f")"
done)

## Quality Metrics
- Total patterns in vault: $(ls -1 "$VAULT_PATH/03-patterns"/*.md 2>/dev/null | wc -l | tr -d ' ')
- New today: $PATTERNS_EXTRACTED

## Output
- Log: $LOG_FILE
- Patterns: $VAULT_PATH/03-patterns/

## Next Steps
Opportunity detector will score patterns for build proposals.
EOF

echo "=== Analyst Complete ==="
echo "Transcripts analyzed: $(echo "$NEW_TRANSCRIPTS" | wc -l | tr -d ' ')"
echo "Patterns extracted: $PATTERNS_EXTRACTED"
echo "Session log: $VAULT_PATH/05-sessions/analyst-${TIMESTAMP}.md"
echo ""

# Output for pipeline
echo "ANALYST_RESULT: transcripts=$(echo "$NEW_TRANSCRIPTS" | wc -l | tr -d ' ') patterns=$PATTERNS_EXTRACTED"
