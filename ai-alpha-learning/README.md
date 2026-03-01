# AI Alpha Learning System v2 — Trajectory Focus

**Purpose:** Learn from AI experts to extract leverage, not accumulate knowledge.

**Principle:** Reverse-engineer expertise → Apply immediately → Ship proof

---

## The Shift

**v1 (Deprecated):** Curriculum-based learning, master then apply.  
**v2 (Now):** Signal-based extraction, apply while learning.

AI moves too fast for "study then build." You must build WHILE studying.

---

## Learning = Leverage Extraction

Every piece of content from experts contains:

| Component | What to Extract | Output |
|-----------|----------------|--------|
| **Timing signal** | Why now? What changed? | Signal log entry |
| **Leverage point** | What 10x improvement is possible? | Leverage brief |
| **Mental model** | How do they think about this? | Study note |
| **Implementation** | What to actually build? | Asset spec |
| **Distribution** | How to prove it? | Content angle |

**Rule:** No content consumption without immediate application.

---

## Expert Sources (Signal Priority)

### Tier 1: Business Leverage (Never Miss)
These create direct economic opportunity:

1. **Nate B Jones** — AI agency models, pricing, positioning
   - Signal type: What's selling now, how to package
   - Action: Extract offer structure → Apply to SMB vertical

### Tier 2: Capability Leverage (Watch Closely)
These unlock new technical possibilities:

2. **Andrej Karpathy** — Deep technical, first principles
   - Signal type: New capabilities, architectural patterns
   - Action: Map to SMB application → Spec new asset

3. **OpenClaw/Claude Code/LLM release notes** — Tool improvements
   - Signal type: Faster/cheaper/better ways to build
   - Action: Immediate test → Ship using new capability

### Tier 3: Market Context (Weekly Scan)
4. **Indie Hackers / Building in Public** — Business model breakdowns, operator pain
5. **Hacker News /show** — Real product launches
6. **GitHub Trending** — What engineers build

---

## Processing Pipeline (Per Piece of Content)

```
[Content] → [Extract in 30 min] → [Apply same day] → [Ship within week]
                ↓
        ┌───────┼───────┐
        ↓       ↓       ↓
    Signal   Brief   Asset
     Log     Spec    Ship
```

### Step 1: Signal Extraction (10 min)
- What changed?
- Why does it matter now?
- What was impossible last week?

**Output:** 1-2 sentences → `memory/signals/`

### Step 2: Leverage Brief (20 min)
- What 10x improvement is possible?
- Which SMB workflow does this transform?
- How long is the window open?

**Output:** Brief → `ai-alpha-learning/leverage-briefs/`

### Step 3: Immediate Application (Same Day)
- Build minimal proof using new insight
- Do NOT wait to "fully understand"
- Ship something, anything

**Output:** Proof artifact

---

## Study Note Format (If Needed)

Only create detailed notes for reusable mental models:

```markdown
# [Expert] — [Topic] — [Date]

## The Signal
What changed? Why now?

## The Leverage
What 10x improvement is possible?

## Mental Model
How to think about this:

## Immediate Application
What I'm building today:

## Proof of Learning
[Link to shipped thing]
```

---

## Anti-Patterns

❌ **Taking notes without building** — Consuming without applying  
❌ **Waiting to "master" before shipping** — Perfection is procrastination  
❌ **Collecting without prioritizing** — Everything is not equally important  
❌ **Studying old content** — >3 months = likely outdated  

---

## Integration with Trajectory_OS

| Trajectory_OS | AI Alpha Learning |
|---------------|-------------------|
| Signal Detection | Tier 1-2 sources |
| Leverage Extraction | Processing pipeline |
| Compounding Ship | Immediate application rule |

---

## Weekly Commitment

- **15 min/day:** Scan Tier 1 sources for signals
- **1 hour/week:** Deep process one high-signal piece
- **Same week:** Ship proof using what you learned

**Metric:** Content pieces → shipped proofs ratio should be 1:1

---

## Success = Shipped Proof

You've learned it when:
1. You can explain the leverage in one sentence
2. You've shipped something using it
3. You can teach it from experience, not notes

**Not:** Notes taken, videos watched, courses completed.

---

## Directory Structure

```
ai-alpha-learning/
├── leverage-briefs/        # Extracted opportunities
│   └── YYYY-MM-DD-slug.md
├── mental-models/          # Reusable thinking frameworks
│   └── model-name.md
├── study-notes/            # Deep dives (rare)
│   └── expert-topic.md
├── inbox/                  # Content to process
└── mastery-log.md          # What you shipped
```

---

## Current Priorities

1. **SMB workflow automation** — Operations-heavy businesses with clear ROI
2. **Speed-to-lead** — Response automation as first offer
3. **Local model deployment** — Cost-effective inference
4. **Content velocity** — Ship proof weekly

---

## Next Actions

1. Define your Tier 1 signal sources
2. Set up daily 15-min scan habit
3. Process one piece this week → ship proof
4. Log first leverage brief

---

*See TRAJECTORY_OS.md for full velocity system*
