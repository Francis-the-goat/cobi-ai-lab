# Intro to Large Language Models (1hr Talk)
**Source:** YouTube — Andrej Karpathy  
**Date:** 2023-11-13  
**Type:** Video (Educational)  
**Tier:** 1 (Core Curriculum)

---

## The Core Idea

LLMs are next-token prediction machines trained on internet text. They compress human knowledge into weights and can be conditioned (prompted) to perform tasks they weren't explicitly trained for.

---

## Why It Matters for Cobi

Understanding LLMs at this level lets you:
- Debug agent failures (is it the model or the prompt?)
- Choose right model for task (latency vs capability tradeoffs)
- Build better prompting strategies
- Explain to clients how this actually works (builds trust)

---

## Knowledge Extraction

### Mental Model: "LLM as a Dreaming Brain"
Karpathy describes LLMs as dreaming — they hallucinate because they're not grounded, just predicting patterns. This helps me understand:
- Why RAG is necessary (ground the dream in facts)
- Why agents need tool use (let them check reality)
- Why prompting matters (steer the dream)

### Technical Pattern: Tokenization → Transformer → Sampling
The full pipeline:
1. **Tokenization** — Text → numbers (40K vocab)
2. **Transformer** — Process with attention mechanism
3. **Sampling** — Generate next token (temperature controls randomness)

**For my work:**
- Token counting = cost estimation
- Temperature = creativity vs reliability dial
- Context window = working memory limit

### Tacit Knowledge
- "Pretraining is the easy part, RLHF is the secret sauce" — OpenAI's real moat isn't model size, it's alignment
- He emphasizes that smaller models are surprisingly capable with good prompting
- The "system 1 vs system 2" analogy — LLMs are fast intuitive thinking, need to add slow deliberate thinking via agents

### Market/Timing Context
- This talk was Nov 2023 — pre-GPT-4 turbo, pre-Claude 3
- Models are getting faster and cheaper (his prediction held)
- Local models becoming viable for many use cases

---

## Key Quotes

> "LLMs are the kernel of a new operating system."

> "Pretraining is the computational phase, but the post-training phase is where the magic happens."

> "The context window is the working memory of the model."

---

## Connections

- Connects to **swyx's** "LLMs are platforms not products"
- Builds on **Nate's** "sell outcomes not AI" — LLM is the mechanism, not the value
- Contradicts hype about AGI timelines — he's conservative/practical

---

## Exercises for Mastery

### Immediate (This Week)
- [x] Watch full video with notes
- [ ] Build a token counter tool (estimate costs)
- [ ] Experiment with temperature settings in Claude

### Implementation (This Month)
- [ ] Implement basic RAG system (ground the "dream")
- [ ] Build prompt evaluation framework
- [ ] Test local model vs API for specific task

### Teaching (Solidify)
- [ ] Write thread: "What I learned from Karpathy's 1hr LLM talk"
- [ ] Explain to non-technical friend how LLMs work

---

## Mastery Checklist

- [x] Can explain to beginner (did this with roommate)
- [ ] Can implement tokenizer from scratch (doable but haven't)
- [x] Can adapt: Used temperature knowledge to tune agent responses
- [ ] Can teach: Thread drafted but not published

---

## Related

- Video: https://www.youtube.com/watch?v=zjkBMFhNj_g
- Notes: https://karpathy.ai/zero-to-hero.html
- Next: Watch "Let's build GPT" (implementation)
