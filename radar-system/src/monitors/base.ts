import type { Logger, Monitor, Signal, SignalSource } from '../types/index.js';
import { logger } from '../utils/logger.js';

export interface BaseMonitorConfig {
  readonly enabled: boolean;
  readonly interval: number;
}

export abstract class BaseMonitor<TConfig extends BaseMonitorConfig> implements Monitor {
  abstract readonly name: SignalSource;
  abstract readonly config: TConfig;
  protected readonly log: Logger;

  protected constructor(log: Logger = logger) {
    this.log = log;
  }

  abstract fetch(): Promise<readonly Signal[]>;

  protected async jsonFetch<T>(
    url: string,
    init: RequestInit = {},
    retries = 3,
    backoffMs = 500,
  ): Promise<T> {
    let lastError: Error | undefined;

    for (let attempt = 1; attempt <= retries; attempt += 1) {
      try {
        const response = await fetch(url, {
          ...init,
          headers: {
            Accept: 'application/json',
            'User-Agent': 'radar-system/1.0',
            ...(init.headers ?? {}),
          },
        });

        if (!response.ok) {
          const body = await response.text();
          throw new Error(`HTTP ${response.status} ${response.statusText}: ${body.slice(0, 200)}`);
        }

        const data = (await response.json()) as T;
        return data;
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        if (attempt < retries) {
          const delay = backoffMs * 2 ** (attempt - 1);
          await this.sleep(delay);
          continue;
        }
      }
    }

    throw lastError ?? new Error('jsonFetch failed');
  }

  protected async textFetch(url: string, init: RequestInit = {}): Promise<string> {
    const response = await fetch(url, {
      ...init,
      headers: {
        'User-Agent': 'radar-system/1.0',
        ...(init.headers ?? {}),
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status} ${response.statusText}`);
    }

    return response.text();
  }

  protected generateId(source: SignalSource, externalId: string): string {
    return `${source}:${externalId}`;
  }

  protected async sleep(ms: number): Promise<void> {
    await new Promise((resolve) => setTimeout(resolve, ms));
  }

  protected inLastHours(isoTimestamp: string, hours: number): boolean {
    const t = new Date(isoTimestamp).getTime();
    if (Number.isNaN(t)) {
      return false;
    }
    const cutoff = Date.now() - hours * 60 * 60 * 1000;
    return t >= cutoff;
  }
}
