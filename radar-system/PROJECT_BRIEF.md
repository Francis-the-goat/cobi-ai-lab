# Radar System Implementation Brief

## Overview
Build a production-quality monitoring system that continuously monitors channels (GitHub, HackerNews, YouTube, X/Twitter) for high-signal opportunities related to AI/agentic systems and SMB automation.

## Architecture
```
radar-system/
├── config/
│   ├── channels.yaml          # Channel configurations
│   ├── scoring.yaml           # Foundry Rubric weights
│   └── filters.yaml           # Keywords, exclusions
├── src/
│   ├── monitors/
│   │   ├── base.ts            # Abstract monitor class
│   │   ├── github.ts          # GitHub trending/search
│   │   ├── hackernews.ts      # HN Show + AI posts
│   │   ├── youtube.ts         # Channel upload monitor
│   │   └── twitter.ts         # X/Twitter via RSS/API
│   ├── scorer/
│   │   ├── rubric.ts          # Scoring engine
│   │   └── weights.ts         # Foundry Rubric implementation
│   ├── router/
│   │   └── queue-router.ts    # Route signals to queues
│   ├── storage/
│   │   ├── queue.ts           # Queue management
│   │   └── cache.ts           # Deduplication cache
│   ├── types/
│   │   └── index.ts           # TypeScript interfaces
│   └── utils/
│       ├── logger.ts          # Structured logging
│       └── config.ts          # Config loader
├── queues/                    # Signal storage (JSONL)
├── logs/                      # Structured logs
├── tests/
│   ├── monitors.test.ts
│   ├── scorer.test.ts
│   └── integration.test.ts
├── scripts/
│   ├── run-radar.ts           # Main entry point
│   └── generate-handoff.ts    # Daily summary
├── package.json
├── tsconfig.json
└── README.md
```

## Core Data Models

```typescript
interface Signal {
  id: string;
  source: 'github' | 'hackernews' | 'youtube' | 'twitter';
  timestamp: string;
  raw: unknown;
  title?: string;
  url?: string;
  author?: string;
  description?: string;
  tags?: string[];
  engagement?: {
    stars?: number;
    comments?: number;
    views?: number;
  };
}

interface ScoredSignal extends Signal {
  scores: {
    pain: number;
    roi: number;
    autoFit: number;
    defensibility: number;
    distribution: number;
    speed: number;
  };
  totalScore: number;
  action: 'alert' | 'asset' | 'content' | 'research' | 'log';
  priority: 'high' | 'medium' | 'low';
  reasoning: string;
}

interface QueueEntry {
  signal: ScoredSignal;
  queuedAt: string;
  status: 'pending' | 'processing' | 'done';
}
```

## Foundry Rubric

```typescript
const RUBRIC = {
  pain: { weight: 8, description: 'Problem acuity' },
  roi: { weight: 8, description: 'Quantifiable value' },
  autoFit: { weight: 8, description: 'Agent solvability' },
  distribution: { weight: 7, description: 'Can Cobi reach buyers?' },
  defensibility: { weight: 6, description: 'Hard to replicate?' },
  speed: { weight: 8, description: 'Buildable in 7 days?' }
};

const THRESHOLDS = {
  alert: 40,
  asset: 35,
  content: 30,
  research: 25,
  log: 0
};
```

## Quality Requirements

1. TypeScript throughout - Strict mode, no any types
2. Error handling - All async operations wrapped, graceful degradation
3. Testing - Unit tests for scorer/router, integration tests for monitors
4. Observability - Structured logging, metrics, health checks
5. Config-driven - No hardcoded values, everything in config/
6. Idempotent - Safe to run multiple times, deduplication built-in
7. Rate limiting - Respect API limits, backoff strategies

## Implementation Order

1. Project setup (package.json, tsconfig, folder structure)
2. Type definitions
3. Config loader
4. Logger utility
5. Cache/storage layer
6. Queue management
7. Base monitor class
8. GitHub monitor (reference implementation)
9. Scoring engine
10. Router/queue logic
11. HN monitor
12. YouTube monitor
13. Twitter monitor
14. CLI scripts
15. Tests
16. Documentation

## Monitor Specifications

### GitHub Monitor
- Search: TypeScript repos created in last 24h
- Keywords: agent, ai, llm, automation, workflow, bot
- Filter: >10 stars, has description
- API: GitHub REST API with token auth

### HackerNews Monitor
- Sources: /show, AI-tagged posts
- Filter: >10 points (show), >20 points (AI)
- API: algolia.com/api/v1/search

### YouTube Monitor
- Channels: configurable list
- Check: uploads in last 24h
- Use yt-dlp or YouTube Data API

### Twitter/X Monitor
- Method: RSS feeds
- Accounts: configurable list
- Filter: engagement threshold

## CLI Commands

```bash
npx tsx scripts/run-radar.ts           # Run all monitors
npx tsx scripts/run-radar.ts --monitor=github  # Run specific monitor
npx tsx scripts/generate-handoff.ts    # Generate daily summary
npx tsx scripts/status.ts              # Check status
npx tsx scripts/process-queue.ts --queue=urgent  # Process queues
```

## Notes

- Use Node + tsx (not Deno)
- Prefer fetch() over axios
- Use zod for runtime validation
- Use pino for structured logging
- Store state in JSONL format
- Design for cron: exit codes, idempotency
