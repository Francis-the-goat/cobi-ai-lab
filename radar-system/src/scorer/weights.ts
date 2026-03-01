import type { RubricConfig, ThresholdConfig } from '../types/index.js';

export const DEFAULT_RUBRIC: RubricConfig = {
  pain: { weight: 8, description: 'Problem acuity' },
  roi: { weight: 8, description: 'Quantifiable value' },
  autoFit: { weight: 8, description: 'Agent solvability' },
  distribution: { weight: 7, description: 'Can Cobi reach buyers?' },
  defensibility: { weight: 6, description: 'Hard to replicate?' },
  speed: { weight: 8, description: 'Buildable in 7 days?' },
};

export const DEFAULT_THRESHOLDS: ThresholdConfig = {
  alert: 40,
  asset: 35,
  content: 30,
  research: 25,
  log: 0,
};
