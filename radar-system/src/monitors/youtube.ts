import { XMLParser } from 'fast-xml-parser';
import type { Signal, YouTubeConfig } from '../types/index.js';
import { BaseMonitor } from './base.js';

interface YouTubeEntry {
  readonly ['yt:videoId']?: string;
  readonly title?: string;
  readonly published?: string;
  readonly updated?: string;
  readonly link?: { readonly ['@_href']?: string } | ReadonlyArray<{ readonly ['@_href']?: string }>;
  readonly author?: { readonly name?: string };
  readonly ['media:group']?: {
    readonly ['media:description']?: string;
  };
}

interface YouTubeFeed {
  readonly feed?: {
    readonly entry?: YouTubeEntry | readonly YouTubeEntry[];
  };
}

function toArray<T>(input: T | readonly T[] | undefined): readonly T[] {
  if (!input) return [];
  return Array.isArray(input) ? input : [input];
}

function extractLink(entry: YouTubeEntry): string | undefined {
  if (!entry.link) return undefined;
  if (Array.isArray(entry.link)) {
    return entry.link[0]?.['@_href'];
  }
  return entry.link['@_href'];
}

export class YouTubeMonitor extends BaseMonitor<YouTubeConfig> {
  readonly name = 'youtube' as const;
  private readonly parser = new XMLParser({ ignoreAttributes: false, attributeNamePrefix: '@_' });

  constructor(readonly config: YouTubeConfig) {
    super();
  }

  async fetch(): Promise<readonly Signal[]> {
    if (!this.config.enabled) return [];

    const results: Signal[] = [];

    for (const channel of this.config.channels) {
      const feedUrl = `https://www.youtube.com/feeds/videos.xml?channel_id=${encodeURIComponent(channel.id)}`;
      const xml = await this.textFetch(feedUrl);
      const parsed = this.parser.parse(xml) as YouTubeFeed;
      const entries = toArray(parsed.feed?.entry);

      for (const entry of entries) {
        const published = entry.published ?? entry.updated;
        if (!published || !this.inLastHours(published, 24)) {
          continue;
        }

        const videoId = entry['yt:videoId'];
        const url = extractLink(entry) ?? (videoId ? `https://www.youtube.com/watch?v=${videoId}` : undefined);
        if (!videoId || !entry.title || !url) {
          continue;
        }

        const id = this.generateId(this.name, videoId);
        results.push({
          id,
          source: this.name,
          timestamp: published,
          raw: entry,
          title: entry.title,
          url,
          author: entry.author?.name ?? channel.name,
          description: entry['media:group']?.['media:description'],
          tags: ['youtube', 'video'],
        });
      }

      await this.sleep(350);
    }

    return results;
  }
}
