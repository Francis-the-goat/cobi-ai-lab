#!/usr/bin/env node
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { GitHubMonitor } from '../src/monitors/github.js';
import { HackerNewsMonitor } from '../src/monitors/hackernews.js';
import { TwitterMonitor } from '../src/monitors/twitter.js';
import { YouTubeMonitor } from '../src/monitors/youtube.js';
import { QueueRouter } from '../src/router/queue-router.js';
import { SignalScorer } from '../src/scorer/rubric.js';
import { DeduplicationCache } from '../src/storage/cache.js';
import { QueueManager } from '../src/storage/queue.js';
import type { Monitor, MonitorResult, Signal, SignalSource } from '../src/types/index.js';
import { loadConfig } from '../src/utils/config.js';
import { logger } from '../src/utils/logger.js';

function parseMonitorArg(argv: readonly string[]): SignalSource | undefined {
  const arg = argv.find((entry) => entry.startsWith('--monitor='));
  if (!arg) return undefined;
  const value = arg.split('=')[1];
  if (value === 'github' || value === 'hackernews' || value === 'youtube' || value === 'twitter') {
    return value;
  }
  throw new Error(`Unknown monitor: ${value}`);
}

function includeSignal(signal: Signal, include: readonly string[], exclude: readonly string[]): boolean {
  const body = `${signal.title ?? ''} ${signal.description ?? ''}`.toLowerCase();
  if (exclude.some((term) => body.includes(term.toLowerCase()))) {
    return false;
  }

  if (include.length === 0) {
    return true;
  }

  return include.some((term) => body.includes(term.toLowerCase()));
}

async function run(): Promise<void> {
  mkdirSync('logs', { recursive: true });
  mkdirSync('queues', { recursive: true });

  const config = loadConfig('config');
  const monitorArg = parseMonitorArg(process.argv.slice(2));

  const monitorMap: Record<SignalSource, Monitor> = {
    github: new GitHubMonitor(config.channels.monitors.github),
    hackernews: new HackerNewsMonitor(config.channels.monitors.hackernews),
    youtube: new YouTubeMonitor(config.channels.monitors.youtube),
    twitter: new TwitterMonitor(config.channels.monitors.twitter),
  };

  const monitors = monitorArg
    ? [monitorMap[monitorArg]]
    : (Object.values(monitorMap) as Monitor[]);

  const queueManager = new QueueManager('queues');
  const cache = new DeduplicationCache('queues');
  const scorer = new SignalScorer(config.scoring.rubric, config.scoring.thresholds);
  const router = new QueueRouter(queueManager);

  const results: MonitorResult[] = [];

  for (const monitor of monitors) {
    const monitorName = monitor.name;
    const result: MonitorResult = {
      monitor: monitorName,
      fetched: 0,
      deduped: 0,
      routed: 0,
      errors: 0,
    };

    try {
      logger.info('Running monitor', { monitor: monitorName });
      const fetched = await monitor.fetch();
      result.fetched = fetched.length;

      for (const signal of fetched) {
        if (!includeSignal(signal, config.filters.keywords.include, config.filters.keywords.exclude)) {
          continue;
        }

        if (cache.has(signal.id)) {
          result.deduped += 1;
          continue;
        }

        const scored = scorer.score(signal);
        router.route(scored);
        cache.add(signal.id, signal.source);
        result.routed += 1;
      }
    } catch (error) {
      result.errors += 1;
      logger.error('Monitor failed', {
        monitor: monitorName,
        error: error instanceof Error ? error.message : String(error),
      });
    }

    results.push(result);
  }

  const totals = results.reduce(
    (acc, row) => {
      acc.fetched += row.fetched;
      acc.deduped += row.deduped;
      acc.routed += row.routed;
      acc.errors += row.errors;
      return acc;
    },
    { fetched: 0, deduped: 0, routed: 0, errors: 0 },
  );

  const summary = {
    timestamp: new Date().toISOString(),
    totals,
    results,
    queues: queueManager.stats(),
    cacheSize: cache.size(),
  };

  writeFileSync(join('logs', 'last-run.json'), JSON.stringify(summary, null, 2));
  logger.info('Radar run complete', summary);

  const failedAll = results.length > 0 && results.every((r) => r.errors > 0);
  process.exit(failedAll ? 1 : 0);
}

run().catch((error) => {
  logger.error('Radar run crashed', {
    error: error instanceof Error ? error.stack ?? error.message : String(error),
  });
  process.exit(1);
});
