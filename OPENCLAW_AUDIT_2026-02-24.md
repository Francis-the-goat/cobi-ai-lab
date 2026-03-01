# OpenClaw Audit - 2026-02-24

## Executive Summary

Your setup is operational and capable, but it is not yet an autonomous business operator.

Current strengths:
- Stable primary model routing (Moonshot -> Codex -> Local fallback)
- Sandboxing enabled for default agent sessions
- Telegram channel connected with allowlist policy
- Startup health checks and version pin checks in place

Current bottlenecks:
- Secrets are still embedded in runtime config/state files
- Gateway probe behavior is inconsistent (RPC probe flaps)
- No production cron jobs for autonomous value generation
- No structured revenue engine (lead -> offer -> case study -> distribution)

Bottom line:
- You have a strong technical base.
- The next jump is not "better prompts"; it is converting the agent into a repeatable business system.

---

## Findings (Prioritized)

## P0 - Security and Trust Boundary Gaps

1) Secrets in plaintext config/state
- `~/.openclaw/openclaw.json` contains channel and gateway secrets.
- `~/.openclaw/agents/main/agent/auth*.json` contains provider auth material.
- `~/.openclaw/devices/paired.json` includes operator token material.

Impact:
- One accidental leak or compromised local account exposes the control plane.

2) `.env` permissions are too broad
- `~/.openclaw/.env` is currently `0644` (world-readable on local machine context).

Impact:
- Increases blast radius if additional local users/processes exist.

---

## P1 - Reliability/Operations Gaps

3) Gateway health is partially degraded
- `openclaw gateway status` frequently reports `RPC probe: failed` with close code `1006`.
- Runtime/listener can still be healthy, but control-plane diagnostics are noisy/inconsistent.

Impact:
- Harder incident detection and lower confidence in automation.

4) Client/gateway protocol mismatch events
- Repeated `tools.catalog` unknown method from `openclaw-control-ui vdev` in logs.

Impact:
- Risk of intermittent UI feature breakage.

5) Dev profile auth noise
- Repeated historical `No API key found for provider "anthropic"` for dev profile sessions.

Impact:
- Log noise hides real incidents.

---

## P1 - Business Execution Gaps

6) Autonomous engine is not wired
- `~/.openclaw/cron/jobs.json` has no jobs.
- HEARTBEAT describes tasks, but they are not executed on schedule.

Impact:
- System behaves like an on-demand assistant, not a 24/7 operator.

7) Knowledge system is incomplete
- Daily note exists, but no durable `MEMORY.md`.
- `workspace/memory/` is currently untracked in git.

Impact:
- Learnings are easy to lose and hard to compound.

---

## P2 - Capability Expansion Gaps

8) High-leverage skills missing dependencies
- Eligible skills: 14
- Missing requirements: 37
- Notably missing for business growth workflows:
  - `xurl` (X API operations)
  - `blogwatcher` (feed monitoring)
  - `clawhub` (skill distribution lifecycle)
  - `model-usage` (cost telemetry via codexbar)

Impact:
- Slower research/distribution loops and weaker cost instrumentation.

---

## 7-Day Upgrade Plan (High ROI)

## Day 1-2: Security Hardening

1) Rotate exposed tokens/keys:
- Telegram bot token
- Gateway auth token
- Web search key
- Provider keys in auth stores

2) Lock file permissions:
```bash
chmod 600 ~/.openclaw/.env
chmod 600 ~/.openclaw/openclaw.json
chmod 600 ~/.openclaw/agents/main/agent/auth.json ~/.openclaw/agents/main/agent/auth-profiles.json
chmod 600 ~/.openclaw/devices/paired.json
```

3) Enforce secret hygiene:
- Keep secrets in dedicated secret manager flow (or at minimum owner-only files).
- Do not store real keys in workspace docs.

## Day 3-4: Reliability Stabilization

4) Pin UI/runtime compatibility:
- Keep `openclaw` and control UI on the same release lane (avoid `vdev` drift on production sessions).

5) Keep single active gateway process:
- Avoid competing manual and LaunchAgent gateway runs.

6) Keep health monitor as source of truth:
- Continue using `~/.openclaw/scripts/startup-health-check.sh`.

## Day 5-7: Business Autonomy Wiring

7) Create cron jobs for revenue-adjacent outputs:
- Daily market scan brief
- Daily content draft generation
- Weekly case study synthesis
- Weekly offer refinement memo

8) Add durable memory workflow:
- Create `MEMORY.md` as weekly distillation
- Commit `workspace/memory/` notes to git

---

## "Super Employee" Architecture (What to Build Next)

## Core Role Split (single agent, 4 operating modes)

1) Research Analyst Mode
- Inputs: niche news, competitors, emerging tools
- Outputs: one-page daily brief + 3 actions

2) Growth Operator Mode
- Inputs: backlog + audience goals
- Outputs: 1 thread draft + 1 reel script daily

3) Delivery Engineer Mode
- Inputs: active build priorities
- Outputs: shipped feature, test notes, changelog

4) Commercial Strategist Mode
- Inputs: target niche pain points
- Outputs: offer upgrades, ROI calculator updates, outreach angles

## Required Artifact Every Day

- `memory/YYYY-MM-DD.md` daily log
- One distribution asset (thread draft/reel script)
- One shipping artifact (code/workflow/template)
- One commercial artifact (offer/pricing/lead insight)

No day is complete without all four.

---

## KPI Stack (Track Weekly)

Business:
- Qualified leads generated
- Discovery calls booked
- Proposals sent
- Revenue closed

Distribution:
- Posts published
- Profile visits
- Inbound DMs
- Email captures

Delivery:
- Shipped assets/week
- Cycle time (idea -> shipped)
- Case studies published

System Quality:
- Gateway uptime checks passing
- Failed runs/week
- Token/cost by model

---

## Immediate Next Commands

```bash
# 1) Verify setup health
~/.openclaw/scripts/validate-config.sh
~/.openclaw/scripts/check-version-pin.sh
~/.openclaw/scripts/startup-health-check.sh

# 2) Inspect cron baseline
openclaw cron list

# 3) Inspect scheduler run history
openclaw cron runs --limit 20
```

---

## What Will Actually Make You Win

The winning edge is not another model tweak.
It is a ruthless daily loop:

Ship -> Document -> Distribute -> Convert -> Iterate.

Your OpenClaw stack is now good enough.
Your next bottleneck is execution cadence and commercial focus.
