import type { ScoredSignal } from '../types/index.js';
import { QueueManager, type QueueName } from '../storage/queue.js';

export interface RouteResult {
  readonly signalId: string;
  readonly queue: QueueName;
  readonly action: ScoredSignal['action'];
  readonly score: number;
}

export class QueueRouter {
  constructor(private readonly queueManager: QueueManager) {}

  route(signal: ScoredSignal): RouteResult {
    const queue = this.queueManager.enqueue(signal);
    return {
      signalId: signal.id,
      queue,
      action: signal.action,
      score: signal.totalScore,
    };
  }

  routeBatch(signals: readonly ScoredSignal[]): readonly RouteResult[] {
    return signals.map((signal) => this.route(signal));
  }
}
