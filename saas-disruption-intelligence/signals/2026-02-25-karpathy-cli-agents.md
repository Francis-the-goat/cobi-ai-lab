# Signal: Karpathy on CLIs + Agents
**Date:** 2026-02-25  
**Source:** Andrej Karpathy (Twitter)  
**Status:** Analyzed

## The Signal

Karpathy: CLIs are "super exciting" because they're legacy tech that agents can natively use.

**Key claim:** Agents combine CLIs, build dashboards, navigate repos via terminal toolkit in minutes.

**Examples given:**
- Claude built Polymarket dashboard in ~3 minutes
- GitHub CLI → agents navigate repos, issues, PRs
- Arbitrary logic/interfaces via terminal

**The punchline:** "It's 2026. Build. For. Agents."

## Analysis

### 1. Capability Unlock

**What's newly possible:**
- Agents as product interface (not just automation)
- CLI-first products become agent-native
- Rapid prototyping: "build me X" → working code in minutes
- Composability: agents combine multiple CLIs into pipelines

**Technical implication:**
Text interfaces > GUIs for agent era. APIs > dashboards. CLI tools are suddenly strategic assets.

### 2. SaaS Vulnerability

**What's threatened:**
- Dashboard-heavy SaaS (admin panels, analytics UIs)
- Products requiring human navigation (click-heavy workflows)
- Integration platforms (Zapier, etc.) — agents replace them
- Documentation systems (agents read docs directly)

**The shift:**
- From: Beautiful UI for humans
- To: Clean CLI/API for agents + natural language interface

### 3. Business Model

**Old:** Sell dashboard access per-seat
**New:** Sell agent-accessible capabilities (API calls, actions)

**Pricing implication:**
- Usage-based (per action)
- Outcome-based (per result)
- NOT per-seat (agents don't need seats)

### 4. Build/Buy/Partner: BUILD

This is core to Cobi's strategy.

**Why:**
- You already use Claude Code/OpenClaw (CLI-native)
- You're building agents, not using them as end-user
- This validates your infrastructure-first approach

### 5. Timing Window: NOW

Karpathy tweeting this = mainstream awareness in 3-6 months.

Window to build CLI-first/agent-native products: 12-18 months before everyone does it.

### 6. Execution Path

**Week 1:** Audit your current tools. Which have CLIs? Which need them?

**Month 1:** Build one agent-native product (CLI-first, agent-usable)

**Month 3:** Product that agents use to serve customers (meta-level)

**Month 6:** Platform for agent-building (infrastructure play)

## Cobi Translation

### Immediate Implications

**1. Your Home Services Agent Should Be CLI-First**

Not a dashboard. A CLI that:
- `answer-call --business=acme-hvac --incoming=+61400...`
- `schedule-appointment --customer=jane --service=repair`
- `get-metrics --business=acme-hvac --period=last-7-days`

Then agents (yours, customer's) can orchestrate it.

**2. Build Your Tools As CLIs**

The radar system, nate-intelligence — turn them into CLIs:
```bash
radar check --channel=nate
radar analyze --signal=karpathy-cli
nate process --video=latest
```

Then agents can run them. Meta.

**3. Sell CLI Access, Not Dashboards**

Pitch: "Your agent can control our system via CLI/API."

Not: "Log into our dashboard."

**4. Documentation = Markdown Exports**

Karpathy explicitly: "are your legacy docs exportable in markdown?"

Every system you build:
- README.md (human + agent readable)
- --help flags
- Structured output (JSON)

Agents consume this directly.

### Strategic Opportunity

**The Meta-Play:** Build CLI-first infrastructure for SMB agents.

**What:** Tools that SMBs need, but accessible via CLI so agents can orchestrate them.

**Examples:**
- `smb-voice` — voice agent CLI
- `smb-schedule` — scheduling CLI  
- `smb-crm` — CRM CLI
- `smb-invoice` — invoicing CLI

**Why it wins:**
- Agents become the interface (no UI to build)
- SMBs get automation (agents use tools)
- You own the infrastructure layer

**Business model:** Usage-based API calls. Per-action pricing.

## Action

**This week:**

1. Convert one existing script to CLI with `--help`, JSON output
2. Document it in markdown
3. Ask Claude to use it via natural language
4. Record the interaction (content gold)

**Next:** Build agent that uses your CLI to serve customers.

## Score

- Pain urgency: 4/5 (CLI barrier for agents)
- Economic value: 5/5 (infrastructure layer)
- Build speed: 4/5 (CLIs are fast to build)
- Window duration: 4/5 (12-18 months)
- Your advantage: 4/5 (already CLI-native with OpenClaw)

**Total: 21/25** — Strong signal. Act on this.
