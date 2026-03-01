# SMB Intent Layer Template (Reusable Asset)

Created: 2026-02-26  
Primary Track: SYSTEM  
Secondary Track: SMB

## Problem
Most SMB automation builds fail because they specify tools and workflows but never encode decision intent (what to optimize, trade-offs, escalation thresholds, rollback triggers). This creates agent drift, inconsistent outcomes, and buyer mistrust.

## User
- Primary user: Cobi (operator) building client-facing automations
- Secondary user: implementation contractors/future team members who need a deterministic spec before build

## Reusable Workflow
1. Select one business workflow (e.g., inbound lead response).
2. Fill `01-intent-layer-template.md` with business metrics and decision policy.
3. Run `02-intent-policy-validation-checklist.md` to check policy completeness.
4. Use output as the required pre-build section in every asset spec.
5. Track before/after KPI in pilot and update policy version.

## Files in this asset
- `01-intent-layer-template.md` — fillable template (copy/paste into asset specs)
- `02-intent-policy-validation-checklist.md` — go/no-go gate before implementation
- `03-example-home-services-intake.md` — worked example for a common SMB wedge
- `EVIDENCE.md` — validated signals used to justify this build

## Build Notes
This asset operationalizes today's validated insight: intent engineering must be explicit and measurable, or automation quality degrades.
