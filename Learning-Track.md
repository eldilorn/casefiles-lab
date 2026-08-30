# Learning Track — AI Security

*The parallel track. No dates, no daily quota — this runs during slow shift time and whenever you want more. Progress is measured by checkpoints, not calendar. The daily case file never depends on this track; this track feeds it ideas.*

**The one hard rule:** work first. Queue empty, alerts handled, then this. The moment an alert lands, this waits. Slow-shift learning stays a privilege by keeping the job visibly handled.

**The accountability rule:** no written notes required — but a stage is not done until you pass its checkpoint *out loud, cold*. Say it to a person, or to your phone's camera. If it comes out shaky, the stage isn't done. This replaces the write-ups; it's the only thing standing between "watched it" and "learned it."

---

## Stage 1 — What an LLM actually is
1. ~~Karpathy — Intro to Large Language Models~~ ✅
2. Karpathy — *Deep Dive into LLMs like ChatGPT* (~3 hr, 1.25x) ← **you are mid-video here**
3. Optional: 3Blue1Brown transformer series for visual intuition.

**Checkpoint — say all seven, cold:** what a token is · what the context window physically is · why the model just predicts the next token · base vs. instruction-tuned · what temperature does · what a system prompt is **and why it is not a privileged security boundary** · why hallucination is structural, not a bug. The last two are the hinge the whole field swings on.

---

## Stage 2 — How LLMs become agents
1. **Build a tiny agent** — prompt → model requests a tool → your code runs it → result feeds back → repeat. Two tools (read a file, run a command). AI can help write it; you go line by line until you own every part. *Note: the build itself needs keyboard time — evenings or weekends, not shift time. The reading fits shifts; the building doesn't.*
2. Anthropic's *Building Effective Agents*.
3. A tiny RAG over your own notes — feel why retrieved content is untrusted input.
4. MCP intro docs; wire up one server.

**Checkpoint:** sketch an agentic app's data flow on paper, cold, and point to every place untrusted text enters context — user input, retrieved docs, tool results, memory. That sketch is Stage 3's attack surface.

---

## Stage 3 — The attack surface
Frameworks in order: **OWASP Top 10 for LLM Apps** → **OWASP Agentic Top 10** → **MITRE ATLAS** (reference, don't memorize — it'll feel native to a SOC brain).

Attack classes to actually understand: direct injection · **indirect injection** (payloads hidden in content the AI reads — where real incidents live) · **the lethal trifecta** (private data + untrusted content + exfil path; any two survivable, all three is a breach waiting) · memory poisoning · excessive agency · data/model poisoning.

Follow along: Simon Willison (simonwillison.net) · Johann Rehberger (embracethered.com). Perfect slow-shift reading.

**Checkpoint:** given any AI feature ("a copilot that summarizes customer emails"), rattle off five concrete attacks and mitigations, mapped to OWASP/ATLAS, cold.

---

## Stage 4 — Attack things (hands-on; runs alongside Stage 3)
- **Lakera Gandalf** — beat every level. Browser-based; fits a slow shift.
- **PortSwigger Web LLM attacks labs** — free, structured. Browser-based.
- Self-hosted (home time): ai-goat · Microsoft AI-Red-Teaming-Playground-Labs.
- Ollama + a toy app you build, then inject/jailbreak your own creation — attacking what you built teaches the most. (Home time.)

**Checkpoint:** PortSwigger LLM labs cleared, and at least one attack reproduced end to end that you could explain to a stranger.

---

## Stage 5 — Make it real
Threat-model a real AI deployment (homelab). Build a **detection** for an AI attack — lean defensive; that's your strength and the field's biggest gap. Publish work someone else could learn from. (HTB AI Red Teamer path: optional, only if still hungry.)

**Checkpoint:** one published piece of AI-security work someone else could learn from, and a clear sense of your lane.

---

## How this track touches the daily practice

- **Crossover reps:** when a concept clicks hard, it may become that morning's case file, in your own words. Optional.
- **Stage 4–5 work generates real case files:** a Gandalf solve, a PortSwigger lab, an injection against your own app — each is legitimate daily-rep material whenever you choose.
- **Roll-ups can draw from both tracks.** "30 days of investigations, plus I hit the Stage 1 checkpoint — here's what an LLM actually is, from a SOC analyst" is a strong post.
- **Order rule stands:** don't advance past an unpassed checkpoint. Understanding compounds; speed doesn't.

No calendar. A stage takes as long as it takes. The only failure mode on this track is skipping a checkpoint — the daily streak lives elsewhere and is never at risk from slow learning.
