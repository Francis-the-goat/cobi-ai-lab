import type { HackerNewsConfig, Signal } from '../types/index.js';
import { BaseMonitor } from './base.js';

interface HNHit {
  readonly objectID: string;
  readonly title: string | null;
  readonly story_title: string | null;
  readonly url: string | null;
  readonly story_url: string | null;
  readonly author: string;
  readonly created_at: string;
  readonly created_at_i: number;
  readonly points: number;
  readonly num_comments: number;
  readonly story_text: string | null;
  readonly _tags: readonly string[];
}

interface HNResponse {
  readonly hits: readonly HNHit[];
}

export class HackerNewsMonitor extends BaseMonitor<HackerNewsConfig> {
  readonly name = 'hackernews' as const;

  constructor(readonly config: HackerNewsConfig) {
    super();
  }

  async fetch(): Promise<readonly Signal[]> {
    if (!this.config.enabled) {
      return [];
    }

    const signals = new Map<string, Signal>();
    const minPoints = this.config.minPoints;

    if (this.config.sources.includes('show_hn')) {
      const showUrl = `https://hn.algolia.com/api/v1/search_by_date?tags=show_hn&numericFilters=points>${minPoints.show}&hitsPerPage=50`;
      const showData = await this.jsonFetch<HNResponse>(showUrl);
      for (const hit of showData.hits) {
        if (!this.inLastHours(hit.created_at, 24)) continue;
        if (hit.points < minPoints.show) continue;
        const title = hit.title ?? hit.story_title;
        if (!title) continue;

        const id = this.generateId(this.name, hit.objectID);
        signals.set(id, {
          id,
          source: this.name,
          timestamp: hit.created_at,
          raw: hit,
          title,
          url: hit.url ?? hit.story_url ?? `https://news.ycombinator.com/item?id=${hit.objectID}`,
          author: hit.author,
          description: hit.story_text ?? undefined,
          tags: ['show_hn', ...hit._tags],
          engagement: {
            comments: hit.num_comments,
            likes: hit.points,
          },
        });
      }
    }

    if (this.config.sources.includes('ai')) {
      const aiUrl = `https://hn.algolia.com/api/v1/search_by_date?query=${encodeURIComponent('ai agent automation llm')}&tags=story&numericFilters=points>${minPoints.ai}&hitsPerPage=50`;
      const aiData = await this.jsonFetch<HNResponse>(aiUrl);
      for (const hit of aiData.hits) {
        if (!this.inLastHours(hit.created_at, 24)) continue;
        if (hit.points < minPoints.ai) continue;
        const title = hit.title ?? hit.story_title;
        if (!title) continue;

        const normalized = `${title} ${hit.story_text ?? ''}`.toLowerCase();
        if (!/(ai|agent|automation|llm|workflow)/.test(normalized)) {
          continue;
        }

        const id = this.generateId(this.name, hit.objectID);
        signals.set(id, {
          id,
          source: this.name,
          timestamp: hit.created_at,
          raw: hit,
          title,
          url: hit.url ?? hit.story_url ?? `https://news.ycombinator.com/item?id=${hit.objectID}`,
          author: hit.author,
          description: hit.story_text ?? undefined,
          tags: hit._tags,
          engagement: {
            comments: hit.num_comments,
            likes: hit.points,
          },
        });
      }
    }

    return Array.from(signals.values());
  }
}
