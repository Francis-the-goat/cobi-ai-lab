#!/usr/bin/env bash
set -euo pipefail

# Low-friction network egress guard for a dedicated OpenClaw host.
# Goal: preserve broad internet autonomy while reducing common compromise blast radius.
#
# What this enforces (via pf anchor):
# - Blocks outbound lateral-movement ports to RFC1918/ULA local networks.
# - Blocks access to cloud metadata endpoint (169.254.169.254).
# - Allows all other outbound traffic.
#
# Usage:
#   ./openclaw_network_guard.sh audit
#   ./openclaw_network_guard.sh apply
#   ./openclaw_network_guard.sh disable
#   ./openclaw_network_guard.sh status

MODE="${1:-audit}"
ANCHOR_NAME="ai.openclaw.egress"
ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"
PF_CONF="/etc/pf.conf"
IFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"

if [[ -z "${IFACE}" ]]; then
  echo "Unable to detect default network interface." >&2
  exit 1
fi

require_root_tools() {
  if ! sudo -n true >/dev/null 2>&1; then
    echo "This action needs sudo/root. Re-run with a sudo-capable shell." >&2
    exit 1
  fi
}

build_rules() {
  cat <<EOF
# ${ANCHOR_NAME} generated on $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Interface: ${IFACE}
table <oc_local_nets> const {
  10.0.0.0/8,
  172.16.0.0/12,
  192.168.0.0/16,
  169.254.0.0/16,
  100.64.0.0/10
}

# Block common lateral movement + infra probing ports on local/private networks.
block drop out quick on ${IFACE} inet proto { tcp udp } from any to <oc_local_nets> port {
  22, 111, 135, 137:139, 445, 3389, 5900, 2375, 2376, 3306, 5432, 6379, 27017, 11211
}

# Block cloud instance metadata endpoint.
block drop out quick on ${IFACE} inet from any to 169.254.169.254

# Keep broad internet autonomy.
pass out quick on ${IFACE} all keep state
EOF
}

ensure_anchor_in_pf_conf() {
  if ! sudo grep -q "anchor \"${ANCHOR_NAME}\"" "${PF_CONF}"; then
    echo "Adding ${ANCHOR_NAME} anchor to ${PF_CONF}"
    sudo cp "${PF_CONF}" "${PF_CONF}.bak.${ANCHOR_NAME}.$(date +%Y%m%d-%H%M%S)"
    {
      sudo cat "${PF_CONF}"
      echo
      echo "anchor \"${ANCHOR_NAME}\""
      echo "load anchor \"${ANCHOR_NAME}\" from \"${ANCHOR_FILE}\""
    } | sudo tee "${PF_CONF}" >/dev/null
  fi
}

apply_rules() {
  require_root_tools
  ensure_anchor_in_pf_conf
  build_rules | sudo tee "${ANCHOR_FILE}" >/dev/null
  sudo pfctl -f "${PF_CONF}" >/dev/null
  sudo pfctl -e >/dev/null || true
  echo "Applied ${ANCHOR_NAME} guardrails on ${IFACE}."
}

disable_rules() {
  require_root_tools
  if [[ -f "${ANCHOR_FILE}" ]]; then
    sudo cp "${ANCHOR_FILE}" "${ANCHOR_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  fi
  echo "# ${ANCHOR_NAME} disabled on $(date -u +"%Y-%m-%dT%H:%M:%SZ")" | sudo tee "${ANCHOR_FILE}" >/dev/null
  sudo pfctl -f "${PF_CONF}" >/dev/null
  echo "Disabled ${ANCHOR_NAME} rules."
}

status_rules() {
  if ! sudo -n true >/dev/null 2>&1; then
    echo "Status requires sudo for pfctl visibility." >&2
    exit 1
  fi
  echo "PF enabled state:"
  sudo pfctl -s info | awk -F': ' '/Status/{print $2}'
  echo
  echo "Anchor rules (${ANCHOR_NAME}):"
  sudo pfctl -a "${ANCHOR_NAME}" -s rules || true
}

case "${MODE}" in
  audit)
    echo "Planned rules for ${ANCHOR_NAME} on ${IFACE}:"
    build_rules
    ;;
  apply)
    apply_rules
    ;;
  disable)
    disable_rules
    ;;
  status)
    status_rules
    ;;
  *)
    echo "Usage: $0 {audit|apply|disable|status}" >&2
    exit 1
    ;;
esac

