import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { QueueEntry, ScoredSignal } from '../types/index.js';

export type QueueName = 'urgent' | 'assets' | 'content' | 'research' | 'all';

const QUEUE_FILE_MAP: Record<QueueName, string> = {
  urgent: 'urgent.jsonl',
  assets: 'assets.jsonl',
  content: 'content.jsonl',
  research: 'research.jsonl',
  all: 'all.jsonl',
};

export class QueueManager {
  constructor(private readonly queuesDir = 'queues') {
    mkdirSync(this.queuesDir, { recursive: true });
    this.initializeFiles();
  }

  private initializeFiles(): void {
    for (const file of Object.values(QUEUE_FILE_MAP)) {
      const full = join(this.queuesDir, file);
      if (!existsSync(full)) {
        writeFileSync(full, '');
      }
    }
    const processedFile = join(this.queuesDir, 'processed.jsonl');
    if (!existsSync(processedFile)) {
      writeFileSync(processedFile, '');
    }
  }

  private queuePath(queueName: QueueName): string {
    return join(this.queuesDir, QUEUE_FILE_MAP[queueName]);
  }

  getQueueForScore(score: number): QueueName {
    if (score >= 40) return 'urgent';
    if (score >= 35) return 'assets';
    if (score >= 30) return 'content';
    if (score >= 25) return 'research';
    return 'all';
  }

  enqueue(signal: ScoredSignal): QueueName {
    const primaryQueue = this.getQueueForScore(signal.totalScore);
    const entry: QueueEntry = {
      signal,
      queuedAt: new Date().toISOString(),
      status: 'pending',
    };

    this.append(primaryQueue, entry);
    if (primaryQueue !== 'all') {
      this.append('all', entry);
    }

    return primaryQueue;
  }

  private append(queueName: QueueName, entry: QueueEntry): void {
    appendFileSync(this.queuePath(queueName), `${JSON.stringify(entry)}\n`);
  }

  read(queueName: QueueName): QueueEntry[] {
    const content = readFileSync(this.queuePath(queueName), 'utf8');
    if (!content.trim()) {
      return [];
    }

    const out: QueueEntry[] = [];
    const lines = content.split('\n').filter(Boolean);
    for (const line of lines) {
      try {
        const parsed = JSON.parse(line) as QueueEntry;
        out.push(parsed);
      } catch {
        // Skip malformed lines for robustness
      }
    }
    return out;
  }

  updateStatus(queueName: QueueName, signalId: string, status: QueueEntry['status']): void {
    const updated = this.read(queueName).map((entry) =>
      entry.signal.id === signalId ? { ...entry, status } : entry,
    );
    const lines = updated.map((entry) => JSON.stringify(entry));
    writeFileSync(this.queuePath(queueName), lines.join('\n') + (lines.length > 0 ? '\n' : ''));
  }

  stats(): Record<QueueName, { total: number; pending: number; processing: number; done: number }> {
    const names = Object.keys(QUEUE_FILE_MAP) as QueueName[];
    const result = {} as Record<QueueName, { total: number; pending: number; processing: number; done: number }>;

    for (const name of names) {
      const entries = this.read(name);
      result[name] = {
        total: entries.length,
        pending: entries.filter((e) => e.status === 'pending').length,
        processing: entries.filter((e) => e.status === 'processing').length,
        done: entries.filter((e) => e.status === 'done').length,
      };
    }

    return result;
  }
}
