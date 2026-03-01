#!/usr/bin/env node
/**
 * Signal Scorer - Apply Foundry Rubric to detected signals
 * Usage: cat signal.json | node score-signal.js
 * Output: Scored signal with action recommendation
 */

const readline = require('readline');
const fs = require('fs');

// Foundry Rubric weights
const RUBRIC = {
  pain: { weight: 8, desc: 'How acute is the problem?' },
  roi: { weight: 8, desc: 'Can value be quantified?' },
  auto_fit: { weight: 8, desc: 'Can agents solve this?' },
  defensibility: { weight: 6, desc: 'Hard to replicate?' },
  distribution: { weight: 7, desc: 'Can Cobi reach buyers?' },
  speed: { weight: 8, desc: 'Buildable in 7 days?' }
};

const MAX_SCORE = Object.values(RUBRIC).reduce((a, b) => a + b.weight * 5, 0); // 225

// Scoring heuristics based on signal source and content
function scoreSignal(signal) {
  let scores = {};
  
  // Default scores by source
  switch(signal.source) {
    case 'github-trending':
      scores = scoreGithub(signal);
      break;
    case 'hackernews':
      scores = scoreHN(signal);
      break;
    case 'youtube':
      scores = scoreYouTube(signal);
      break;
    case 'x-twitter':
      scores = scoreTwitter(signal);
      break;
    default:
      scores = { pain: 3, roi: 3, auto_fit: 3, defensibility: 3, distribution: 3, speed: 3 };
  }
  
  // Calculate total
  let total = 0;
  let maxPossible = 0;
  for (const [key, config] of Object.entries(RUBRIC)) {
    total += (scores[key] || 3) * config.weight;
    maxPossible += 5 * config.weight;
  }
  
  const normalized = Math.round((total / maxPossible) * 45); // 0-45 scale
  
  return {
    ...signal,
    scores,
    total_score: normalized,
    action: determineAction(normalized),
    priority: normalized >= 35 ? 'HIGH' : normalized >= 30 ? 'MEDIUM' : 'LOW'
  };
}

function scoreGithub(signal) {
  const repo = signal.repo || {};
  const desc = (repo.description || '').toLowerCase();
  const topics = (repo.topics || []).join(' ').toLowerCase();
  const text = desc + ' ' + topics;
  
  // Pain: Are they solving a workflow bottleneck?
  const pain = text.match(/automat|workflow|schedul|book|intake|support/) ? 4 : 3;
  
  // ROI: Can this save time/money?
  const roi = text.match(/save|reduc|cut|eliminat|replace/) ? 4 : 3;
  
  // Auto-fit: Is this agent-shaped?
  const auto_fit = text.match(/agent|ai|llm|claude|openai|assist|bot/) ? 5 : 2;
  
  // Defensibility: Is this just a wrapper?
  const defensibility = repo.stars > 500 ? 3 : 4; // Niche = more defensible
  
  // Distribution: Can Cobi sell this?
  const distribution = text.match(/smb|small.business|local|service|trade/) ? 5 : 3;
  
  // Speed: Can build fast?
  const speed = text.match(/simple|lightweight|minimal/) ? 5 : 
                text.match(/framework|platform|enterprise/) ? 2 : 4;
  
  return { pain, roi, auto_fit, defensibility, distribution, speed };
}

function scoreHN(signal) {
  const title = (signal.title || '').toLowerCase();
  const comments = signal.comments || 0;
  
  // Higher engagement = more validation
  const engagement = comments > 50 ? 1 : 0;
  
  const pain = title.match(/frustrat|pain|hate|struggl|wast|bottleneck/) ? 4 + engagement : 3;
  const roi = title.match(/made|\$|revenue|sales|profit/) ? 4 : 3;
  const auto_fit = title.match(/ai|llm|agent|automat/) ? 5 : 2;
  const defensibility = 3;
  const distribution = title.match(/smb|local|small|service/) ? 5 : 3;
  const speed = 4;
  
  return { pain, roi, auto_fit, defensibility, distribution, speed };
}

function scoreYouTube(signal) {
  const title = (signal.title || '').toLowerCase();
  
  // Nate/Kyle content tends to be high-signal
  const base = 3;
  const is_high_value_creator = signal.channel?.match(/Nate|Kyle|Karpathy|Naval/);
  
  return {
    pain: is_high_value_creator ? 4 : 3,
    roi: title.match(/business|money|revenue|client/) ? 4 : 3,
    auto_fit: title.match(/agent|ai|automation|claude/) ? 5 : 3,
    defensibility: 3,
    distribution: 4,
    speed: 4
  };
}

function scoreTwitter(signal) {
  const text = (signal.text || '').toLowerCase();
  
  return {
    pain: text.match(/problem|pain|issue|broke/) ? 4 : 3,
    roi: text.match(/$|revenue|growth|scale/) ? 4 : 3,
    auto_fit: text.match(/agent|ai|llm/) ? 5 : 3,
    defensibility: 3,
    distribution: 4,
    speed: 4
  };
}

function determineAction(score) {
  if (score >= 40) return 'ALERT+BUILD';  // Immediate action
  if (score >= 35) return 'CREATE_ASSET'; // Full asset pack
  if (score >= 30) return 'CONTENT';      // Content angle
  if (score >= 25) return 'RESEARCH';     // Deep dive
  return 'LOG';                           // Just log it
}

// Main
async function main() {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  });
  
  let input = '';
  rl.on('line', line => input += line);
  rl.on('close', () => {
    try {
      const signal = JSON.parse(input);
      const scored = scoreSignal(signal);
      console.log(JSON.stringify(scored, null, 2));
    } catch(e) {
      console.error('Invalid JSON:', e.message);
      process.exit(1);
    }
  });
}

main();
