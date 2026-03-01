import { XMLParser } from 'fast-xml-parser';
import type { Signal, TwitterConfig } from '../types/index.js';
import { BaseMonitor } from './base.js';

interface RSSItem {
  readonly guid?: string | { readonly ['#text']?: string };
  readonly title?: string;
  readonly link?: string;
  readonly pubDate?: string;
  readonly description?: string;
  readonly author?: string;
}

interface AtomEntry {
  readonly id?: string;
  readonly title?: string;
  readonly link?: { readonly ['@_href']?: string } | readonly { readonly ['@_href']?: string }[];
  readonly updated?: string;
  readonly published?: string;
  readonly summary?: string;
  readonly author?: { readonly name?: string };
}

interface FeedParsed {
  readonly rss?: { readonly channel?: { readonly item?: RSSItem | readonly RSSItem[] } };
  readonly feed?: { readonly entry?: AtomEntry | readonly AtomEntry[] };
}

function asArray<T>(value: T | readonly T[] | undefined): readonly T[] {
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

function extractAtomLink(link: AtomEntry['link']): string | undefined {
  if (!link) return undefined;
  if (Array.isArray(link)) return link[0]?.['@_href'];
  return link['@_href'];
}

export class TwitterMonitor extends BaseMonitor<TwitterConfig> {
  readonly name = 'twitter' as const;
  private readonly parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '@_' });

  constructor(readonly config: TwitterConfig) {
    super();
  }

  async fetch(): Promise<readonly Signal[]> {
    if (!this.config.enabled || this.config.rssFeeds.length === 0) {
      return [];
    }

    const out: Signal[] = [];

    for (const feedUrl of this.config.rssFeeds) {
      const xml = await this.textFetch(feedUrl);
      const parsed = this.parser.parse(xml) as FeedParsed;

      const rssItems = asArray(parsed.rss?.channel?.item);
      for (const item of rssItems) {
        const timestamp = item.pubDate ? new Date(item.pubDate).toISOString() : undefined;
        if (!timestamp || !this.inLastHours(timestamp, 24)) continue;

        const guid =
          typeof item.guid === 'string'
            ? item.guid
            : item.guid?.['#text'] ?? `${feedUrl}:${item.link ?? item.title ?? timestamp}`;

        const title = item.title ?? 'Tweet';
        const desc = item.description ?? '';

        const engagement = this.estimateEngagement(title + ' ' + desc);
        if (engagement < this.config.minEngagement) continue;

        const id = this.generateId(this.name, guid);
        out.push({
          id,
          source: this.name,
          timestamp,
          raw: item,
          title,
          url: item.link,
          author: item.author,
          description: desc,
          tags: ['twitter', 'x'],
          engagement: {
            likes: engagement,
          },
        });
      }

      const atomEntries = asArray(parsed.feed?.entry);
      for (const entry of atomEntries) {
        const timestamp = entry.published ?? entry.updated;
        if (!timestamp || !this.inLastHours(timestamp, 24)) continue;

        const idPart = entry.id ?? `${feedUrl}:${entry.title ?? timestamp}`;
        const engagement = this.estimateEngagement(`${entry.title ?? ''} ${entry.summary ?? ''}`);
        if (engagement < this.config.minEngagement) continue;

        out.push({
          id: this.generateId(this.name, idPart),
          source: this.name,
          timestamp,
          raw: entry,
          title: entry.title ?? 'Tweet',
          url: extractAtomLink(entry.link),
          author: entry.author?.name,
          description: entry.summary,
          tags: ['twitter', 'x'],
          engagement: {
            likes: engagement,
          },
        });
      }

      await this.sleep(350);
    }

    return out;
  }

  private estimateEngagement(content: string): number {
    const normalized = content.toLowerCase();
    let score = 0;

    const metrics = normalized.match(/(\d+[\.,]?\d*)\s*(likes?|retweets?|replies?|hearts?|views?)/g);
    if (metrics) {
      for (const metric of metrics) {
        const numberMatch = metric.match(/\d+[\.,]?\d*/);
        if (!numberMatch) continue;
        const value = Number.parseFloat(numberMatch[0].replace(',', ''));
        if (Number.isFinite(value)) {
          score += value;
        }
      }
    }

    if (score === 0 && /(viral|trending|launch|agent|automation|ai)/.test(normalized)) {
      score = 10;
    }

    return Math.round(score);
  }
}
