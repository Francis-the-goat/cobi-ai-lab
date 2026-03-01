#!/bin/bash
# Auto-Build Agent
# Takes "build [name]" and creates the asset from value card

set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"
WORKSPACE_PATH="${WORKSPACE_PATH:-$HOME/.openclaw/workspace}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$WORKSPACE_PATH/skills"
mkdir -p "$WORKSPACE_PATH/workflows"
mkdir -p "$WORKSPACE_PATH/tools"
mkdir -p "$WORKSPACE_PATH/content-drafts"
mkdir -p "$WORKSPACE_PATH/logs"

LOG_FILE="$WORKSPACE_PATH/logs/build-${TIMESTAMP}.log"

echo "=== Auto-Build Agent ===" | tee -a "$LOG_FILE"
echo "Started: $(date)" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Get build target
TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Usage: build [name]" | tee -a "$LOG_FILE"
    echo "Example: build 00-hot-memory" | tee -a "$LOG_FILE"
    exit 1
fi

echo "Building: $TARGET" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Find value card
VALUE_CARD="$VAULT_PATH/04-decisions/value-cards/${TARGET}-value.md"
if [ ! -f "$VALUE_CARD" ]; then
    echo "❌ Value card not found: $VALUE_CARD" | tee -a "$LOG_FILE"
    echo "Available value cards:" | tee -a "$LOG_FILE"
    ls -1 "$VAULT_PATH/04-decisions/value-cards/"/*-value.md 2>/dev/null | xargs -n1 basename | sed 's/-value.md//' | tee -a "$LOG_FILE" || echo "  (none)" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Found value card" | tee -a "$LOG_FILE"

# Extract asset type from value card (handle markdown)
ASSET_TYPE=$(grep "^\*\*" "$VALUE_CARD" | head -1 | sed 's/\*\*//g' | tr -d ' ' || echo "unknown")
# Fallback if empty
if [ -z "$ASSET_TYPE" ] || [ "$ASSET_TYPE" = "" ]; then
    ASSET_TYPE="research-note"
fi
echo "Asset type: $ASSET_TYPE" | tee -a "$LOG_FILE"

# Extract recommended action
REC_ACTION=$(grep "Recommended Action" "$VALUE_CARD" -A1 | tail -1 | sed 's/\*\*//' | sed 's/\*\*//' || echo "")
echo "Action: $REC_ACTION" | tee -a "$LOG_FILE"

# Build based on asset type
case "$ASSET_TYPE" in
    skill-template)
        echo "" | tee -a "$LOG_FILE"
        echo "[BUILDING] Skill Template..." | tee -a "$LOG_FILE"
        
        SKILL_DIR="$WORKSPACE_PATH/skills/${TARGET}-skill"
        mkdir -p "$SKILL_DIR"
        
        # Create skill structure
        cat > "$SKILL_DIR/README.md" << 'SKILLREADME'
# Skill: TARGET_NAME

## Overview
Built from value card analysis.

## Purpose
PURPOSE_HERE

## Usage
```bash
# Install
clawhub install local/TARGET_NAME-skill

# Use
openclaw skills run TARGET_NAME --input "your input"
```

## Configuration
Edit `config.yaml` to customize.

## Credits
Built by Auto-Build Agent from value extraction.
SKILLREADME
        
        # Replace placeholders
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$SKILL_DIR/README.md"
        
        # Create basic skill.yaml
        cat > "$SKILL_DIR/skill.yaml" << 'SKILLYAML'
name: TARGET_NAME-skill
version: 1.0.0
description: Auto-built skill from value extraction
author: Auto-Build Agent
entry: main.sh
inputs:
  - name: input
    description: Input to process
    required: true
SKILLYAML
        
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$SKILL_DIR/skill.yaml"
        
        # Create main script
        cat > "$SKILL_DIR/main.sh" << 'SKILLMAIN'
#!/bin/bash
# TARGET_NAME Skill
# Auto-built from value extraction

echo "Running TARGET_NAME skill..."
echo "Input: $1"

# Add your implementation here
echo "TODO: Implement skill logic"
echo "See README.md for details"
SKILLMAIN
        
        chmod +x "$SKILL_DIR/main.sh"
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$SKILL_DIR/main.sh"
        
        # Update value card status
        sed -i '' "s/Status: \*\*Proposed\*\*/Status: **Built** | Built: $(date)/" "$VALUE_CARD"
        echo "✅ Built: $SKILL_DIR/" | tee -a "$LOG_FILE"
        echo "" | tee -a "$LOG_FILE"
        echo "Next steps:" | tee -a "$LOG_FILE"
        echo "  1. Review: $SKILL_DIR/" | tee -a "$LOG_FILE"
        echo "  2. Implement logic in main.sh" | tee -a "$LOG_FILE"
        echo "  3. Test: bash $SKILL_DIR/main.sh 'test input'" | tee -a "$LOG_FILE"
        echo "  4. Publish: clawhub publish $SKILL_DIR/" | tee -a "$LOG_FILE"
        ;;
        
    workflow)
        echo "" | tee -a "$LOG_FILE"
        echo "[BUILDING] Workflow Template..." | tee -a "$LOG_FILE"
        
        WORKFLOW_FILE="$WORKSPACE_PATH/workflows/${TARGET}-workflow.md"
        
        cat > "$WORKFLOW_FILE" << 'WORKFLOW'
# Workflow: TARGET_NAME

## Overview
Auto-built workflow template from value extraction.

## When to Use
Use this workflow when: [context from value card]

## Steps

### Step 1: Preparation
- [ ] Gather required inputs
- [ ] Verify prerequisites
- [ ] Set up environment

### Step 2: Execution
- [ ] Run main process
- [ ] Monitor progress
- [ ] Handle errors

### Step 3: Completion
- [ ] Verify output
- [ ] Document results
- [ ] Clean up

## Automation
```bash
# Run this workflow
bash ~/.openclaw/workspace/workflows/TARGET_NAME-run.sh
```

## Value
Extracted from: TARGET_NAME value card
Built: DATE
WORKFLOW
        
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$WORKFLOW_FILE"
        sed -i '' "s/DATE/$(date)/g" "$WORKFLOW_FILE"
        
        # Create runner script
        cat > "$WORKSPACE_PATH/workflows/${TARGET}-run.sh" << 'RUNNER'
#!/bin/bash
# Workflow Runner: TARGET_NAME

echo "Running TARGET_NAME workflow..."

# TODO: Implement workflow steps
echo "Step 1: Preparation"
echo "Step 2: Execution"  
echo "Step 3: Completion"

echo "Workflow complete!"
RUNNER
        
        chmod +x "$WORKSPACE_PATH/workflows/${TARGET}-run.sh"
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$WORKSPACE_PATH/workflows/${TARGET}-run.sh"
        
        # Update value card
        sed -i '' "s/Status: \*\*Proposed\*\*/Status: **Built** | Built: $(date)/" "$VALUE_CARD"
        echo "✅ Built: $WORKFLOW_FILE" | tee -a "$LOG_FILE"
        ;;
        
    internal-tool)
        echo "" | tee -a "$LOG_FILE"
        echo "[BUILDING] Internal Tool..." | tee -a "$LOG_FILE"
        
        TOOL_FILE="$WORKSPACE_PATH/tools/${TARGET}.sh"
        
        cat > "$TOOL_FILE" << 'TOOL'
#!/bin/bash
# Tool: TARGET_NAME
# Auto-built from value extraction

set -euo pipefail

echo "=== TARGET_NAME Tool ==="
echo "Built: DATE"
echo ""

# TODO: Implement tool functionality
echo "This tool was auto-built from value extraction."
echo "Edit this file to add your implementation."
echo ""
echo "Usage: bash TARGET_NAME.sh [args]"
TOOL
        
        chmod +x "$TOOL_FILE"
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$TOOL_FILE"
        sed -i '' "s/DATE/$(date)/g" "$TOOL_FILE"
        
        # Update value card
        sed -i '' "s/Status: \*\*Proposed\*\*/Status: **Built** | Built: $(date)/" "$VALUE_CARD"
        echo "✅ Built: $TOOL_FILE" | tee -a "$LOG_FILE"
        ;;
        
    content-draft)
        echo "" | tee -a "$LOG_FILE"
        echo "[BUILDING] Content Draft..." | tee -a "$LOG_FILE"
        
        CONTENT_FILE="$WORKSPACE_PATH/content-drafts/${TARGET}-content.md"
        
        cat > "$CONTENT_FILE" << 'CONTENT'
# Content Draft: TARGET_NAME

## Hook
[Attention-grabbing opening about TARGET_NAME]

## Problem
[What problem does this solve?]

## Solution
[How does this work?]

## Implementation
[Step-by-step guide]

## Results
[What outcomes to expect]

## Call to Action
[What should reader do next?]

---
Draft created: DATE
Source: TARGET_NAME value card
CONTENT
        
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$CONTENT_FILE"
        sed -i '' "s/DATE/$(date)/g" "$CONTENT_FILE"
        
        # Update value card
        sed -i '' "s/Status: \*\*Proposed\*\*/Status: **Built** | Built: $(date)/" "$VALUE_CARD"
        echo "✅ Built: $CONTENT_FILE" | tee -a "$LOG_FILE"
        ;;
        
    *)
        echo "" | tee -a "$LOG_FILE"
        echo "⚠️ Unknown asset type: $ASSET_TYPE" | tee -a "$LOG_FILE"
        echo "Creating generic research note..." | tee -a "$LOG_FILE"
        
        RESEARCH_FILE="$VAULT_PATH/03-patterns/${TARGET}-built.md"
        cat > "$RESEARCH_FILE" << 'RESEARCH'
# Built: TARGET_NAME

## Status
Built from value card on DATE

## Asset Type
ASSET_TYPE

## Notes
This item was flagged for research. Review value card for details.

## Next Steps
- Determine if this should be built into a concrete asset
- Research implementation approach
- Estimate effort and value
RESEARCH
        
        sed -i '' "s/TARGET_NAME/$TARGET/g" "$RESEARCH_FILE"
        sed -i '' "s/DATE/$(date)/g" "$RESEARCH_FILE"
        sed -i '' "s/ASSET_TYPE/$ASSET_TYPE/g" "$RESEARCH_FILE"
        echo "✅ Created: $RESEARCH_FILE" | tee -a "$LOG_FILE"
        ;;
esac

echo "" | tee -a "$LOG_FILE"
echo "=== Build Complete ===" | tee -a "$LOG_FILE"
echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
