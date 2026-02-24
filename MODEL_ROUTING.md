# Model Routing Configuration

This file defines when to use which model for optimal cost/performance.

## Model Stack

| Model | Alias | Cost | Best For | Avoid For |
|-------|-------|------|----------|-----------|
| **Llama 3.2 3B** | `Local` | FREE | Simple Q&A, summaries, formatting, research, basic analysis | Complex reasoning, creative writing, coding |
| **DeepSeek Coder 1.3B** | `LocalCode` | FREE | Code tasks, technical explanations, debugging simple code | Non-code tasks, complex architecture |
| **Kimi K2.5** | `Kimi` | API $ | Complex reasoning, creative content, coding, analysis, anything important | Simple tasks that local models handle |

## Routing Rules

### ALWAYS use Local (free) for:
- Simple Q&A and factual lookups
- Summarizing articles/content
- Formatting/transforming text
- Research compilation
- Brainstorming lists
- Simple explanations
- Routine tasks

### ALWAYS use LocalCode (free) for:
- Code generation (simple scripts)
- Code explanation
- Debugging straightforward errors
- Technical documentation
- Regex patterns
- Shell commands

### ALWAYS use Kimi (paid) for:
- Complex multi-step reasoning
- Creative writing/content creation
- Business strategy
- Client-facing content
- Important decisions
- Novel problems
- When quality > cost

## Usage

**Override routing manually:**
```bash
# Force local model
openclaw agent --model Local "simple question"

# Force Kimi for important task
openclaw agent --model Kimi "write client proposal"

# Force code model
openclaw agent --model LocalCode "debug this Python script"
```

**I'll route automatically based on task characteristics.**
