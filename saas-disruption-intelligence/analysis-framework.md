# Signal Analysis Framework

When you detect a new signal (video, thread, release, tool), run through this framework.

---

## Step 1: Capture (2 minutes)

**Record:**
- Source (who, where, when)
- The core claim/announcement
- Links to full content
- Your initial reaction

**Output:** Raw signal entry in `signals/`

---

## Step 2: The 6 Questions (10 minutes)

### 1. What capability unlocked?

What can now be done that couldn't before?
- New model capability?
- New tooling available?
- Cost reduction enabling new use case?
- Reliability improvement?

**Example:**  
"GPT-4 Turbo's 128k context enables processing entire customer conversation histories"

---

### 2. What SaaS is now vulnerable?

Which existing software category is threatened?
- What workflow does it replace?
- Why is agent version 10x better?
- Who pays for this today?

**Example:**  
"CRM data entry tools (Salesforce without automation). Agent can listen to calls and auto-update records."

---

### 3. What's the business model?

How does the agent version make money?
- Who pays?
- What do they pay for?
- Outcome-based or subscription?
- What's the ROI story?

**Example:**  
"Outcome-based: $X per updated record. Labor savings vs manual entry."

---

### 4. Build, Buy, or Ignore?

Should you:
- **Build:** Core to your strategy, you can win here
- **Use:** Someone else's platform, focus higher up
- **Partner:** Complementary, combine forces
- **Ignore:** Not your market, too crowded, too early

**Decision criteria:**
- Do you have unique insight?
- Can you execute in 30 days?
- Is the window >12 months?
- Do you want to own this?

---

### 5. What's the timing window?

- **Now:** Clear opportunity, tools ready
- **6 months:** Emerging, needs watching
- **12+ months:** Early, build foundations
- **Commoditizing:** Too late for new entrants

**Key questions:**
- How long until this is table stakes?
- What's the first-mover advantage?
- What's the sustainable moat?

---

### 6. What's the execution path?

If you were to build this:

**Week 1:** What's the MVP?  
**Month 1:** What proves demand?  
**Month 3:** What proves business model?  
**Month 6:** What's the sustainable advantage?

**Resource requirements:**
- Time investment?
- Technical complexity?
- Capital needed?
- Dependencies?

---

## Step 3: Score It (2 minutes)

Rate 1-5 on:

| Factor | Score | Notes |
|--------|-------|-------|
| Pain urgency | | How badly do people need this? |
| Economic value | | How much money is at stake? |
| Build speed | | Can ship in 7-30 days? |
| Window duration | | 12+ months of opportunity? |
| Your advantage | | Why you vs competitors? |
| **Total** | **/30** | |

**Scoring:**
- 25-30: Immediate action — create leverage brief
- 20-24: Strong — queue for this month
- 15-19: Interesting — monitor, revisit quarterly
- <15: Ignore

---

## Step 4: Output (5 minutes)

**Create:** `analysis/YYYY-MM-DD-signal-slug.md`

**Template:**
```markdown
# Analysis: [Signal Title]
**Date:** [Date]  
**Source:** [Who/Where]  
**Score:** [X/30]

## The Signal
[What happened]

## Capability Unlock
[What's newly possible]

## SaaS Vulnerability
[What's threatened]

## Business Model
[How it makes money]

## Decision: [Build/Buy/Partner/Ignore]
[Why]

## Timing Window
[Now/6mo/12mo/Commoditizing]

## Execution Path
[Week 1, Month 1, Month 3, Month 6]

## For Cobi Specifically
[How this applies to home services focus]

## Action
[What to do, if anything]
```

---

## Step 5: Route It (1 minute)

Based on score and decision:

**Score 25-30 + Build:**
- Create `opportunities/YYYY-MM-DD-slug.md`
- Alert Cobi immediately
- Start 7-day validation

**Score 20-24:**
- Add to action queue
- Schedule for deeper dive

**Score 15-19:**
- Log in signals/
- Set reminder to revisit in 30 days

**Ignore:**
- Just log it
- Move on

---

## Example Analysis

**Signal:** Nate B Jones video on "Outcome-Based Pricing for AI Agencies"

**The Signal:**  
Nate argues that AI agencies selling "AI implementation" are building jobs, not businesses. Winners sell outcomes ("$50K more revenue") not hours.

**Capability Unlock:**  
Not technical — business model insight. Agents enable outcome-based pricing because they deliver results, not just tools.

**SaaS Vulnerability:**  
Traditional agencies charging hourly. Also per-seat SaaS that doesn't own outcomes.

**Business Model:**  
Price on % of value created or per-outcome. Higher margins, better alignment, stickier.

**Decision: BUILD (for Cobi)**  
This is exactly what he needs for home services. Immediate application.

**Timing Window: NOW**  
Category forming. Early adopters will pay premium. Window is 12-18 months before commoditization.

**Execution Path:**
- Week 1: Rewrite offer to outcome-based framing
- Month 1: 3 validation conversations with new framing
- Month 3: First pilot client on outcome pricing
- Month 6: Case study proving ROI

**Score:** 28/30
- Pain: 5 (agencies failing, need better model)
- Value: 5 (2-10x pricing possible)
- Speed: 5 (can implement immediately)
- Window: 5 (now is the time)
- Advantage: 4 (deep focus on home services)
- **Total: 28**

**For Cobi:**  
Immediate action: Reframe home services offer from "AI voice agent $1,500/month" to "lead recovery system capturing $15K+/month" 

**Action:**  
Create new one-pager with outcome framing. Test in next 3 conversations.

---

## Speed Matters

**Target time:** 20 minutes from signal to action decision  
**Quality threshold:** Good enough to act on, not perfect  
**Output:** Clear next step or clear ignore

Don't overthink. The goal is to extract insight and decide fast.
