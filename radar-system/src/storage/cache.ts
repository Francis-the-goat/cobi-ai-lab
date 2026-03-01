import { appendFileSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { CacheEntry, SignalSource } from '../types/index.js';
import { logger } from '../utils/logger.js';

const MAX_CACHE_ENTRIES = 20_000;

export class DeduplicationCache {
  private readonly filePath: string;
  private readonly entries: Map<string, CacheEntry> = new Map();

  constructor(private readonly queuesDir = 'queues') {
    mkdirSync(this.queuesDir, { recursive: true });
    this.filePath = join(this.queuesDir, 'processed.jsonl');
    this.load();
  }

  private load(): void {
    if (!existsSync(this.filePath)) {
      writeFileSync(this.filePath, '');
      return;
    }

    const content = readFileSync(this.filePath, 'utf8');
    if (!content.trim()) {
      return;
    }

    const lines = content.split('\n').filter(Boolean);
    for (const line of lines) {
      try {
        const parsed = JSON.parse(line) as CacheEntry;
        this.entries.set(parsed.id, parsed);
      } catch {
        logger.warn('Skipping malformed cache line', { line });
      }
    }

    if (this.entries.size > MAX_CACHE_ENTRIES) {
      const values = Array.from(this.entries.values()).slice(-MAX_CACHE_ENTRIES);
      this.entries.clear();
      for (const v of values) {
        this.entries.set(v.id, v);
      }
      this.flush();
    }
  }

  private flush(): void {
    const lines = Array.from(this.entries.values()).map((entry) => JSON.stringify(entry));
    writeFileSync(this.filePath, lines.join('\n') + (lines.length > 0 ? '\n' : ''));
  }

  has(id: string): boolean {
    return this.entries.has(id);
  }

  add(id: string, source: SignalSource): void {
    const entry: CacheEntry = {
      id,
      source,
      timestamp: new Date().toISOString(),
    };

    this.entries.set(id, entry);
    appendFileSync(this.filePath, `${JSON.stringify(entry)}\n`);
  }

  size(): number {
    return this.entries.size;
  }

  clear(): void {
    this.entries.clear();
    writeFileSync(this.filePath, '');
  }
}
