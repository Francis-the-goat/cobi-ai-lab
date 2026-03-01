# Skill: Skill Opportunity Detector

## Purpose
Autonomous daily analysis of extracted patterns to identify codifiable skills/tools. Evaluates value against constraints and proposes only high-opportunity builds.

## Problem Solved
- Prevents dumping infrastructure into skill repos
- Judges buildable value before proposing work
- Maintains constraint alignment ($200, warehouse, 90-day)
- Builds only reusable, agent-valuable capabilities

## Installation
```bash
# Clone to skills directory
cd ~/.openclaw/skills
git clone https://github.com/Francis-the-goat/skill-opportunity-detector.git

# Configure environment variables
export SKILL_VAULT_PATH="$HOME/obsidian/openclaw"
export SKILL_GITHUB_REPO="your-org/skill-collection"
```

## Usage

### Daily Autonomous Run (via cron)
```bash
# 7 AM daily — after pattern extraction
0 7 * * * ~/.openclaw/skills/skill-opportunity-detector/scripts/daily-scan.sh
```

### Manual Trigger
```bash
~/.openclaw/skills/skill-opportunity-detector/scripts/analyze-patterns.sh --source=nate-2026-02-28
```

### Review Proposals
Check vault: `04-decisions/skill-proposals/`

## Configuration

File: `config.yaml`
```yaml
vault_path: ~/obsidian/openclaw
pattern_sources:
  - 03-patterns/  # Analyst pattern notes
  - 02-research/  # Raw insights
  - transcripts/  # Direct transcripts

value_criteria:
  novelty_threshold: 7        # 1-10: New vs repackaged
  actionability_threshold: 7  # 1-10: Can we build this?
  reuse_potential: 6          # 1-10: Would others use it?
  
constraint_filters:
  max_cost: 50               # $50 per skill max
  max_api_calls: 10          # API calls per operation
  requires_realtime: false   # Async-friendly only
  
auto_log: true              # Log rejected patterns too
```

## Output Format

### High-Value Proposal (Ready to Build)
File: `04-decisions/skill-proposals/[pattern-name]-proposal.md`

```markdown
# Skill Proposal: [Name]
Date: [YYYY-MM-DD]
Source: [[source-pattern-link]]

## Source Pattern
[Extracted pattern from source]

## Buildability Analysis
- [x] Codifiable: Yes — can be expressed as OpenClaw skill
- [x] Reusable: Yes — applies to multiple use cases
- [x] Constraint-fit: Yes — async, <$50, agent-valuable

## Value Assessment
| Criterion | Score | Evidence |
|-----------|-------|----------|
| Novelty | 8/10 | New approach vs existing skills |
| Actionability | 9/10 | Clear acceptance criteria |
| Reuse potential | 8/10 | 3+ use cases identified |
| Constraint fit | 9/10 | $0 cost, fully async |
| **Overall** | **8.5/10** | Build recommended |

## Proposed Skill Spec

### Name
skill-[descriptive-name]

### What It Does
[One-sentence value proposition]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Constraint Architecture
- Model: [Local/Premium/Hybrid]
- Cost per use: $[X]
- Async-friendly: Yes/No
- Dependencies: [list]

### Risk Assessment
Level: Low/Medium/High
Mitigation: [if applicable]

## Alternatives Considered
- Option A: [why rejected]
- Option B: [why rejected]

## Recommendation
**BUILD** — Meets all criteria, high leverage

Reply "build [name]" to approve, "skip [name]" to discard.
```

### Rejected Pattern (Logged for Reference)
File: `04-decisions/rejected-patterns/[pattern-name]-rejected.md`

```markdown
# Rejected Pattern: [Name]
Date: [YYYY-MM-DD]
Source: [[source-pattern-link]]

## Why Rejected
- Reason 1: [e.g., Not reusable — too specific to one workflow]
- Reason 2: [e.g., High cost, low value]

## Pattern Logged For
Future synthesis — may combine with other patterns

## Tags
#rejected #potential-revisit #infrastructure-ish
```

## How It Works

### Step 1: Scan Pattern Vault
- Reads all pattern notes from configured sources
- Identifies unanalyzed patterns (no proposal exists)

### Step 2: Evaluate Buildability
Checks 4 criteria:
1. **Codifiable** — Can this be expressed as an OpenClaw skill?
2. **Reusable** — Would this help other agents/users?
3. **Valuable** — Does it solve a real operational problem?
4. **Constraint-fit** — Fits $200 budget, warehouse shifts, async?

### Step 3: Score Against Rubric
| Score | Interpretation |
|-------|----------------|
| 9-10 | Must build — high leverage, clear value |
| 7-8 | Build if capacity — solid value, worth doing |
| 5-6 | Defer — interesting but not urgent |
| <5 | Reject — not a skill, infrastructure, or not valuable |

### Step 4: Generate Proposal or Rejection
- High scores → Full proposal with spec
- Low scores → Rejection log with reasoning

### Step 5: Queue for Review
- Proposals go to `04-decisions/skill-proposals/`
- Cobi reviews, says "build it" or "skip"

## Decision Rubric

### BUILD Immediately (Auto-build criteria)
- Overall score ≥ 9
- Constraint fit = 10
- Cost = $0
- Risk = Low

### BUILD on Approval (Standard)
- Overall score 7-8
- Constraint fit ≥ 7
- Clear acceptance criteria
- Cobi says "build it"

### SKIP (Log Only)
- Overall score < 7
- Infrastructure, not reusable skill
- Too specific to one workflow
- Violates constraints

## Integration

### With Harvester Agent
- Runs after Harvester completes source processing
- Analyzes new transcripts for skill opportunities

### With Analyst Agent
- Uses Analyst's pattern notes as primary input
- Extends Analyst's value judgment with buildability lens

### With Builder Agent
- Proposals feed Builder's queue
- Builder only builds approved proposals

## Example Workflow

```
Harvester acquires Nate video → Analyst extracts pattern → 
Skill Detector analyzes → Proposes "specification-engineering skill" → 
Cobi says "build it" → Builder creates skill → GitHub push
```

## Success Metrics

- Proposals generated: 2-5/week
- Proposal quality: >80% approval rate
- Build success: >90% of approved proposals
- Cost per scan: $0 (local analysis)
- False positives: <20% (rejected after approval)

## Files

```
skill-opportunity-detector/
├── SKILL.md                    # This file
├── config.yaml                 # User configuration
├── scripts/
│   ├── daily-scan.sh          # Cron entry point
│   ├── analyze-patterns.sh    # Main analysis script
│   └── evaluate-buildability.py  # Scoring logic
├── templates/
│   ├── proposal-template.md   # High-value output
│   └── rejection-template.md  # Low-value output
└── README.md                   # Quick start guide
```

## Requirements

- OpenClaw gateway running
- Obsidian vault configured at `SKILL_VAULT_PATH`
- Python 3.9+ for scoring logic
- Local LLM for analysis (ollama/qwen2.5:7b recommended)

## Cost

- Analysis: $0 (local models)
- Synthesis: ~$0.25/day (Kimi for complex patterns)
- **Total: <$8/month**

## License

MIT — Reuse, modify, distribute freely.

---

**Status:** Proposed — Awaiting Cobi's "build it"
