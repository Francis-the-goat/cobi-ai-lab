#!/usr/bin/env bash
set -euo pipefail

# Skill integrity guard for user-managed skills.
# Detects unexpected changes that may indicate malicious edits or supply-chain drift.
#
# Usage:
#   ./skills_integrity_guard.sh snapshot
#   ./skills_integrity_guard.sh verify
#   ./skills_integrity_guard.sh status

MODE="${1:-status}"
SKILLS_ROOT="${SKILLS_ROOT:-$HOME/.openclaw/skills}"
SECURITY_DIR="${SECURITY_DIR:-$HOME/.openclaw/workspace/security}"
MANIFEST="${MANIFEST:-$SECURITY_DIR/skills-integrity.manifest.sha256}"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing command: $1" >&2
    exit 1
  }
}

need_cmd shasum
need_cmd diff

mkdir -p "${SECURITY_DIR}"

if [[ ! -d "${SKILLS_ROOT}" ]]; then
  echo "Skills root not found: ${SKILLS_ROOT}" >&2
  exit 1
fi

build_manifest() {
  local out_file="$1"
  (
    cd "${SKILLS_ROOT}"
    find . -type f \
      ! -path "*/.git/*" \
      ! -name ".DS_Store" \
      -print0 \
      | sort -z \
      | xargs -0 shasum -a 256
  ) > "${out_file}"
}

check_permissions() {
  local world_writable
  world_writable="$(find "${SKILLS_ROOT}" -type f -perm -0002 -print || true)"
  if [[ -n "${world_writable}" ]]; then
    echo "FAIL: world-writable skill files detected:" >&2
    echo "${world_writable}" >&2
    exit 1
  fi
}

snapshot() {
  build_manifest "${MANIFEST}"
  check_permissions
  echo "Snapshot written: ${MANIFEST}"
}

verify() {
  if [[ ! -f "${MANIFEST}" ]]; then
    echo "No baseline manifest found. Run snapshot first." >&2
    exit 1
  fi
  local tmp
  tmp="$(mktemp)"
  build_manifest "${tmp}"
  if ! diff -u "${MANIFEST}" "${tmp}" >/tmp/skills-integrity.diff 2>&1; then
    echo "FAIL: skill integrity drift detected."
    echo "Diff: /tmp/skills-integrity.diff"
    rm -f "${tmp}"
    exit 1
  fi
  check_permissions
  rm -f "${tmp}"
  echo "PASS: skills integrity verified"
}

status() {
  local files count
  files="$(find "${SKILLS_ROOT}" -type f ! -path "*/.git/*" | wc -l | tr -d ' ')"
  count="0"
  [[ -f "${MANIFEST}" ]] && count="$(wc -l < "${MANIFEST}" | tr -d ' ')"
  echo "Skills root: ${SKILLS_ROOT}"
  echo "Current files: ${files}"
  echo "Baseline entries: ${count}"
  [[ -f "${MANIFEST}" ]] && echo "Baseline: ${MANIFEST}" || echo "Baseline: not created"
}

case "${MODE}" in
  snapshot) snapshot ;;
  verify) verify ;;
  status) status ;;
  *)
    echo "Usage: $0 {snapshot|verify|status}" >&2
    exit 1
    ;;
esac

