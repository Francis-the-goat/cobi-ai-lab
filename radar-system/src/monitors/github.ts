import type { GitHubConfig, Signal } from '../types/index.js';
import { BaseMonitor } from './base.js';

interface GitHubSearchResponse {
  readonly items: ReadonlyArray<{
    readonly id: number;
    readonly full_name: string;
    readonly html_url: string;
    readonly description: string | null;
    readonly stargazers_count: number;
    readonly created_at: string;
    readonly updated_at: string;
    readonly language: string | null;
    readonly owner: {
      readonly login: string;
    };
    readonly topics?: readonly string[];
  }>;
}

export class GitHubMonitor extends BaseMonitor<GitHubConfig> {
  readonly name = 'github' as const;

  constructor(readonly config: GitHubConfig) {
    super();
  }

  async fetch(): Promise<readonly Signal[]> {
    if (!this.config.enabled) {
      return [];
    }

    const token = process.env.GITHUB_TOKEN;
    const createdSince = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
    const byId = new Map<string, Signal>();

    for (const keyword of this.config.filters.keywords) {
      const query = [
        `${keyword} in:name,description,readme`,
        `language:${this.config.filters.language}`,
        `created:>=${createdSince}`,
        `stars:>=${this.config.filters.minStars}`,
      ].join(' ');

      const url = `https://api.github.com/search/repositories?q=${encodeURIComponent(query)}&sort=stars&order=desc&per_page=30`;

      const data = await this.jsonFetch<GitHubSearchResponse>(
        url,
        {
          headers: token
            ? {
                Authorization: `Bearer ${token}`,
                'X-GitHub-Api-Version': '2022-11-28',
              }
            : {
                'X-GitHub-Api-Version': '2022-11-28',
              },
        },
        3,
        600,
      );

      for (const repo of data.items) {
        if (!repo.description || repo.stargazers_count < this.config.filters.minStars) {
          continue;
        }

        const signalId = this.generateId(this.name, String(repo.id));
        byId.set(signalId, {
          id: signalId,
          source: this.name,
          timestamp: repo.created_at,
          raw: repo,
          title: repo.full_name,
          url: repo.html_url,
          author: repo.owner.login,
          description: repo.description,
          tags: repo.topics ?? [],
          engagement: {
            stars: repo.stargazers_count,
          },
        });
      }

      // Lightweight pacing to avoid search API bursts.
      await this.sleep(700);
    }

    return Array.from(byId.values());
  }
}
