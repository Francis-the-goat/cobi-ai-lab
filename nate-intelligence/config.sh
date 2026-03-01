#!/usr/bin/env bash
# Configuration for Nate B Jones Intelligence System

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export NATE_CHANNEL_ID="UCt8xK0wfUCn5YTCYEmIDa1g"
export NATE_CHANNEL_NAME="Nate B Jones"
export WORKSPACE_DIR="${OPENCLAW_NATE_DIR:-$SCRIPT_DIR}"
export PROCESSED_DIR="$WORKSPACE_DIR/processed"
export INBOX_DIR="$WORKSPACE_DIR/inbox"
export SEEN_FILE="$WORKSPACE_DIR/.seen-videos"

# Create dirs
mkdir -p "$PROCESSED_DIR" "$INBOX_DIR"
touch "$SEEN_FILE"
touch "$INBOX_DIR/pending.txt"
