# Asset Spec - smb-intake-automation

## Asset Definition
- Type: hybrid
- Name: Lead-to-Booked-Job Orchestrator
- One-line value proposition: Turn inbound SMB leads into qualified, follow-up-ready booking candidates in minutes.

## User Story
- As a: solo service business owner
- I need: an intake assistant that qualifies leads and keeps follow-ups moving
- So that: I book more jobs without being glued to my phone

## Boundaries
- In scope: inbound lead triage, qualification Q&A, summary generation, follow-up reminders
- Out of scope: payment handling, calendar writes, legal/financial advice, irreversible actions

## Inputs / Outputs
- Inputs: new lead message, service type, location window, urgency, budget range
- Outputs: qualification summary, next action recommendation, follow-up message sequence

## V1 Acceptance Criteria
- [ ] For each new lead, generate a structured intake summary in under 2 minutes
- [ ] Produce one recommended response draft and one follow-up draft
- [ ] Flag "high-intent" leads using explicit rubric fields (urgency + fit + budget signal)

## 7-Day Build Plan
- Day 1: Define intake schema and qualification rubric for first niche
- Day 2: Create skill prompt + templates for intake and follow-up
- Day 3: Build message parsing + summary formatting workflow
- Day 4: Add lead scoring logic and high-intent flagging
- Day 5: Run 10 synthetic lead simulations, tune failure cases
- Day 6: Pilot with one real business workflow
- Day 7: Review outcomes, finalize v1, publish case-study draft

## Risks and Mitigation
- Risk 1: Low-quality lead context causes weak qualification
  Mitigation: enforce minimum required fields and ask clarifying follow-up automatically
- Risk 2: Owner ignores recommendations, reducing realized ROI
  Mitigation: deliver short "next best action" output with low-friction copy/paste drafts
