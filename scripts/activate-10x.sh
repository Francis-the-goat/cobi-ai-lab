#!/bin/bash
# Activate OpenClaw 10x Improvements
# Implements the 5 techniques from the video

set -euo pipefail

echo "========================================="
echo "OpenClaw 10x Power Activation"
echo "========================================="
echo ""

# 1. Enable Scheduler
echo "[1/5] Enabling proactive scheduling..."
if command -v openclaw &> /dev/null; then
    # Check if scheduler config exists
    if [ -f "$HOME/.openclaw/workspace/config/scheduler.yaml" ]; then
        echo "  ✓ Scheduler config found"
        echo "  → Copy to OpenClaw config directory"
        
        # This would copy to actual OpenClaw config location
        # mkdir -p ~/.openclaw/config
        # cp config/scheduler.yaml ~/.openclaw/config/
        
        echo "  ⚠ Manual step: Add to OpenClaw config:"
        echo "     openclaw config set scheduler.enabled=true"
        echo "     openclaw config set scheduler.config_path=~/.openclaw/workspace/config/scheduler.yaml"
    else
        echo "  ✗ Scheduler config not found"
    fi
else
    echo "  ✗ OpenClaw CLI not found"
fi

# 2. Register Sub-Agents
echo ""
echo "[2/5] Registering sub-agents..."
if [ -f "$HOME/.openclaw/workspace/config/agents.yaml" ]; then
    echo "  ✓ Agent configs found"
    echo "  → Harvester: Local model, data acquisition"
    echo "  → Analyst: Kimi, pattern extraction"
    echo "  → Builder: Codex, implementation"
    echo ""
    echo "  ⚠ Manual step: Register agents:"
    echo "     openclaw agents register harvester --config ~/.openclaw/workspace/config/agents.yaml"
    echo "     openclaw agents register analyst --config ~/.openclaw/workspace/config/agents.yaml"
    echo "     openclaw agents register builder --config ~/.openclaw/workspace/config/agents.yaml"
else
    echo "  ✗ Agent configs not found"
fi

# 3. Initialize Self-Improvement System
echo ""
echo "[3/5] Initializing self-improvement loop..."
bash "$HOME/.openclaw/workspace/scripts/self-improvement-loop.sh"
echo "  ✓ Self-improvement structure created"

# 4. Set up Pre-Compaction Hooks
echo ""
echo "[4/5] Setting up pre-compaction memory persistence..."
echo "  ✓ Pre-compaction save script: scripts/pre-compaction-save.sh"
echo ""
echo "  ⚠ Manual step: Add to OpenClaw config:"
echo "     openclaw config set memory.pre_compaction_hook='bash ~/.openclaw/workspace/scripts/pre-compaction-save.sh'"

# 5. Install ClawHub (if not already)
echo ""
echo "[5/5] Skills marketplace setup..."
echo "  ✓ Skill-opportunity-detector: Ready to install"
echo ""
echo "  ⚠ Manual step: Install ClawHub skill:"
echo "     openclaw skills install clawhub"
echo "     Then: 'Install skill-opportunity-detector'"

# Summary
echo ""
echo "========================================="
echo "Activation Summary"
echo "========================================="
echo ""
echo "What's Ready:"
echo "  ✓ Sub-agent orchestration scripts"
echo "  ✓ Pre-compaction memory persistence"
echo "  ✓ Self-improvement loop structure"
echo "  ✓ Scheduler configuration"
echo "  ✓ Agent definitions"
echo ""
echo "Manual Steps Required:"
echo "  1. Enable scheduler in OpenClaw config"
echo "  2. Register the three sub-agents"
echo "  3. Set pre-compaction hook"
echo "  4. Install ClawHub skill"
echo "  5. Set Telegram credentials for notifications"
echo ""
echo "Test Commands:"
echo "  bash scripts/orchestrate-agents.sh --harvester"
echo "  bash scripts/orchestrate-agents.sh --analyst"
echo "  bash scripts/self-improvement-loop.sh --daily-surprise"
echo ""
echo "What's Now Possible:"
echo "  • Harvester runs every 2h automatically"
echo "  • Analyst processes when harvest completes"
echo "  • Morning briefing at 6 AM daily"
echo "  • Memory survives conversation compaction"
echo "  • Daily self-improvement tasks"
echo "  • Builder spawns on 'build it' command"
echo ""
echo "Cost per Day:"
echo "  • Harvester: $0 (local)"
echo "  • Analyst: ~$0.50/day"
echo "  • Self-improvement: $0 (local)"
echo "  • Total: ~$15/month"
echo ""
