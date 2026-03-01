# SECURITY_ARCHITECTURE_2026-02-26

Purpose: keep high agent autonomy while enforcing strong control-plane and execution-plane security.

## 1) Security Objectives

- Keep agents useful (do not globally disable core execution lanes).
- Contain blast radius per lane (sandbox + workspace boundaries + approvals).
- Harden trust boundaries for node execution and channel ingress.
- Detect drift quickly and recover fast.

## 2) Current Baseline (Applied)

- `agents.defaults.sandbox.mode=all`
- `tools.elevated.enabled=false`
- `tools.fs.workspaceOnly=true`
- `tools.exec.applyPatch.workspaceOnly=true`
- `tools.sandbox.tools.allow` includes `nodes`
- `tools.sandbox.tools.deny` blocks browser/web + high-risk channel/control tools
- Gateway running on loopback only (`127.0.0.1:19001`)
- Gateway auth token rotated on 2026-02-26

## 3) Threats That Matter Most

- Control-plane exposure (gateway token theft, reverse proxy mis-trust, open bind).
- Runtime escalation from unsafe command execution paths.
- Sandbox escape or sandbox-policy bypass (especially with path tricks and network edges).
- Untrusted channel input driving high-risk tools.
- Small-model misuse with untrusted web inputs.
- Node/device overreach when pairing is too permissive.

## 4) Architecture Controls by Lane

### A) Orchestrator + Builder (high-value decisions/builds)

- Keep premium models primary (`Strategist`, `Builder`).
- Keep sandbox enabled even for primary sessions.
- Use approvals for uncommon binaries and privileged operations.

### B) Local Worker Lanes (LocalFast/LocalCode/LocalSmart)

- Keep sandbox mandatory.
- Keep web/browser tools disabled for these lanes.
- Use script-first workflows for repetitive tasks.

### C) Node Lane (remote/device actions)

- Keep `nodes` tool enabled, but only for paired approved devices.
- Use explicit node targeting in sensitive tasks.
- Require command allowlist for node-run style actions.

## 5) Control Plane Hardening

- Keep `gateway.bind=loopback` unless you intentionally deploy remote access.
- If using reverse proxy, set `gateway.trustedProxies` explicitly.
- Keep one gateway instance only; avoid manual + LaunchAgent duplicates.
- Rotate gateway token on any process/log exposure event.

## 6) Secret Hygiene

- Keep credentials outside workspace repos.
- Use owner-only permissions (`600`) for secret-bearing files.
- Prefer env-based provider keys over plaintext config where possible.
- Rotate channel/provider tokens on incident suspicion.

## 7) Detection and Guardrails

- Run `openclaw security audit --json` daily.
- Keep launch health checks enabled.
- Treat these as incident triggers:
  - sudden gateway restart loops
  - unknown paired nodes
  - unexpected tool enablement drift
  - repeated channel conflicts or unauthorized sender activity

## 8) Operational Runbook

### Daily

```bash
openclaw gateway health
openclaw security audit --json
openclaw sandbox explain
openclaw nodes list
```

### Weekly

```bash
openclaw status --deep
openclaw approvals get
openclaw logs --follow
```

### Incident

```bash
# 1) Rotate gateway token and reload service
NEW_TOKEN=$(openssl rand -hex 24)
openclaw config set gateway.auth.token "$NEW_TOKEN"
openclaw gateway install --force
openclaw gateway start

# 2) Re-check hardening
openclaw security audit --json
openclaw sandbox explain
```

## 9) Non-Negotiables

- No direct internet exposure of gateway without explicit hardening.
- No disabling sandbox globally to fix convenience issues.
- No node pairing approvals without verifying device identity.
- No long-term operation with critical findings in `security audit`.
