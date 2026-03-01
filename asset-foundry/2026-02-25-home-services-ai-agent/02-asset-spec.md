# Asset Spec: Lead-to-Booked-Job Orchestrator
**Target Vertical:** Home Services (HVAC initial)  
**Build Time:** 7 days  
**Tech Stack:** OpenClaw + Retell AI + Cal.com + Airtable/Make

---

## System Architecture

```
[Inbound Call]
    ↓
[Retell AI Voice Agent] ← Knowledge base (services, pricing, FAQs)
    ↓
[Qualification Logic]
    ├─→ Emergency → SMS dispatch to on-call tech
    ├─→ High intent → Check availability → Book via Cal.com
    ├─→ Low intent → Capture lead → Queue for callback
    └─→ Wrong fit → Polite decline + referral
    ↓
[CRM Update] (Airtable/Notion)
    ↓
[Confirmation Flow]
    ├─→ SMS confirmation with prep checklist
    ├─→ Calendar invite (tech + customer)
    └─→ Reminder 24h before + 2h before
    ↓
[Post-Service]
    └─→ Review request (if 5★ candidate)
```

---

## Component Breakdown

### 1. Voice Agent (Retell AI)
**Purpose:** Handle inbound calls 24/7  
**Config:**
- Voice: Natural, professional (not robotic)
- Greeting: "Thanks for calling [Company]. I'm [Name], the scheduling assistant."
- Languages: English (AU), option for other languages
- Transfer: "Let me get [Owner] on the line" with SMS alert

**Capabilities:**
- Service qualification (HVAC: repair, maintenance, install, emergency)
- Location validation (service area check)
- Availability checking (real-time calendar)
- Appointment booking (confirmation number)
- FAQ handling (pricing estimates, warranties, hours)

**Fallbacks:**
- Complex question → "Let me have [Owner] call you back within 15 minutes"
- Angry customer → Immediate human escalation + SMS alert
- Technical issue → "I'm having trouble hearing you" + retry

### 2. Qualification Engine (OpenClaw Skill)
**Purpose:** Score and route leads  
**Logic:**

```
SCORE_MATRIX = {
  "emergency": +50,      # No heat in winter, AC out in summer
  "installation": +30,   # New system = high value
  "maintenance": +10,    # Recurring, lower urgency
  "price_shopper": -20,  # "Just want a quote"
  "out_of_area": -100,   # Automatic decline
}

THRESHOLDS = {
  "book_now": 40,
  "callback_queue": 10,
  "decline": 0
}
```

### 3. Scheduling Integration (Cal.com)
**Purpose:** Real-time booking without double-booking  
**Config:**
- Sync with tech calendars (Google/Outlook)
- Buffer times between jobs
- Service-type duration mapping (repair=2h, install=6h, maintenance=1h)
- Location-based routing (closest tech)
- Emergency override (book outside normal hours)

### 4. CRM / Job Tracking (Airtable)
**Purpose:** Central source of truth  
**Tables:**
- **Leads:** Source, qualification score, status, notes
- **Appointments:** Date/time, tech, service type, customer
- **Customers:** History, equipment, warranty info
- **No-Shows:** Tracking, rescheduling, follow-up

**Automations:**
- New booking → SMS confirmation
- 24h before → Reminder SMS
- 2h before → "We're on our way" SMS
- Job complete → Review request (next day)
- No-show → Rescheduling flow

### 5. Notification System (SMS via Twilio)
**Purpose:** Keep everyone informed  
**Flows:**

**Customer:**
- Booking confirmation + prep checklist
- Reminder 24h + 2h
- Tech en route
- Post-service thank you + review link

**Business Owner:**
- New lead summary (3x/day digest)
- Emergency call alert (immediate)
- Daily booking summary
- Weekly metrics (leads, bookings, conversions)

**Techs:**
- New assignment notification
- Customer details + job notes
- Location/directions link

---

## Data Model

### Lead Object
```json
{
  "lead_id": "uuid",
  "source": "phone",
  "timestamp": "2026-02-25T09:30:00Z",
  "customer": {
    "name": "Jane Smith",
    "phone": "+614XX XXX XXX",
    "address": "123 Main St, Gold Coast",
    "suburb": "Burleigh Heads"
  },
  "qualification": {
    "service_type": "hvac_repair",
    "urgency": "high",  // emergency, urgent, routine
    "budget_indicated": true,
    "score": 65
  },
  "call_transcript": "...",
  "status": "booked",  // new, qualified, booked, callback, declined
  "appointment_id": "uuid"
}
```

### Appointment Object
```json
{
  "appointment_id": "uuid",
  "lead_id": "uuid",
  "datetime": "2026-02-26T14:00:00Z",
  "duration_minutes": 120,
  "tech_id": "tech_001",
  "service_type": "hvac_repair",
  "status": "confirmed",  // confirmed, completed, no_show, cancelled
  "customer_notified": true,
  "reminder_sent": true
}
```

---

## Integration Points

| System | Integration | Data Flow |
|--------|-------------|-----------|
| Retell AI | Webhook | Call start/end, transcript, booking request |
| Cal.com | API | Availability check, booking creation, cancellation |
| Airtable | API | Lead creation, status updates, appointment logging |
| Twilio | API | SMS send/receive |
| Google Calendar | API | Tech availability sync |

---

## Security & Compliance

- **Data:** Customer info encrypted at rest
- **Retention:** Call recordings 30 days, transcripts 2 years
- **Opt-out:** SMS unsubscribe handled automatically
- **Privacy:** No data shared with third parties beyond operational need

---

## Success Metrics (System Health)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Answer rate | >95% | Calls answered / total calls |
| Booking conversion | >60% | Booked / qualified leads |
| No-show rate | <10% | No-shows / total bookings |
| Escalation rate | <15% | Human transfer / total calls |
| Customer satisfaction | >4.5★ | Post-service rating |

---

## Phase 1 MVP (Days 1-3)

**Core Flow:**
- [ ] Retell AI voice agent configured
- [ ] Basic qualification (service type, location, urgency)
- [ ] Cal.com booking integration
- [ ] SMS confirmation
- [ ] Airtable CRM logging

**Test Scenarios:**
1. Emergency HVAC call → Tech dispatch
2. Routine maintenance → Book appointment
3. Out of area → Polite decline
4. Price shopper → Capture info, callback queue

---

## Phase 2 Polish (Days 4-7)

**Enhancements:**
- [ ] Reminder system (24h + 2h)
- [ ] Post-service review request
- [ ] Owner dashboard (daily metrics)
- [ ] No-show handling
- [ ] Rescheduling flow

**Test Scenarios:**
1. Complete customer journey simulation
2. Edge cases (angry customer, complex request)
3. Load test (5 simultaneous calls)
4. Owner training session

---

## Build Checklist

### Day 1: Foundation
- [ ] Set up Retell AI account + voice agent
- [ ] Create knowledge base (HVAC FAQ, services, pricing guide)
- [ ] Configure greeting and basic flows
- [ ] Test single call flow

### Day 2: Logic Layer
- [ ] Build qualification engine (OpenClaw skill)
- [ ] Define scoring matrix
-