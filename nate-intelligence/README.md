# Nate B Jones Intelligence System

Process Nate B Jones videos into actionable business value for Cobi.

## What It Does

1. **Detect** → New video uploaded
2. **Ingest** → Download + transcribe
3. **Extract** → Key frameworks, strategies, insights
4. **Translate** → Map to Cobi's context (SMB agentic, AI agency)
5. **Output** → Actionable deliverables

## Pipeline

```
[New Video] → [Transcribe] → [Extract Insights] → [Translate to Cobi Context] → [Generate Outputs]
                                                                     ↓
                                                [Thread Draft] [Business Idea] [Action Item]
```

## Outputs

For each video, generate:

1. **Summary** (2-3 paras) — What he actually said
2. **Key Framework** — The mental model or strategy
3. **Cobi Translation** — How this applies to your situation
4. **Content Angle** — X thread or reel idea based on this
5. **Business Action** — Specific thing to try/build/research
6. **Quote Bank** — Tweet-worthy lines to remix

## Storage

```
nate-intelligence/
├── inbox/              # New videos detected
├── processed/          # Videos fully analyzed
│   └── YYYY-MM-DD-video-slug/
│       ├── transcript.txt
│       ├── summary.md
│       ├── framework.md
│       ├── translation.md
│       ├── content-ideas.md
│       └── action-items.md
└── insights.db         # Searchable index of all insights
```

## Example Output

**Video:** "The AI Agency Model That Actually Works"

**Summary:** Nate breaks down why most AI agencies fail — they sell labor instead of outcomes. The winners package specific business results ("10x your lead response") not hours.

**Key Framework:** Outcome-Based Packaging — Price on value created, not time spent.

**Cobi Translation:** My home services AI agent shouldn't be sold as "$1,500/month for a voice agent" — it should be "$1,500/month to capture $10K+ in leads you're currently missing." ROI-first positioning.

**Content Angle:** Thread: "I spent 2 hours researching AI agencies. Here's why 90% will fail in 12 months." (Lead with contrarian take, prove with Nate's framework)

**Business Action:** Rewrite home services offer to lead with ROI number ($200K+ annual impact) not features.

**Quote Bank:**
- "Agencies selling hours are building jobs, not businesses."
- "The buyer doesn't want AI. They want the result AI creates."

## Next Steps

1. Set up YouTube polling for Nate's channel
2. Build transcription pipeline (yt-dlp + whisper)
3. Create extraction prompt (framework, translation, actions)
4. Build output generators
5. Test on last 3 videos
