# Asset Pack: Home Services AI Agent
**Slug:** home-services-ai-agent  
**Date:** 2026-02-25  
**Decision:** PROTOTYPE  
**Vertical:** Home Services (HVAC/Plumbing/Electrical)  
**Signal Strength:** ⭐⭐⭐ HIGH

---

## What I Did

- Analyzed 3 existing asset packs in workspace (smb-intake-ops, smb-intake-automation, home-services-ai-agent)
- Scored opportunities against LEVERAGE_OS rubric: Pain Urgency × Economic Value × Build Speed
- Home Services AI Agent scored highest: 5/5 pain urgency, 5/5 economic value, 4/5 build speed
- Validated against QUALITY_BAR.md: Evidence ✅ Economics ✅ Decision Clarity ✅ Execution Quality ✅
- Consolidated existing research into unified asset pack with 7-day validation sprint plan

---

## What Matters

**1. Market Signal Strength: HIGH**
- Regal.ai case studies: 96% faster answer time, 41% conversion increase, 42% speed-to-lead improvement
- YC-backed players (Retell AI, Avoca) have dedicated home services verticals
- Angi, Kohler, Pella already deployed = market validation

**2. Economic Impact: $208K/year for typical 10-tech HVAC company**
- Baseline: 50 leads/week, 30% missed (15 leads), $800 avg job, 40% close rate = $11,200/week
- With AI Agent: 96% answer rate, 19 booked jobs = $15,200/week
- Additional weekly revenue: $4,000 ($208K annually)
- Client ROI: 3,900%+ first year
- Revenue model: $3-5K setup + $1,500/month = $180K ARR at 10 clients

**3. Buyer Profile: Ideal for Cobi's positioning**
- Owner-operator, 3-20 techs, $1M-5M revenue
- Fast decision maker (no procurement cycle)
- Authentic positioning: warehouse background creates trust with trades
- Australian market has less competition than US

---

## Tonight's Top 3

1. **Open Retell AI account** ($25 free credit) + create basic voice agent with HVAC greeting
2. **Google "HVAC Gold Coast"** → identify 5 target businesses → research contact info
3. **Draft first outreach message** using validation script → send by end of day

---

## Upskill Sprint (20 min)

**Concept:** Voice AI orchestration architecture (Retell AI → OpenClaw → Cal.com → Airtable)
**Drill:** Watch Retell AI "Getting Started" video + create a test voice agent in playground

---

## Risk

**Risk:** Owners don't respond to outreach, validation fails within 5 days  
**Mitigation:** Multi-channel approach (email + DM + phone), expand to Brisbane if needed, offer $50 gift card for 30-min conversation, pivot to healthcare vertical (similar pain, proven demand) if <3 responses by Day 3

---

## 7-Day Validation Sprint Plan

### Day 1 (Today) — Setup & Targeting
- [ ] Review asset pack in full (2 hours)
- [ ] Set up Retell AI account ($25 free credit)
- [ ] Identify 5 local HVAC/plumbing businesses (Gold Coast area)
- [ ] Research: Google Business, websites, social presence
- [ ] Draft personalized outreach messages

**Deliverable:** Target list with contact info + draft messages

### Day 2 — Outreach Blitz
- [ ] Send 5 outreach emails/DMs (use validation script)
- [ ] Follow up on non-responses (phone call if number available)
- [ ] Aim for 3 conversation commitments
- [ ] Schedule calls for Day 3-4

**Deliverable:** 3+ scheduled validation calls

### Day 3 — Problem Validation Calls
- [ ] Conduct 2 owner conversations (30 min each)
- [ ] Document: pain level, quantified cost, current workarounds
- [ ] Fill validation scorecard

**Deliverable:** 2 completed discovery calls + notes

### Day 4 — Solution Validation
- [ ] Conduct remaining owner conversation(s)
- [ ] Build simple Retell AI demo (if not already done)
- [ ] Run demo for interested owners
- [ ] Gather reaction and pricing feedback

**Deliverable:** 3+ validation conversations complete + demo reactions

### Day 5 — Commitment & Decision
- [ ] Review validation scorecard
- [ ] Pursue LOI or pilot deposit from interested owners
- [ ] Make go/no-go decision:
  - **GO (5+ checkpoints passed):** Proceed to 7-day build sprint
  - **PAUSE (3-4 checkpoints):** Address gaps, extend validation
  - **PIVOT (<3 checkpoints):** Reassess opportunity

**Deliverable:** Clear decision + commitment or pivot plan

### Day 6-7 — Build Prep (If GO) or Pivot (If Not)

**If GO:**
- [ ] Finalize pilot business selection
- [ ] Set up accounts: Retell AI, Cal.com, Airtable, Twilio
- [ ] Gather business details for customization
- [ ] Schedule Day 1 of build sprint

**If PIVOT:**
- [ ] Review radar for next best opportunity
- [ ] Apply learnings to new vertical

---

## Validation Scorecard

| Checkpoint | Required | Status |
|------------|----------|--------|
| Problem validated (3+ owners confirm pain) | ✅ | ⬜ |
| Quantified pain (cost estimate from owner) | ✅ | ⬜ |
| Solution demo complete | ✅ | ⬜ |
| Positive reaction to demo | ✅ | ⬜ |
| Pricing accepted ($1,500/month feels reasonable) | ✅ | ⬜ |
| LOI or pilot deposit secured | ✅ | ⬜ |

**Minimum for GO:** 5 of 6 checkpoints passed

---

## Build Spec (Post-Validation)

**System:** Lead-to-Booked-Job Orchestrator
**Stack:** OpenClaw + Retell AI + Cal.com + Airtable/Make + Twilio
**Time:** 7 days post-validation

**Core Flow:**
```
Inbound Call → Retell AI Voice Agent → Qualification Logic → 
[Emergency → SMS dispatch | High-intent → Cal.com booking | Low-intent → Callback queue] → 
Airtable CRM → SMS Confirmation + Reminders → Post-service review request
```

**Success Metrics:**
- Answer rate: >95%
- Booking conversion: >60%
- No-show rate: <10%
- Escalation rate: <15%

---

## Quality Check (Pre-Flight)

- [x] **Evidence:** Regal.ai case studies with concrete metrics (96% faster, 41% conversion increase)
- [x] **Economics:** Baseline $11,200/week → Target $15,200/week (+$4K/week, $208K/year)
- [x] **Budget owner:** Business owner/operator, no procurement cycle
- [x] **Decision clarity:** PROTOTYPE → Validate → Then BUILD or PIVOT
- [x] **Next actions:** 3 prioritized, executable tasks for tonight
- [x] **Risk identified:** Outreach response rate + mitigation plan
- [x] **Communication:** Concise, actionable, no filler
- [x] **Business-First Gate:** Validation conversations prioritized over infrastructure building

---

## Why PROTOTYPE (Not BUILD NOW or REJECT)

**Not BUILD NOW:** Validation checkpoints are incomplete. The validation plan explicitly requires 3+ owner conversations and 1+ LOI before build. Skipping validation risks building something the market doesn't want.

**Not REJECT:** Signal strength is HIGH with concrete ROI data. Asset pack is complete. Australian market has less competition. Cobi's warehouse background creates authentic positioning.

**PROTOTYPE is correct:** Run the 5-day validation sprint to confirm problem/solution fit before committing to 7-day build.

---

**One-Line Focus:** Start Retell AI account setup and send first outreach message tonight.

**Review Date:** 2026-03-04 (after validation sprint)
