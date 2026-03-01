#!/usr/bin/env python3
"""
Evaluate buildability of a pattern
Returns: 0 = proposal generated, 1 = rejected, 2 = error
"""

import argparse
import re
import sys
import yaml
from pathlib import Path
from datetime import datetime

def load_config(config_path):
    """Load scoring configuration"""
    if Path(config_path).exists():
        with open(config_path) as f:
            return yaml.safe_load(f)
    return {
        'value_criteria': {
            'novelty_threshold': 7,
            'actionability_threshold': 7,
            'reuse_potential': 6
        },
        'constraint_filters': {
            'max_cost': 50,
            'requires_realtime': False
        }
    }

def parse_pattern(pattern_file):
    """Extract key fields from pattern note"""
    with open(pattern_file) as f:
        content = f.read()
    
    pattern = {
        'title': '',
        'source': '',
        'thinking_architecture': '',
        'applicability': {},
        'content': content
    }
    
    # Extract title
    title_match = re.search(r'^# (.+)$', content, re.MULTILINE)
    if title_match:
        pattern['title'] = title_match.group(1)
    
    # Extract source
    source_match = re.search(r'Origin:\s*(.+)', content)
    if source_match:
        pattern['source'] = source_match.group(1)
    
    # Extract thinking architecture
    arch_match = re.search(r'## Thinking Architecture\s*(.+?)(?=##|\Z)', content, re.DOTALL)
    if arch_match:
        pattern['thinking_architecture'] = arch_match.group(1).strip()
    
    # Extract applicability to constraints
    for constraint in ['Warehouse shifts', '$200 budget', '90-day sprint', '10K MRR']:
        match = re.search(rf'\| {constraint} \| ([✅❌⚠️])', content)
        if match:
            pattern['applicability'][constraint] = match.group(1)
    
    return pattern

def evaluate_buildability(pattern):
    """Score pattern against buildability criteria"""
    scores = {
        'codifiable': 0,
        'reusable': 0,
        'valuable': 0,
        'constraint_fit': 0
    }
    
    reasons = {
        'codifiable': [],
        'reusable': [],
        'valuable': [],
        'constraint_fit': []
    }
    
    # 1. Codifiable — can this be a skill?
    content = pattern['content'].lower()
    
    # Positive signals
    if any(x in content for x in ['automation', 'workflow', 'script', 'skill', 'tool']):
        scores['codifiable'] += 3
        reasons['codifiable'].append('Contains automation/workflow language')
    
    if 'thinking architecture' in content and len(pattern['thinking_architecture']) > 50:
        scores['codifiable'] += 2
        reasons['codifiable'].append('Has structured thinking architecture')
    
    if 'acceptance criteria' in content or 'framework' in content:
        scores['codifiable'] += 2
        reasons['codifiable'].append('Contains framework/structure')
    
    # Negative signals
    if any(x in content for x in ['infrastructure', 'config', 'setup', 'installation']):
        scores['codifiable'] -= 2
        reasons['codifiable'].append('May be infrastructure, not skill')
    
    if 'my specific' in content or 'only for me' in content:
        scores['codifiable'] -= 3
        reasons['codifiable'].append('Appears too specific to be reusable')
    
    # 2. Reusable — would others use it?
    if 'agent' in content or 'agents' in content:
        scores['reusable'] += 3
        reasons['reusable'].append('Agent-related (broad applicability)')
    
    if 'openclaw' in content or 'ai system' in content:
        scores['reusable'] += 2
        reasons['reusable'].append('OpenClaw/AI system related')
    
    if 'smb' in content or 'business' in content or 'roi' in content:
        scores['reusable'] += 2
        reasons['reusable'].append('Business/monetization applicability')
    
    # 3. Valuable — solves real problem?
    if 'fix' in content or 'solve' in content or 'problem' in content:
        scores['valuable'] += 2
        reasons['valuable'].append('Addresses specific problem')
    
    if any(x in content for x in ['efficiency', 'automation', 'async', 'background']):
        scores['valuable'] += 2
        reasons['valuable'].append('Improves operational efficiency')
    
    # 4. Constraint fit — matches Cobi's profile?
    fit_score = 0
    
    # Check applicability table
    for constraint, emoji in pattern['applicability'].items():
        if emoji == '✅':
            fit_score += 2
            reasons['constraint_fit'].append(f'{constraint}: good fit')
        elif emoji == '⚠️':
            fit_score += 1
            reasons['constraint_fit'].append(f'{constraint}: partial fit')
        elif emoji == '❌':
            fit_score -= 2
            reasons['constraint_fit'].append(f'{constraint}: poor fit')
    
    scores['constraint_fit'] = fit_score
    
    # Calculate overall
    overall = sum(scores.values())
    max_possible = 20  # rough normalization
    normalized = min(10, max(1, round((overall / max_possible) * 10)))
    
    return {
        'scores': scores,
        'normalized': normalized,
        'reasons': reasons,
        'overall': overall
    }

def determine_risk(evaluation):
    """Determine risk level based on evaluation"""
    if evaluation['normalized'] >= 8:
        return 'Low'
    elif evaluation['normalized'] >= 6:
        return 'Medium'
    else:
        return 'High'

def determine_cost(evaluation):
    """Estimate implementation cost"""
    if evaluation['scores']['codifiable'] >= 6:
        return '$0-10'  # Well-defined, clear structure
    elif evaluation['scores']['codifiable'] >= 4:
        return '$10-25'  # Some ambiguity
    else:
        return '$25+'  # Needs significant design

def generate_proposal(pattern, evaluation, vault_path):
    """Generate proposal markdown file"""
    
    safe_name = re.sub(r'[^\w-]', '-', pattern['title'].lower())[:50]
    date_str = datetime.now().strftime('%Y-%m-%d')
    
    filename = f"{safe_name}-{date_str}-proposal.md"
    filepath = Path(vault_path) / "04-decisions" / "skill-proposals" / filename
    
    risk = determine_risk(evaluation)
    cost = determine_cost(evaluation)
    
    proposal = f"""# Skill Proposal: {pattern['title']}
Date: {date_str}
Source: [[{Path(pattern_file).stem}]]

## Source Pattern
{pattern['thinking_architecture'][:500] if pattern['thinking_architecture'] else 'See linked source'}

## Buildability Analysis
- [x] Codifiable: Yes — can be expressed as OpenClaw skill
  - Evidence: {'; '.join(evaluation['reasons']['codifiable'])}
- [x] Reusable: Yes — applies to multiple use cases
  - Evidence: {'; '.join(evaluation['reasons']['reusable'])}
- [x] Constraint-fit: {'Yes' if evaluation['scores']['constraint_fit'] >= 5 else 'Partial'}
  - Evidence: {'; '.join(evaluation['reasons']['constraint_fit'])}

## Value Assessment
| Criterion | Score | Evidence |
|-----------|-------|----------|
| Codifiable | {evaluation['scores']['codifiable']}/10 | Skill potential |
| Reusable | {evaluation['scores']['reusable']}/10 | {'; '.join(evaluation['reasons']['reusable'][:2])} |
| Valuable | {evaluation['scores']['valuable']}/10 | {'; '.join(evaluation['reasons']['valuable'][:2])} |
| Constraint fit | {evaluation['scores']['constraint_fit']}/10 | Warehouse/budget alignment |
| **Overall** | **{evaluation['normalized']}/10** | Build recommended |

## Proposed Skill Spec

### Name
skill-{safe_name}

### What It Does
Implements the {pattern['title']} pattern as an autonomous OpenClaw skill

### Acceptance Criteria
- [ ] Implements core pattern from source
- [ ] Fits constraint profile (async, <$50)
- [ ] Includes clear usage documentation
- [ ] Tested on live data

### Constraint Architecture
- Model: Hybrid (local analysis + Kimi synthesis)
- Cost per use: {cost}
- Async-friendly: Yes
- Dependencies: OpenClaw gateway, Obsidian vault

### Risk Assessment
Level: {risk}
Mitigation: Start with minimal implementation, iterate based on usage

## Recommendation
**BUILD** — Overall score {evaluation['normalized']}/10, meets all criteria

Reply "build {safe_name}" to approve, "skip {safe_name}" to discard.
"""
    
    filepath.write_text(proposal)
    return filepath

def generate_rejection(pattern, evaluation, vault_path):
    """Generate rejection log file"""
    
    safe_name = re.sub(r'[^\w-]', '-', pattern['title'].lower())[:50]
    date_str = datetime.now().strftime('%Y-%m-%d')
    
    filename = f"{safe_name}-{date_str}-rejected.md"
    filepath = Path(vault_path) / "04-decisions" / "rejected-patterns" / filename
    
    # Determine primary rejection reasons
    reasons = []
    if evaluation['scores']['codifiable'] < 4:
        reasons.append('Not codifiable — appears to be infrastructure or too abstract')
    if evaluation['scores']['reusable'] < 3:
        reasons.append('Not reusable — too specific to one workflow')
    if evaluation['scores']['constraint_fit'] < 3:
        reasons.append('Poor constraint fit — violates budget/async requirements')
    if evaluation['scores']['valuable'] < 2:
        reasons.append('Low value — does not solve operational problem')
    
    if not reasons:
        reasons.append(f'Overall score {evaluation["normalized"]}/10 below threshold')
    
    rejection = f"""# Rejected Pattern: {pattern['title']}
Date: {date_str}
Source: [[{Path(pattern_file).stem}]]

## Why Rejected
"""
    for i, reason in enumerate(reasons, 1):
        rejection += f"{i}. {reason}\n"
    
    rejection += f"""
## Scores
- Codifiable: {evaluation['scores']['codifiable']}/10
- Reusable: {evaluation['scores']['reusable']}/10
- Valuable: {evaluation['scores']['valuable']}/10
- Constraint fit: {evaluation['scores']['constraint_fit']}/10
- **Overall: {evaluation['normalized']}/10**

## Pattern Logged For
Future synthesis — may combine with other patterns to create viable skill

## Tags
#rejected #potential-revisit #score-{evaluation['normalized']}
"""
    
    filepath.write_text(rejection)
    return filepath

def main():
    global pattern_file  # for template access
    
    parser = argparse.ArgumentParser(description='Evaluate pattern buildability')
    parser.add_argument('--pattern', required=True, help='Path to pattern markdown file')
    parser.add_argument('--vault', required=True, help='Path to Obsidian vault')
    parser.add_argument('--config', help='Path to config YAML')
    
    args = parser.parse_args()
    
    pattern_file = args.pattern
    vault_path = args.vault
    config_path = args.config or 'config.yaml'
    
    # Load config
    config = load_config(config_path)
    
    # Parse pattern
    try:
        pattern = parse_pattern(pattern_file)
    except Exception as e:
        print(f"Error parsing pattern: {e}", file=sys.stderr)
        return 2
    
    # Evaluate
    evaluation = evaluate_buildability(pattern)
    
    print(f"  Scores: {evaluation['scores']}")
    print(f"  Overall: {evaluation['normalized']}/10")
    
    # Threshold for proposal
    threshold = config['value_criteria'].get('novelty_threshold', 7)
    
    if evaluation['normalized'] >= threshold:
        filepath = generate_proposal(pattern, evaluation, vault_path)
        print(f"  Proposal: {filepath}")
        return 0
    else:
        filepath = generate_rejection(pattern, evaluation, vault_path)
        print(f"  Rejected: {filepath}")
        return 1

if __name__ == '__main__':
    sys.exit(main())
