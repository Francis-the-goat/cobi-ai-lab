export type SignalSource = 'github' | 'hackernews' | 'youtube' | 'twitter';
export type ActionType = 'alert' | 'asset' | 'content' | 'research' | 'log';
export type PriorityLevel = 'high' | 'medium' | 'low';
export type QueueStatus = 'pending' | 'processing' | 'done';

export interface EngagementMetrics {
  readonly stars?: number;
  readonly comments?: number;
  readonly views?: number;
  readonly likes?: number;
  readonly retweets?: number;
}

export interface Signal {
  readonly id: string;
  readonly source: SignalSource;
  readonly timestamp: string;
  readonly raw: unknown;
  readonly title?: string;
  readonly url?: string;
  readonly author?: string;
  readonly description?: string;
  readonly tags?: readonly string[];
  readonly engagement?: EngagementMetrics;
}

export interface RubricScores {
  readonly pain: number;
  readonly roi: number;
  readonly autoFit: number;
  readonly defensibility: number;
  readonly distribution: number;
  readonly speed: number;
}

export interface ScoredSignal extends Signal {
  readonly scores: RubricScores;
  readonly totalScore: number;
  readonly action: ActionType;
  readonly priority: PriorityLevel;
  readonly reasoning: string;
}

export interface QueueEntry {
  readonly signal: ScoredSignal;
  readonly queuedAt: string;
  readonly status: QueueStatus;
}

export interface RubricWeight {
  readonly weight: number;
  readonly description: string;
}

export interface RubricConfig {
  readonly pain: RubricWeight;
  readonly roi: RubricWeight;
  readonly autoFit: RubricWeight;
  readonly distribution: RubricWeight;
  readonly defensibility: RubricWeight;
  readonly speed: RubricWeight;
}

export interface ThresholdConfig {
  readonly alert: number;
  readonly asset: number;
  readonly content: number;
  readonly research: number;
  readonly log: number;
}

export interface GitHubConfig {
  readonly enabled: boolean;
  readonly interval: number;
  readonly filters: {
    readonly language: string;
    readonly minStars: number;
    readonly keywords: readonly string[];
  };
}

export interface HackerNewsConfig {
  readonly enabled: boolean;
  readonly interval: number;
  readonly sources: readonly ('show_hn' | 'ai')[];
  readonly minPoints: {
    readonly show: number;
    readonly ai: number;
  };
}

export interface YouTubeChannel {
  readonly id: string;
  readonly name: string;
}

export interface YouTubeConfig {
  readonly enabled: boolean;
  readonly interval: number;
  readonly channels: readonly YouTubeChannel[];
}

export interface TwitterConfig {
  readonly enabled: boolean;
  readonly interval: number;
  readonly rssFeeds: readonly string[];
  readonly minEngagement: number;
}

export interface ChannelsConfig {
  readonly monitors: {
    readonly github: GitHubConfig;
    readonly hackernews: HackerNewsConfig;
    readonly youtube: YouTubeConfig;
    readonly twitter: TwitterConfig;
  };
}

export interface FilterConfig {
  readonly keywords: {
    readonly include: readonly string[];
    readonly exclude: readonly string[];
  };
  readonly tags: {
    readonly include: readonly string[];
    readonly exclude: readonly string[];
  };
}

export interface AppConfig {
  readonly channels: ChannelsConfig;
  readonly scoring: {
    readonly rubric: RubricConfig;
    readonly thresholds: ThresholdConfig;
  };
  readonly filters: FilterConfig;
}

export interface CacheEntry {
  readonly id: string;
  readonly source: SignalSource;
  readonly timestamp: string;
}

export interface MonitorResult {
  readonly monitor: SignalSource;
  readonly fetched: number;
  readonly deduped: number;
  readonly routed: number;
  readonly errors: number;
}

export interface HealthCheck {
  readonly status: 'healthy' | 'degraded' | 'unhealthy';
  readonly checks: ReadonlyArray<{
    readonly name: string;
    readonly status: 'pass' | 'fail' | 'warn';
    readonly message: string;
  }>;
  readonly timestamp: string;
}

export interface Logger {
  info(message: string, context?: Record<string, unknown>): void;
  warn(message: string, context?: Record<string, unknown>): void;
  error(message: string, context?: Record<string, unknown>): void;
  debug(message: string, context?: Record<string, unknown>): void;
}

export interface Monitor {
  readonly name: SignalSource;
  fetch(): Promise<readonly Signal[]>;
}
