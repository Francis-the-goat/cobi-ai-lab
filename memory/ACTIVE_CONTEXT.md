# ACTIVE_CONTEXT.md — Context Override

Last updated: 2026-02-25 22:42 AEST

## Purpose
This file is the highest-priority context override for current operations.
Use it to prevent drift from stale or legacy notes.

## Current Operating Intent
1. Build a high-agency AI operator across five tracks: `SMB`, `UPSKILL`, `BRAND`, `LIFE`, `SYSTEM`.
2. Treat SMB as a monetization wedge, not the default answer to every prompt.
3. Prefer non-generic outputs with concrete evidence, flaws found, and explicit decisions.

## Hard Rules
1. If the last primary track was `SMB`, bias the next primary track away from SMB unless blocked by a hard deadline or active client issue.
2. Every substantive output must include:
   - one concrete artifact reference (file path, source URL, metric log, or command result)
   - one identified flaw/risk and one mitigation
3. Do not repeat chatbot-level playbooks; produce operator-grade actions.

## Current Priority Order
1. Remove system reliability bottlenecks (`SYSTEM`) that block delivery.
2. Compound capability and execution quality (`UPSKILL`, `LIFE`).
3. Convert real work into distribution (`BRAND`).
4. Execute monetization actions (`SMB`) with evidence-backed timing.

## Legacy Context Handling
- Legacy SMB-heavy notes are archived under `memory/archive/legacy-smb/`.
- If legacy files conflict with this document, this document wins.
