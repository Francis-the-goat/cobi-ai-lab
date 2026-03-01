# Intent Policy Validation Checklist

Pass this checklist before coding.

## Completeness Gate
- [ ] Primary outcome metric has numeric baseline and target.
- [ ] Secondary metric and guardrail are defined.
- [ ] Trade-off rule has explicit condition + exception.
- [ ] Escalation trigger includes quantifiable thresholds.
- [ ] Rollback condition includes threshold + time window + owner.
- [ ] Budget owner and operator are named.

## Reliability Gate
- [ ] Decision policy can be represented in YAML without ambiguity.
- [ ] At least one failure mode has a deterministic handoff path.
- [ ] Logging fields are specified for every trigger.
- [ ] SLA defined for human escalations.

## Economics Gate
- [ ] Baseline metric is from real current process (not estimate only).
- [ ] 30-day target ties to revenue, cost, or throughput.
- [ ] Owner who approves spend is identified.

## Anti-Generic Gate
- [ ] Includes one workflow-specific non-obvious constraint (e.g., "after-hours messages must prioritize emergency jobs over quote requests").
- [ ] Includes one explicit scenario where automation should *not* act.

## Go/No-Go
- GO only if all boxes checked.
- If any box unchecked: status = PROTOTYPE (not build-ready).
