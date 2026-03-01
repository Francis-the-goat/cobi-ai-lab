# Execution Roadmap: Lead-to-Booked-Job Orchestrator
**Build Duration:** 7 days  
**Go-Live Target:** March 4, 2026  
**First Pilot:** March 5-31, 2026

---

## Pre-Build: Validation Complete (Days -5 to 0)

**Prerequisites:**
- [ ] 3+ owner conversations confirm problem
- [ ] 1+ demo generates positive reaction
- [ ] LOI or pilot deposit secured
- [ ] Target business identified for pilot

**If validation fails:**
- Pivot to different vertical (healthcare, bookkeeping)
- Reassess messaging/positioning
- Or: Build generic version for portfolio without pilot

---

## Week 1: Build Sprint

### Day 1: Foundation — Voice Agent Setup
**Goal:** Working voice agent that can handle basic calls

**Tasks:**
- [ ] Create Retell AI account
- [ ] Configure voice agent with HVAC-specific greeting
- [ ] Build knowledge base (services, FAQs, pricing ranges)
- [ ] Set up basic call flows (greeting, qualification, closing)
- [ ] Test 5 sample calls manually

**Deliverable:** Demo-ready voice agent
**Success Criteria:** Can handle simple booking inquiry end-to-end

**Evening Review:**
- What's working?
- What's clunky?
- Adjust flows based on testing

---

### Day 2: Logic Layer — Qualification Engine
**Goal:** Smart lead scoring and routing

**Tasks:**
- [ ] Build qualification logic (OpenClaw skill or Retell functions)
- [ ] Define scoring matrix (emergency, service type, location)
- [ ] Create routing rules (book now, callback, decline)
- [ ] Set up escalation triggers (complex requests, angry customers)
- [ ] Test edge cases (price shoppers, wrong area, emergencies)

**Deliverable:** Qualification engine with test suite
**Success Criteria:** Correctly scores and routes 90% of test scenarios

**Evening Review:**
- Review test transcripts
- Tune scoring thresholds
- Document fallback behaviors

---

### Day 3: Integration — Booking & CRM
**Goal:** Seamless booking and data capture

**Tasks:**
- [ ] Set up Cal.com (or similar) for real-time booking
- [ ] Connect calendar to tech availability
- [ ] Create Airtable base (Leads, Appointments, Customers)
- [ ] Build automation: New booking → CRM entry
- [ ] Configure SMS confirmations via Twilio
- [ ] Test complete flow: Call → Qualification → Booking → Confirmation

**Deliverable:** Integrated booking system
**Success Criteria:** End-to-end booking in <3 minutes

**Evening Review:**
- Check data flow integrity
- Verify SMS delivery
- Document any integration quirks

---

### Day 4: Polish — Reminders & Notifications
**Goal:** Complete communication loop

**Tasks:**
- [ ] Build reminder system (24h + 2h before appointment)
- [ ] Create "tech en route" notification
- [ ] Set up owner dashboard (daily metrics digest)
- [ ] Configure post-service review request
- [ ] Build no-show handling flow
- [ ] Add rescheduling capability

**Deliverable:** Full notification system
**Success Criteria:** All touchpoints trigger correctly

**Evening Review:**
- Test all notification timing
- Review copy/voice tone
- Prepare for pilot testing

---

### Day 5: Pilot Prep — Business Configuration
**Goal:** System ready for real business

**Tasks:**
- [ ] Gather pilot business details (services, pricing, hours)
- [ ] Customize voice agent for pilot business name/brand
- [ ] Configure business-specific knowledge base
- [ ] Set up owner notification preferences
- [ ] Create owner training materials (5-min video + doc)
- [ ] Test with business owner (live demo)

**Deliverable:** Pilot-ready system
**Success Criteria:** Owner approves voice/branding, understands dashboard

**Evening Review:**
- Get owner sign-off
- Schedule go-live
- Prepare monitoring plan

---

### Day 6: Testing & Hardening
**Goal:** Bulletproof system

**Tasks:**
- [ ] Load testing (5 simultaneous calls)
- [ ] Edge case testing (complex requests, system failures)
- [ ] Failover testing (what happens if Retell is down?)
- [ ] Backup notification paths (if SMS fails)
- [ ] Documentation complete (system architecture, runbook)
- [ ] Create troubleshooting guide for owner

**Deliverable:** Production-hardened system
**Success Criteria:** No critical failures in testing

**Evening Review:**
- Fix any issues found
- Final system check
- Prepare go-live checklist

---

### Day 7: Go-Live & Monitoring
**Goal:** Live pilot with real calls

**Tasks:**
- [ ] Soft launch (forward 20% of calls to AI)
- [ ] Real-time monitoring (Cobi watches every call)
- [ ] Immediate fixes for any issues
- [ ] Daily owner check-in
- [ ] Document learnings, iterate
- [ ] Prepare for full rollout

**Deliverable:** Live pilot with metrics
**Success Criteria:** AI handles calls without major issues

**Evening Review:**
- First-day metrics
- Owner feedback
- Plan for Day 8-30

---

## Days 8-30: Pilot Optimization

### Week 2: Observation
- [ ] Monitor 100% of calls (listen to recordings)
- [ ] Daily 15-min owner sync
- [ ] Track metrics: answer rate, booking rate, escalations
- [ ] Document edge cases for improvement
- [ ] Fix issues within 24 hours

### Week 3: Optimization
- [ ] Tune qualification thresholds based on data
- [ ] Refine voice agent responses
- [ ] Optimize SMS timing/copy
- [ ] Add any missing FAQ responses
- [ ] Prepare case study documentation

### Week 4: Validation
- [ ] Calculate ROI for owner (bookings captured, time saved)
- [ ] Gather testimonial
- [ ] Document before/after metrics
- [ ] Decide: Continue, iterate, or pivot
- [ ] Plan next pilot or full rollout

---

## Success Metrics (30-Day Pilot)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Answer rate | >95% | AI-answered / total calls |
| Booking conversion | >50% | Booked / qualified leads |
| Owner satisfaction | 8+/10 | Post-pilot survey |
| Escalation rate | <20% | Human transfer / total |
| Technical uptime | >99% | System availability |

**Case Study Threshold:**
- Captured 5+ jobs that would have been missed
- Owner willing to provide testimonial
- ROI positive within 30 days

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| AI voice quality poor | Low | High | Use premium voice, extensive testing |
| Integration failures | Medium | Medium | Fallback to manual booking, SMS alerts |
| Owner doesn't adopt | Medium | High | Daily check-ins, simple dashboard |
| Too many escalations | Medium | Medium | Tune thresholds, improve training |
| Competitor announcement | Low | Low | Focus on local service, speed to market |

---

## Daily Standup Questions (During Build)

1. What did I complete yesterday?
2. What am I building today?
3. What's blocking me?
4. What's the risk of not hitting Day 7 target?

---

## Go-Live Checklist

- [ ] Voice agent tested with 50+ scenarios
- [ ] All integrations verified (calendar, SMS, CRM)
- [ ] Owner trained and comfortable
- [ ] Monitoring dashboard active
- [ ] Escalation path documented
- [ ] Rollback plan ready (can forward calls back instantly)
- [ ] Cobi available for real-time support (first 48 hours)

---

## Post-Pilot Decision Matrix

| Outcome | Action |
|---------|--------|
**Success** (metrics hit, owner happy) | Convert to paid, document case study, start next pilot |
**Partial** (some issues, owner sees value) | Iterate for 2 more weeks, fix issues |
**Failure** (owner unsatisfied, metrics poor) | Analyze root cause, decide: fix or pivot vertical |

---

## Resources & Tools

**Accounts Needed:**
- Retell AI (voice agent)
- Cal.com (scheduling)
- Airtable (CRM)
- Twilio (SMS)
- OpenClaw (orchestration)

**Budget:**
- Retell AI: ~$100-200/month (usage-based)
- Cal.com: $0-12/month
- Airtable: $0-20/month
- Twilio: ~$20-50/month (usage-based)
- **Total:** ~$150-300/month per business

**Time Investment:**
- Build: 7 days full-time
- Pilot: 30 days ~2 hours/day monitoring
- Total: ~67 hours to validated case study
