# Intent Layer Template (SMB Agent Workflow)

Use this before implementation. If a section is blank, do not build yet.

## 1) Workflow Definition
- Workflow name:
- Business owner:
- Operator:
- Version/date:

## 2) Primary Outcome Metric (North Star)
- Metric:
- Baseline (current):
- 30-day target:
- Why this metric matters to budget owner:

## 3) Secondary Efficiency Metric
- Metric:
- Baseline:
- Target:
- Guardrail (minimum acceptable quality):

## 4) Trade-off Rule (Required)
Define what the agent should optimize when objectives conflict.

Format:
- Prioritize `<primary metric>` over `<secondary metric>` when `<condition>`.
- Exception: if `<risk condition>`, switch to `<fallback behavior>`.

## 5) Escalation Trigger (Required)
When should the agent hand off to human?

- Trigger conditions (quantified):
- Max autonomous attempts before handoff:
- Human role for escalation:
- SLA for human response:

## 6) Rollback Condition (Required)
When should automation be partially or fully disabled?

- Failure threshold:
- Observation window:
- Rollback scope (feature/module/full):
- Recovery checklist owner:

## 7) Decision Policy (Machine-Readable)
```yaml
intent_policy:
  workflow: ""
  primary_metric:
    name: ""
    baseline: ""
    target_30d: ""
  secondary_metric:
    name: ""
    baseline: ""
    target_30d: ""
    guardrail: ""
  tradeoff_rule:
    prioritize: ""
    over: ""
    when: ""
    exception:
      condition: ""
      behavior: ""
  escalation:
    conditions: []
    max_attempts: 0
    handoff_role: ""
    sla_minutes: 0
  rollback:
    failure_threshold: ""
    window: ""
    scope: ""
    owner: ""
```

## 8) Validation Plan
- Pilot duration:
- Sample size / volume:
- Logging required:
- Weekly review owner:

## 9) Approvals
- Budget owner sign-off:
- Operator sign-off:
- Go/No-go date:
