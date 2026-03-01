#!/usr/bin/env bash
# AI Alpha Learning System Configuration

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export WORKSPACE_DIR="${OPENCLAW_ALPHA_DIR:-$SCRIPT_DIR}"
export INBOX_DIR="$WORKSPACE_DIR/inbox"
export CURRICULUM_DIR="$WORKSPACE_DIR/curriculum"
export SEEN_FILE="$WORKSPACE_DIR/.seen-content"

# Tier 1 Channels (Never Miss)
TIER1_CHANNELS=(
  "karpathy|UCXUPKJO5MZQN11PZGWH7WIA|youtube"
  "nate|UCt8xK0wfUCn5YTCYEmIDa1g|youtube"
  "kyle|UCR2btWn3i6e1S8iOQpR4V1A|youtube"
)

# X/Twitter handles for RSS (via nitter or similar)
TIER1_X=("karpathy" "natebjones" "kylepathy")

# Tier 2
TIER2_X=("bindureddy" "naval" "swyx")

# Create directories
mkdir -p "$INBOX_DIR" "$CURRICULUM_DIR"/{agentic-systems,business-models,technical-patterns,mental-models,market-timing}
touch "$SEEN_FILE"
touch "$INBOX_DIR/tier1-youtube.txt"
