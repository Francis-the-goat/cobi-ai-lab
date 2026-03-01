import type {
  ActionType,
  PriorityLevel,
  RubricConfig,
  RubricScores,
  ScoredSignal,
  Signal,
  ThresholdConfig,
} from '../types/index.js';
import { DEFAULT_RUBRIC, DEFAULT_THRESHOLDS } from './weights.js';

export class SignalScorer {
  constructor(
    private readonly rubric: RubricConfig = DEFAULT_RUBRIC,
    private readonly thresholds: ThresholdConfig = DEFAULT_THRESHOLDS,
  ) {}

  score(signal: Signal): ScoredSignal {
    const text = `${signal.title ?? ''} ${signal.description ?? ''} ${(signal.tags ?? []).join(' ')}`.toLowerCase();

    const scores: RubricScores = {
      pain: this.painScore(text),
      roi: this.roiScore(text, signal),
      autoFit: this.autoFitScore(text),
      defensibility: this.defensibilityScore(text),
      distribution: this.distributionScore(text),
      speed: this.speedScore(text),
    };

    const totalScore = this.weightedTotal(scores);
    const action = this.pickAction(totalScore);
    const priority = this.priorityFromAction(action);

    const reasoning = [
      `Pain ${scores.pain}/5`,
      `ROI ${scores.roi}/5`,
      `Automation fit ${scores.autoFit}/5`,
      `Defensibility ${scores.defensibility}/5`,
      `Distribution ${scores.distribution}/5`,
      `Speed ${scores.speed}/5`,
      `=> ${totalScore.toFixed(1)} (${action})`,
    ].join(' | ');

    return {
      ...signal,
      scores,
      totalScore,
      action,
      priority,
      reasoning,
    };
  }

  private weightedTotal(scores: RubricScores): number {
    const total =
      (scores.pain / 5) * this.rubric.pain.weight +
      (scores.roi / 5) * this.rubric.roi.weight +
      (scores.autoFit / 5) * this.rubric.autoFit.weight +
      (scores.defensibility / 5) * this.rubric.defensibility.weight +
      (scores.distribution / 5) * this.rubric.distribution.weight +
      (scores.speed / 5) * this.rubric.speed.weight;

    return Math.max(0, Math.min(45, Number(total.toFixed(2))));
  }

  private painScore(text: string): number {
    return this.clamp(
      2 +
        this.keywordHits(text, ['pain', 'manual', 'slow', 'error', 'broken', 'waste', 'overhead']) +
        this.keywordHits(text, ['urgent', 'critical', 'must-have'])
    );
  }

  private roiScore(text: string, signal: Signal): number {
    const engagementBoost =
      (signal.engagement?.stars ?? 0) >= 100 ||
      (signal.engagement?.comments ?? 0) >= 30 ||
      (signal.engagement?.views ?? 0) >= 10_000
        ? 1
        : 0;

    return this.clamp(
      2 +
        this.keywordHits(text, ['save', 'revenue', 'profit', 'cost', 'efficiency', 'productivity', 'pipeline']) +
        engagementBoost,
    );
  }

  private autoFitScore(text: string): number {
    return this.clamp(
      1 + this.keywordHits(text, ['agent', 'automation', 'workflow', 'llm', 'ai', 'autonomous', 'integration']),
    );
  }

  private defensibilityScore(text: string): number {
    return this.clamp(
      1 + this.keywordHits(text, ['vertical', 'domain', 'compliance', 'data', 'network effect', 'proprietary']),
    );
  }

  private distributionScore(text: string): number {
    return this.clamp(
      1 + this.keywordHits(text, ['smb', 'small business', 'ops', 'service business', 'agency', 'sales']),
    );
  }

  private speedScore(text: string): number {
    return this.clamp(
      2 + this.keywordHits(text, ['template', 'sdk', 'api', 'no-code', 'quickstart', 'starter']),
    );
  }

  private keywordHits(text: string, words: readonly string[]): number {
    let hits = 0;
    for (const word of words) {
      if (text.includes(word)) {
        hits += 1;
      }
    }
    return hits;
  }

  private clamp(score: number): number {
    return Math.max(1, Math.min(5, score));
  }

  private pickAction(score: number): ActionType {
    if (score >= this.thresholds.alert) return 'alert';
    if (score >= this.thresholds.asset) return 'asset';
    if (score >= this.thresholds.content) return 'content';
    if (score >= this.thresholds.research) return 'research';
    return 'log';
  }

  private priorityFromAction(action: ActionType): PriorityLevel {
    switch (action) {
      case 'alert':
      case 'asset':
        return 'high';
      case 'content':
      case 'research':
        return 'medium';
      case 'log':
      default:
        return 'low';
    }
  }
}
