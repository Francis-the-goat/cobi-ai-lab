# Validation Plan - smb-intake-automation

## Hypothesis
- If we ship: a structured lead-intake + follow-up orchestration workflow
- Then: businesses will reduce response time and increase booking conversion from inbound leads

## Metrics
- Leading indicator: median first-response time; percent of leads with completed intake summary
- Lagging indicator: lead-to-booking conversion rate; revenue per inbound lead

## Test Design
- Test window: 14 days
- Target users: 1-2 local service SMB operators
- Data collection method: manual baseline vs assisted workflow logs in shared sheet

## Thresholds
- Build now threshold: >=20% conversion improvement or >=60% response-time reduction
- Iterate threshold: 5-19% improvement with clear failure patterns to fix
- Kill threshold: <5% improvement and low operator adoption after week 2

## Kill Criteria
- [ ] Operators do not use outputs consistently after onboarding fixes
- [ ] No measurable booking improvement after two iteration cycles

## Next Experiment
- If pass: add niche-specific quote drafting and objection-handling modules
- If fail: narrow to a single service niche and simplify intake fields by 30%
