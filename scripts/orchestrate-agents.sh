#!/bin/bash
# Sub-Agent Orchestrator
# Spawns specialized agents for different tasks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_PATH="${VAULT_PATH:-$HOME/obsidian/openclaw}"

echo "=== Sub-Agent Orchestrator ==="

# Function: Spawn Harvester Agent
spawn_harvester() {
    echo "[$(date)] Spawning Harvester Agent..."
    
    # Create session with specific agent ID
    SESSION_KEY=$(openclaw sessions spawn \
        --agent-id harvester \
        --mode session \
        --task "Monitor Tier 1 sources, download new content, transcribe, log to vault" \
        --cwd "$VAULT_PATH" \
        --json | jq -r '.sessionKey')
    
    echo "  → Harvester session: $SESSION_KEY"
    echo "$SESSION_KEY" > "$VAULT_PATH/.harvester-session"
}

# Function: Spawn Analyst Agent (triggered after harvester)
spawn_analyst() {
    local harvester_session="$1"
    
    echo "[$(date)] Spawning Analyst Agent..."
    
    # Check if harvester completed
    STATUS=$(openclaw sessions status "$harvester_session" --json | jq -r '.status')
    
    if [ "$STATUS" = "completed" ]; then
        SESSION_KEY=$(openclaw sessions spawn \
            --agent-id analyst \
            --mode session \
            --task "Analyze patterns from harvester output, extract thinking architectures, write to 03-patterns/" \
            --cwd "$VAULT_PATH" \
            --json | jq -r '.sessionKey')
        
        echo "  → Analyst session: $SESSION_KEY"
        echo "$SESSION_KEY" > "$VAULT_PATH/.analyst-session"
    else
        echo "  → Harvester still running, will retry in 10 minutes"
        (sleep 600 && "$0" --check-analyst) &
    fi
}

# Function: Spawn Builder Agent (on approval)
spawn_builder() {
    local proposal="$1"
    
    echo "[$(date)] Spawning Builder Agent for: $proposal"
    
    SESSION_KEY=$(openclaw sessions spawn \
        --agent-id builder \
        --mode run \
        --task "Build skill from proposal: $proposal" \
        --cwd "$VAULT_PATH" \
        --json | jq -r '.sessionKey')
    
    echo "  → Builder session: $SESSION_KEY"
    
    # Wait for completion and notify
    (sleep 5 && openclaw sessions status "$SESSION_KEY" --json | jq -r '.status' && \
     echo "Build complete for $proposal" | openclaw notify telegram) &
}

# Main logic
case "${1:-}" in
    --harvester)
        spawn_harvester
        ;;
    --analyst)
        if [ -f "$VAULT_PATH/.harvester-session" ]; then
            spawn_analyst "$(cat "$VAULT_PATH/.harvester-session")"
        else
            echo "No harvester session found"
            exit 1
        fi
        ;;
    --builder)
        if [ -n "${2:-}" ]; then
            spawn_builder "$2"
        else
            echo "Usage: $0 --builder <proposal-name>"
            exit 1
        fi
        ;;
    --chain)
        # Full chain: harvester → analyst
        spawn_harvester
        sleep 2
        spawn_analyst "$(cat "$VAULT_PATH/.harvester-session")"
        ;;
    *)
        echo "Usage:"
        echo "  $0 --harvester     # Spawn harvester agent"
        echo "  $0 --analyst       # Spawn analyst (after harvester)"
        echo "  $0 --builder NAME  # Spawn builder for proposal"
        echo "  $0 --chain         # Run full harvest→analyze chain"
        exit 1
        ;;
esac

echo "[$(date)] Done"
