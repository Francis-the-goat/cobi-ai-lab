# Example — Home Services Intake Intent Policy

## Workflow Definition
- Workflow name: Inbound lead intake + booking triage
- Business owner: Operations Manager
- Operator: Automation specialist
- Version/date: v0.1 / 2026-02-26

## Primary Outcome Metric
- Metric: Lead response time (seconds)
- Baseline: 8-15 minutes during business hours; missed calls after-hours
- 30-day target: <120 seconds median response time
- Why it matters: Faster response increases booked jobs and captured revenue

## Secondary Efficiency Metric
- Metric: Booking conversion rate
- Baseline: 2-3% web conversion equivalent benchmark from synthesis notes
- Target: 5-6% equivalent conversion after triage optimization
- Guardrail: Customer satisfaction >= 4.2/5 on post-call survey

## Trade-off Rule
- Prioritize response speed over perfect categorization for first contact.
- Exception: If emergency intent detected (gas leak, no hot water in aged care, electrical hazard), force immediate high-priority routing and skip normal script.

## Escalation Trigger
- Trigger conditions:
  - Customer asks pricing beyond approved band
  - Address validation fails twice
  - Customer sentiment marked "angry" or "urgent" with safety keywords
- Max autonomous attempts before handoff: 2
- Human role: On-call dispatcher
- SLA for human response: 5 minutes

## Rollback Condition
- Failure threshold: >5% conversations produce unresolved status OR >2 critical misroutes in 7 days
- Observation window: rolling 7 days
- Rollback scope: disable auto-booking, keep FAQ triage live
- Recovery owner: Operations Manager + Automation specialist

## Machine-Readable Policy
```yaml
intent_policy:
  workflow: "home_services_intake"
  primary_metric:
    name: "lead_response_seconds"
    baseline: "8-15m"
    target_30d: "<120s"
  secondary_metric:
    name: "booking_conversion_rate"
    baseline: "2-3%"
    target_30d: "5-6%"
    guardrail: ">=4.2/5 CSAT"
  tradeoff_rule:
    prioritize: "lead_response_seconds"
    over: "categorization_accuracy"
    when: "standard inbound"
    exception:
      condition: "safety_emergency_keywords_detected"
      behavior: "immediate_dispatcher_handoff"
  escalation:
    conditions:
      - "pricing_out_of_band"
      - "address_validation_failed_twice"
      - "angry_or_urgent_sentiment"
    max_attempts: 2
    handoff_role: "on_call_dispatcher"
    sla_minutes: 5
  rollback:
    failure_threshold: ">5% unresolved OR >2 critical misroutes"
    window: "7d rolling"
    scope: "disable_auto_booking"
    owner: "ops_manager"
```

## Notes
This example is intentionally conservative: it limits autonomous actions in high-risk contexts while preserving speed for normal inquiries.
