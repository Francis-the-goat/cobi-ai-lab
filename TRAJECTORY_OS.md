# TRAJECTORY_OS.md — Velocity-Based AI Leverage System

**Last updated:** 2026-02-25  
**Status:** V2 — Trajectory-focused rewrite

---

## The Problem with Static Learning

AI is compounding, not iterating. The half-life of technical knowledge is now 6-12 months. Traditional "learn then apply" fails because:

1. **What you learn today might be obsolete before you ship**
2. **The tools are improving faster than you can master them**
3. **The opportunity window closes as tools become commoditized**

**The shift:** From "learning AI" → **"using AI change as leverage"**

---

## Core Principle: Trajectory > Knowledge

### Old Model
```
Learn → Practice → Master → Apply
(6 months)   (6 months)  (ongoing)
```

### New Model
```
Sense change → Extract leverage → Ship in 7 days → Compound
(2 hours)       (1 day)           (5 days)          (repeat)
```

**Key insight:** You don't need to master tools. You need to be first to apply new capabilities to business problems.

---

## Three-Layer System

### Layer 1: Signal Detection (Daily, 30 min)

**What changed in the last 48 hours that creates new leverage?**

**Sources (priority order):**
1. **Model releases** (Claude, GPT, Gemini, Llama) — New capabilities = new products
2. **API changes** — Cheaper, faster, new modalities = new economics
3. **Infrastructure shifts** (MCP, OpenClaw, new runtimes) — New ways to build
4. **SMB adoption signals** — Who's buying, what's working
5. **Competitor moves** — What's getting commoditized, where's the edge

**Key question:** *What can I do today that was impossible/expensive last week?*

**Output:** 1-2 sentence signal log → `memory/signals/YYYY-MM-DD.md`

---

### Layer 2: Leverage Extraction (Weekly, 2-3 hours)

**For each high-signal change:**

1. **Capability mapping** — What does this unlock?
2. **Economic analysis** — What was $X, now $Y? What was impossible, now possible?
3. **SMB application** — Which business process does this transform?
4. **Window assessment** — How long until this is commoditized?
5. **Ship decision** — Build now or wait?

**Decision criteria:**
| Factor | Build Now | Park |
|--------|-----------|------|
| Capability jump | 10x+ improvement | <5x |
| SMB applicability | Clear workflow | Vague |
| Window | 3-6 months | <1 month or >1 year |
| Your readiness | Can ship in 7 days | Needs >2 weeks learning |

**Output:** Leverage brief → `ai-alpha-learning/leverage-briefs/`

---

### Layer 3: Compounding Ship (Weekly, 5-10 hours)

**For each "build now" opportunity:**

**Day 1-2: Spec + validation**
- Write the one-sentence value prop
- Identify 3 test customers
- Build minimal proof (MVP)

**Day 3-5: Refine + package**
- Iterate with real feedback
- Document the system
- Create reusable template/skill

**Day 6-7: Distribute + compound**
- Publish proof (thread, reel, case study)
- Update offer/docs
- Log learnings

**Output:** Shipped asset → `asset-foundry/` + public proof

---

## Velocity Metrics (Track Weekly)

| Metric | Target | Why |
|--------|--------|-----|
| Signals detected | 3-5/week | Stay ahead of curve |
| Leverage briefs | 1-2/week | Quality filtering |
| Assets shipped | 1/week | Compounding output |
| Days signal → ship | <7 | Speed wins |
| Window capture rate | >50% | Hitting open opportunities |

**Warning signs:**
- >14 days signal → ship = too slow, opportunity lost
- <1 asset/week = learning without shipping
- All signals = "AI news" not "business leverage" = wrong filter

---

## Anti-Patterns to Avoid

### ❌ "I need to learn more first"
**Truth:** The tools are improving faster than you can learn. Ship with today's knowledge.

### ❌ "I'll wait for the next version"
**Truth:** By then, 10 others have captured the window. Ship now, upgrade later.

### ❌ "This isn't perfect yet"
**Truth:** Perfection is procrastination. SMBs pay for results, not polish.

### ❌ "I should understand the theory"
**Truth:** You don't need to understand transformers to sell GPT-4 outcomes.

### ❌ "I'll build one big thing"
**Truth:** 10 small ships beats 1 big ship. Compounding > moonshots.

---

## Skill Stack (What Actually Matters)

**Tier 1: Use it or lose it (constant practice)**
- Prompt engineering — gets better with new models anyway
- Tool orchestration — OpenClaw, MCP, APIs
- Sales conversations — talk to SMBs weekly
- Content creation — ship proof weekly

**Tier 2: Learn as needed (just-in-time)**
- New model capabilities — when released, not before
- Technical implementation — when shipping, not in advance
- Domain knowledge — when you have a customer

**Tier 3: Ignore (will be automated)**
- Infrastructure setup — use templates, platforms
- Boilerplate code — generate it
- Research without application — it's procrastination

---

## Weekly Rhythm

### Monday Morning (30 min)
- Review weekend signals
- Update leverage briefs
- Pick this week's ship target

### Tuesday-Thursday (1-2 hours/day)
- Build the asset
- Validate with real customers
- Iterate based on feedback

### Friday (1 hour)
- Ship proof (content)
- Update systems/docs
- Log learnings
- Plan next week

### Weekend (optional)
- Deep work on hard problems
- Long-form content
- System improvements

---

## Integration with Existing Systems

| System | Role in Trajectory_OS |
|--------|----------------------|
| LEVERAGE_OS.md | The 5-system engine — use as-is |
| ai-alpha-learning/ | Now for **reverse-engineering expertise**, not curriculum |
| HEARTBEAT.md | Daily signal detection + leverage scan |
| asset-foundry/ | Where ships land |
| memory/signals/ | Raw signal log (new) |

---

## Success Definition

**You're winning when:**
- You're shipping something new every week
- Your assets are compounding (each makes the next easier)
- SMBs are paying you for outcomes
- Your content shows real builds, not theory
- You can sense a signal and ship before others

**You're losing when:**
- You're "learning" more than shipping
- Your week-to-week output looks the same
- You're explaining instead of demonstrating
- You're waiting for "readiness"

---

## Immediate Actions

1. **Create signal log structure**
   ```
   memory/signals/YYYY-MM-DD.md
   ```

2. **Define your 3 signal sources**
   - Nate B Jones (business leverage)
   - OpenClaw/Claude Code releases (tool leverage)
   - One SMB community (market leverage)

3. **Ship one thing this week**
   - Doesn't matter what
   - Just prove the system works

4. **Update HEARTBEAT.md**
   - Daily: Signal scan
   - Weekly: Leverage brief
   - Weekly: Asset ship

---

## The Real Metric

**How many days between "this AI capability exists" and "I shipped something using it"?**

Target: <7 days.  
World-class: <3 days.  
Current reality: ?

That's what we're optimizing.
