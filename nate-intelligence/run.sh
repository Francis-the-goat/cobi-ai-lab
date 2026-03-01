#!/usr/bin/env bash
# Master script for Nate B Jones Intelligence System

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

COMMAND="${1:-help}"

count_lines() {
  local file="$1"
  if [ -f "$file" ]; then
    wc -l < "$file" | tr -d ' '
  else
    echo 0
  fi
}

count_dirs() {
  local dir="$1"
  if [ -d "$dir" ]; then
    find "$dir" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '
  else
    echo 0
  fi
}

case "$COMMAND" in
    check)
        echo "=== Checking for new videos ==="
        "$SCRIPT_DIR/check-for-videos.sh"
        ;;
        
    process)
        echo "=== Processing next video ==="
        "$SCRIPT_DIR/process-video.sh" --inbox
        ;;
        
    process-specific)
        VIDEO_ID="${2:-}"
        if [ -z "$VIDEO_ID" ]; then
            echo "Usage: $0 process-specific <video_id>"
            exit 1
        fi
        "$SCRIPT_DIR/process-video.sh" "$VIDEO_ID"
        ;;
        
    status)
        echo "=== Nate Intelligence System Status ==="
        echo ""
        PENDING="$(count_lines "$INBOX_DIR/pending.txt")"
        PROCESSED="$(count_dirs "$PROCESSED_DIR")"
        echo "Pending videos: $PENDING"
        echo "Processed videos: $PROCESSED"
        echo ""
        if [ "$PROCESSED" -gt 0 ]; then
            echo "Recent processed:"
            find "$PROCESSED_DIR" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | \
              while IFS= read -r dir; do basename "$dir"; done | sort -r | head -5 | sed 's/^/  - /'
        fi
        ;;
        
    list-pending)
        echo "=== Pending Videos ==="
        if [ -s "$INBOX_DIR/pending.txt" ]; then
            cat "$INBOX_DIR/pending.txt" | while IFS='|' read -r id title date url duration; do
                echo "  [$id] $title"
            done
        else
            echo "  No pending videos"
        fi
        ;;
        
    analyze)
        # Interactive analysis mode
        echo "=== Interactive Analysis ==="

        VIDEOS=()
        while IFS= read -r video; do
            [ -n "$video" ] && VIDEOS+=("$video")
        done < <(find "$PROCESSED_DIR" -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null | while IFS= read -r dir; do basename "$dir"; done | sort -r)
        if [ ${#VIDEOS[@]} -eq 0 ]; then
            echo "No processed videos found. Run 'process' first."
            exit 1
        fi
        
        echo "Select a processed video to analyze:"
        for i in "${!VIDEOS[@]}"; do
            echo "  $((i+1)). ${VIDEOS[$i]}"
        done
        
        echo ""
        echo "Usage: $0 analyze <number>"
        echo "Then: cat $PROCESSED_DIR/<video>/analyze-prompt.txt | [your LLM]"
        ;;
        
    full)
        echo "=== Full Pipeline ==="
        "$SCRIPT_DIR/check-for-videos.sh"
        echo ""
        while [ -s "$INBOX_DIR/pending.txt" ]; do
            "$SCRIPT_DIR/process-video.sh" --inbox
            echo ""
        done
        echo "=== All caught up ==="
        ;;
        
    demo)
        echo "=== Creating Demo Example ==="
        DEMO_DIR="$PROCESSED_DIR/2026-02-25-demo-example"
        mkdir -p "$DEMO_DIR"
        
        cat > "$DEMO_DIR/meta.json" << 'DEMO'
{
  "id": "demo123",
  "title": "How to Build an AI Agency That Actually Makes Money",
  "upload_date": "2026-02-20",
  "url": "https://youtube.com/watch?v=demo123",
  "duration": "18:42",
  "processed_at": "2026-02-25T10:00:00Z"
}
DEMO

        cat > "$DEMO_DIR/summary.md" << 'DEMO'
# Summary: How to Build an AI Agency That Actually Makes Money

Nate breaks down why most AI agencies fail within 6 months. The core mistake: selling AI implementation (labor) instead of business outcomes (results). 

He presents a framework called "Outcome-Based Packaging" — where you define the specific business result you deliver, guarantee it or have skin in the game, and price based on value created rather than hours worked. 

The winners in AI services aren't the best technologists — they're the best at identifying expensive business problems and packaging AI as the solution with clear ROI.
DEMO

        cat > "$DEMO_DIR/translation.md" << 'DEMO'
# Cobi Translation

## What This Means For You

**Current approach:** "I build AI voice agents for home services businesses"
**Better approach:** "I capture $10K+ in leads you're currently missing every month"

Nate's framework directly applies to your home services AI agent:

### Reframe Your Offer

❌ "AI voice agent for $1,500/month"
✅ "Lead recovery system — we capture the 30% of calls you miss and convert them to booked jobs. Average client adds $15K/month in captured revenue."

### Why This Works

1. **You're not selling AI** — you're selling revenue recovery
2. **Price on value** — $1,500 is cheap if they capture $15K
3. **Clear ROI** — they can measure exactly what you delivered
4. **Differentiation** — every other agency is selling "AI solutions"

### Your Specific Action

Rewrite your landing page/one-pager to lead with:
- The problem (missed calls = lost revenue)
- The number (30% missed, $X average job value)
- The outcome (capture and convert those leads)
- The ROI (typically 10x return in first month)

Then put the AI part in the "how it works" section.
DEMO

        cat > "$DEMO_DIR/content-ideas.md" << 'DEMO'
# Content Ideas

## X Thread: "I talked to 20 AI agency owners. 18 are building themselves a job."

**Hook:**
I spent 2 weeks talking to AI agency owners.

18 of them are building themselves a $10K/month job.

Only 2 are building a real business.

Here's the difference (and why most will fail):

**Body:**

1/ The "job" owners sell hours.

"$150/hour for AI implementation"

They trade time for money. No leverage. No scale. Just a high-paid contractor.

2/ The business owners sell outcomes.

"$5K/month to add $50K to your bottom line"

They capture value, not time. They're aligned with client success.

3/ The math is brutal:

- 40 hours × $150 = $6K/month (maxed out)
- 1 client × $5K = $5K/month (10 hours work, 4 clients = $20K)

4/ But here's what nobody tells you:

Selling outcomes requires confidence.

You have to guarantee (or strongly imply) results.

That means you actually need to know what works.

5/ The shortcut:

Don't start as an AI agency.

Start as an X expert who uses AI.

- Lead gen expert (who uses AI)
- Customer support expert (who uses AI)
- Content ops expert (who uses AI)

6/ Deep expertise + AI leverage = unbeatable.

Shallow AI skills + generalist positioning = commodity.

The market is flooding with the second type.

Be the first.

**CTA:**
I'm building an AI agency for home services (HVAC/plumbing). 

Focusing on one outcome: capturing missed calls.

If you own a service business, DM me. I'll show you exactly how many leads you're losing.

---

## Reel Concept: "Stop Selling AI"

**Visual:** Split screen or quick cuts

**Hook (0-3s):** Text overlay: "Your AI agency is failing and you don't know why"

**Script:**
"Stop selling AI.

[silent pause]

Sell this instead."

[Show: Revenue chart going up]

"Nobody wants AI.

They want THIS."

[Show: Money/leads/customers]

"AI is just how you get there."

**CTA:** "Follow for how I'm building an AI agency the right way"
DEMO

        cat > "$DEMO_DIR/action-items.md" << 'DEMO'
# Action Items

## This Week

### 1. Rewrite Home Services Offer (Priority: HIGH)

**Current:** "AI voice agents for home services businesses - $1,500/month"

**New:** "Lead Recovery System for HVAC/Plumbing Companies
- Capture the 30% of calls you currently miss
- Convert inquiries to booked appointments
- Typical result: $10-20K additional monthly revenue
- Investment: $1,500/month (guaranteed ROI or money back)"

**Deliverable:** New one-pager with ROI calculator

---

### 2. Create ROI Calculator (Priority: HIGH)

Simple spreadsheet/web form:
- Average monthly calls: [input]
- Current answer rate: [input]  
- Average job value: [input]
- Close rate on contacted leads: [input]

Output:
- Missed calls per month
- Revenue currently lost
- Revenue captured with system
- ROI multiple

**Deliverable:** Working calculator to share with prospects

---

### 3. Draft X Thread (Priority: MEDIUM)

Use the "18 of 20 are building a job" thread from content-ideas.md.

Post this week while the insight is fresh.

**Deliverable:** Published thread with your specific angle

---

### 4. Update Pitch Deck/Website (Priority: MEDIUM)

Reorder content to lead with outcome, not technology:

1. Headline: "Never Miss a Lead Again"
2. Subhead: "AI-powered call answering that books appointments while you work"
3. Proof: Case study or ROI calc
4. How it works: [AI explanation here]

**Deliverable:** Updated landing page copy

---

## Success Metrics

- [ ] 3 prospect conversations using new framing
- [ ] 1 positive reaction ("that makes sense" or better)
- [ ] X thread gets 10+ engagements
- [ ] Landing page updated
DEMO

        cat > "$DEMO_DIR/quote-bank.md" << 'DEMO'
# Quote Bank

## Direct from Video

> "Agencies selling hours are building jobs, not businesses."

> "The buyer doesn't want AI. They want the result AI creates."

> "Deep expertise + AI leverage = unbeatable. Shallow AI skills + generalist positioning = commodity."

> "Price on value created, not time spent."

> "Start as an X expert who uses AI, not an AI expert who does X."

## Remixes for Cobi's Voice

> "Your competitors are answering calls at 11 PM. Are you?"

> "Every missed call is a $800 job that went to your competitor."

> "AI isn't the product. Captured revenue is the product."

> "I don't sell voice agents. I sell lead recovery systems."

> "The home service businesses winning in 2026 answer every call. The rest are leaking money."
DEMO

        echo "Demo created in: $DEMO_DIR"
        echo ""
        ls -la "$DEMO_DIR/"
        ;;
        
    help|*)
        echo "Nate B Jones Intelligence System"
        echo ""
        echo "Commands:"
        echo "  check              - Check for new videos"
        echo "  process            - Process next pending video"
        echo "  process-specific <id> - Process specific video ID"
        echo "  full               - Check + process all pending"
        echo "  status             - Show system status"
        echo "  list-pending       - List videos waiting to be processed"
        echo "  analyze            - Show how to analyze processed videos"
        echo "  demo               - Create example output"
        echo ""
        echo "Workflow:"
        echo "  1. $0 check              (find new videos)"
        echo "  2. $0 process            (download + transcribe)"
        echo "  3. cat processed/.../analyze-prompt.txt | claude"
        echo "  4. Fill in summary.md, translation.md, content-ideas.md"
        ;;
esac
