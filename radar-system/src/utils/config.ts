import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import YAML from 'yaml';
import { z } from 'zod';
import type { AppConfig, ChannelsConfig, FilterConfig } from '../types/index.js';
import { logger } from './logger.js';

const rubricWeightSchema = z.object({
  weight: z.number().int().positive(),
  description: z.string().min(1),
});

const scoringSchema = z.object({
  rubric: z.object({
    pain: rubricWeightSchema,
    roi: rubricWeightSchema,
    autoFit: rubricWeightSchema,
    distribution: rubricWeightSchema,
    defensibility: rubricWeightSchema,
    speed: rubricWeightSchema,
  }),
  thresholds: z.object({
    alert: z.number().int().min(0),
    asset: z.number().int().min(0),
    content: z.number().int().min(0),
    research: z.number().int().min(0),
    log: z.number().int().min(0),
  }),
});

const channelsSchema = z.object({
  monitors: z.object({
    github: z.object({
      enabled: z.boolean(),
      interval: z.number().int().positive(),
      filters: z.object({
        language: z.string(),
        minStars: z.number().int().nonnegative(),
        keywords: z.array(z.string().min(1)).min(1),
      }),
    }),
    hackernews: z.object({
      enabled: z.boolean(),
      interval: z.number().int().positive(),
      sources: z.array(z.enum(['show_hn', 'ai'])).min(1),
      minPoints: z.object({
        show: z.number().int().nonnegative(),
        ai: z.number().int().nonnegative(),
      }),
    }),
    youtube: z.object({
      enabled: z.boolean(),
      interval: z.number().int().positive(),
      channels: z.array(
        z.object({
          id: z.string().min(1),
          name: z.string().min(1),
        }),
      ),
    }),
    twitter: z.object({
      enabled: z.boolean(),
      interval: z.number().int().positive(),
      rssFeeds: z.array(z.string().url()),
      minEngagement: z.number().int().nonnegative(),
    }),
  }),
});

const filtersSchema = z.object({
  keywords: z.object({
    include: z.array(z.string()),
    exclude: z.array(z.string()),
  }),
  tags: z.object({
    include: z.array(z.string()),
    exclude: z.array(z.string()),
  }),
});

const appConfigSchema = z.object({
  channels: channelsSchema,
  scoring: scoringSchema,
  filters: filtersSchema,
});

export const DEFAULT_CONFIG: AppConfig = {
  channels: {
    monitors: {
      github: {
        enabled: true,
        interval: 7200,
        filters: {
          language: 'typescript',
          minStars: 10,
          keywords: ['agent', 'ai', 'llm', 'automation', 'workflow', 'bot'],
        },
      },
      hackernews: {
        enabled: true,
        interval: 1800,
        sources: ['show_hn', 'ai'],
        minPoints: {
          show: 10,
          ai: 20,
        },
      },
      youtube: {
        enabled: true,
        interval: 3600,
        channels: [{ id: 'UCt8xK0wfUCn5YTCYEmIDa1g', name: 'Nate B Jones' }],
      },
      twitter: {
        enabled: false,
        interval: 1800,
        rssFeeds: [],
        minEngagement: 10,
      },
    },
  },
  scoring: {
    rubric: {
      pain: { weight: 8, description: 'Problem acuity' },
      roi: { weight: 8, description: 'Quantifiable value' },
      autoFit: { weight: 8, description: 'Agent solvability' },
      distribution: { weight: 7, description: 'Can Cobi reach buyers?' },
      defensibility: { weight: 6, description: 'Hard to replicate?' },
      speed: { weight: 8, description: 'Buildable in 7 days?' },
    },
    thresholds: {
      alert: 40,
      asset: 35,
      content: 30,
      research: 25,
      log: 0,
    },
  },
  filters: {
    keywords: {
      include: ['agent', 'ai', 'llm', 'automation', 'workflow', 'smb', 'business'],
      exclude: ['crypto', 'nft', 'meme', 'gambling'],
    },
    tags: {
      include: ['ai', 'agents', 'automation', 'smb'],
      exclude: [],
    },
  },
};

function readYaml(path: string): unknown {
  if (!existsSync(path)) {
    return undefined;
  }

  const content = readFileSync(path, 'utf8');
  return YAML.parse(content);
}

function mergeChannels(base: ChannelsConfig, incoming: unknown): ChannelsConfig {
  if (incoming === undefined) {
    return base;
  }

  const parsed = channelsSchema.partial().safeParse(incoming);
  if (!parsed.success) {
    logger.warn('Invalid channels config detected, falling back to defaults', {
      issues: parsed.error.issues,
    });
    return base;
  }

  const monitors = parsed.data.monitors ?? {};
  return {
    monitors: {
      github: {
        ...base.monitors.github,
        ...monitors.github,
        filters: {
          ...base.monitors.github.filters,
          ...monitors.github?.filters,
        },
      },
      hackernews: {
        ...base.monitors.hackernews,
        ...monitors.hackernews,
        minPoints: {
          ...base.monitors.hackernews.minPoints,
          ...monitors.hackernews?.minPoints,
        },
      },
      youtube: {
        ...base.monitors.youtube,
        ...monitors.youtube,
        channels: monitors.youtube?.channels ?? base.monitors.youtube.channels,
      },
      twitter: {
        ...base.monitors.twitter,
        ...monitors.twitter,
        rssFeeds: monitors.twitter?.rssFeeds ?? base.monitors.twitter.rssFeeds,
      },
    },
  };
}

function mergeFilters(base: FilterConfig, incoming: unknown): FilterConfig {
  if (incoming === undefined) {
    return base;
  }

  const parsed = filtersSchema.partial().safeParse(incoming);
  if (!parsed.success) {
    logger.warn('Invalid filters config detected, falling back to defaults', {
      issues: parsed.error.issues,
    });
    return base;
  }

  return {
    keywords: {
      include: parsed.data.keywords?.include ?? base.keywords.include,
      exclude: parsed.data.keywords?.exclude ?? base.keywords.exclude,
    },
    tags: {
      include: parsed.data.tags?.include ?? base.tags.include,
      exclude: parsed.data.tags?.exclude ?? base.tags.exclude,
    },
  };
}

function mergeScoring(base: AppConfig['scoring'], incoming: unknown): AppConfig['scoring'] {
  if (incoming === undefined) {
    return base;
  }

  const parsed = scoringSchema.partial().safeParse(incoming);
  if (!parsed.success) {
    logger.warn('Invalid scoring config detected, falling back to defaults', {
      issues: parsed.error.issues,
    });
    return base;
  }

  return {
    rubric: {
      pain: parsed.data.rubric?.pain ?? base.rubric.pain,
      roi: parsed.data.rubric?.roi ?? base.rubric.roi,
      autoFit: parsed.data.rubric?.autoFit ?? base.rubric.autoFit,
      distribution: parsed.data.rubric?.distribution ?? base.rubric.distribution,
      defensibility: parsed.data.rubric?.defensibility ?? base.rubric.defensibility,
      speed: parsed.data.rubric?.speed ?? base.rubric.speed,
    },
    thresholds: {
      alert: parsed.data.thresholds?.alert ?? base.thresholds.alert,
      asset: parsed.data.thresholds?.asset ?? base.thresholds.asset,
      content: parsed.data.thresholds?.content ?? base.thresholds.content,
      research: parsed.data.thresholds?.research ?? base.thresholds.research,
      log: parsed.data.thresholds?.log ?? base.thresholds.log,
    },
  };
}

export function loadConfig(configDir = 'config'): AppConfig {
  const channels = readYaml(join(configDir, 'channels.yaml'));
  const scoring = readYaml(join(configDir, 'scoring.yaml'));
  const filters = readYaml(join(configDir, 'filters.yaml'));

  const merged: AppConfig = {
    channels: mergeChannels(DEFAULT_CONFIG.channels, channels),
    scoring: mergeScoring(DEFAULT_CONFIG.scoring, scoring),
    filters: mergeFilters(DEFAULT_CONFIG.filters, filters),
  };

  const parsed = appConfigSchema.safeParse(merged);
  if (!parsed.success) {
    logger.error('Failed to validate merged config. Using defaults.', {
      issues: parsed.error.issues,
    });
    return DEFAULT_CONFIG;
  }

  return parsed.data;
}

export function getConfig(): AppConfig {
  return loadConfig();
}
