#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
profile="${2:-dev}"

if [[ -z "$mode" ]]; then
  echo "Usage: $0 <quality|build|cool>"
  exit 1
fi

case "$mode" in
  quality)
    openclaw --profile "$profile" models set Strategist
    openclaw --profile "$profile" models fallbacks clear
    openclaw --profile "$profile" models fallbacks add Builder
    openclaw --profile "$profile" models fallbacks add LocalSmart
    openclaw --profile "$profile" models fallbacks add LocalCode
    openclaw --profile "$profile" models fallbacks add LocalFast
    ;;
  build)
    openclaw --profile "$profile" models set Builder
    openclaw --profile "$profile" models fallbacks clear
    openclaw --profile "$profile" models fallbacks add Strategist
    openclaw --profile "$profile" models fallbacks add LocalSmart
    openclaw --profile "$profile" models fallbacks add LocalCode
    openclaw --profile "$profile" models fallbacks add LocalFast
    ;;
  cool)
    openclaw --profile "$profile" models set LocalFast
    openclaw --profile "$profile" models fallbacks clear
    openclaw --profile "$profile" models fallbacks add LocalCode
    openclaw --profile "$profile" models fallbacks add LocalSmart
    openclaw --profile "$profile" models fallbacks add Strategist
    openclaw --profile "$profile" models fallbacks add Builder
    ;;
  *)
    echo "Unknown mode: $mode"
    echo "Valid modes: quality, build, cool"
    exit 1
    ;;
esac

echo "Applied model mode: $mode (profile: $profile)"
openclaw --profile "$profile" models fallbacks list
