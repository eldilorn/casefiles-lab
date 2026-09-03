# One Wall: The Guideline

*The standing rules for the practice. This document doesn't change day to day. When a decision isn't covered here, the answer is: do today's file. For what specifically to work on right now, see `documentation/Daily-Case-Files.md` (what a rep is) and `scenarios/` (the day's material). This file lives in the private `casefiles-lab` repo with the rest of the playbook.*

---

## The two repos

The practice runs across two repositories, split by audience:

- **`casefiles` (public).** The public wall. It holds only the daily case files (`cases/`) and a light README. This is what employers and readers see: solved investigations, each self-contained.
- **`casefiles-lab` (private).** The playbook. This file, `documentation/Daily-Case-Files.md`, `learning/Learning-Track.md`, `ideas.md`, the `scenarios/`, the `lab/` (dealer, setup, rules), and the sealed ground truth. This is the planning and tooling side, and only I see it.

**The one rule that keeps the split clean:** a public case must stand on its own. Describe the context in prose (for example, "a Windows host ran an encoded PowerShell command overnight") and never link a case to a private scenario file or assume a reader has seen the playbook. The verdict is what the case delivers, and the case doesn't need the scenario to make sense. If a case would read as gibberish to a stranger, it's leaning on the private side and needs rewriting.

---

## The spine: one case file a day, committed and pushed

Every day, one markdown file gets written, **committed, and pushed** to the public `casefiles` repo. That is the entire practice. Not a project, not a plan, not a tool, just one file. The repo is the record, and each day adds one file to it. A file that only exists on your laptop doesn't count. The push is part of the rep, every day, no exceptions.

**Don't leave the decision for the morning.** The night before seeds the work, the morning executes it, and the commit closes it. A good day always ends with a pushed file.

*(The playbook repo gets committed whenever you tune a scenario or edit the plan, not on a daily clock. Only the case file is a daily obligation.)*

**The template.** The same seven-heading spine every day. It's laid out in `documentation/Daily-Case-Files.md`, and the canonical copy with prompts is `cases/TEMPLATE.md` in the public repo. That file is the authority if anything ever drifts; the seven headings are the spine and don't change.

**The completion rule.** Committed and pushed means complete. The rep happens in the morning, before the shift. It's the warm-up for the job. Minimum acceptable file: five sentences, 15 minutes. "Inconclusive, ran out of time, next pivot would be X" counts fully. A good session you didn't write up counts as zero. An unpushed file counts as zero. If a morning blows up, the evening is the recovery window, but it's the fallback, never the plan.

**The night-before rule (now a lab action).** 60 seconds before bed, stage tomorrow. Best case: run `./lab/dealer.sh` from Barad-dûr, which fires a randomized scenario and **seals** the ground truth so morning-you investigates blind, exactly like a real shift. The full staging loop, and the `--dry-run` mode for before the range is built, are in `documentation/Daily-Case-Files.md`. Minimum case: open tomorrow's file with date, title, and the "first move" line filled in. Either way, morning-you never decides what to do. Deciding happens the night before. Morning-you only investigates.

**The ceiling rule.** 45 minutes, hard stop, timer running. Stopping mid-investigation and writing "next pivot: X" is not failure. It's the practice working. The 15-minute rough file is not a degraded version of the practice. It is the practice.

---

## What the daily file is about

The file's subject is a homelab investigation, but the practice never changes. You build the attack in your own range, monitor it with Wazuh, and investigate the telemetry cold: **attack → telemetry → detection → investigation → verdict**, all under the same seven-heading template. `documentation/Daily-Case-Files.md` covers the sourcing in full. The short version:

1. **The scenario library (`scenarios/`).** Ten runnable, MITRE-mapped labs on a difficulty ladder, from SSH brute force up to prompt-injection exfil. This is the day-to-day material.
2. **The dealer, on random.** Once the library is familiar, let `lab/dealer.sh` choose and seal. Not knowing the scenario going in is the closest thing to a real alert.
3. **Your own rebuilds.** A technique from an ATT&CK page, a DFIR Report section, or a CVE, reproduced in-lab as a new scenario file. Authoring the attack teaches as much as investigating it.
4. **The detection artifact.** Any case can end in a working Wazuh/Sigma rule (`lab/rules/`), tested against your own attack. Optional per day, but a case that ships a rule is worth three that don't. (Keep the public write-up self-contained: describe the activity, include the rule, and don't reference the private scenario by name.)

### The parallel track: AI security and identity (feeds the file, never gates it)

The Learning Track runs alongside the daily practice on slow-shift and home time, in two lanes: AI security and identity. It has no daily quota and never puts the streak at risk, but it feeds the file: a concept in your own words is a valid crossover rep, and the hands-on stages (A4, A5, I5, I6) are legitimate daily material. `learning/Learning-Track.md` holds the full stages and checkpoints. The hinges to internalize:

- **What an LLM actually is.** Tokens, context window, next-token prediction, temperature, and why a system prompt is not a privileged security boundary, and why hallucination is structural.
- **The attack surface.** Direct vs. **indirect injection** (payloads hidden in content the AI reads, which is where real incidents live) · **the lethal trifecta** (private data + untrusted content + exfil path; all three together is a breach waiting to happen) · memory poisoning · excessive agency.
- **Identity is the control plane.** Authentication is not authorization. A scope is a task property, short-lived and narrow, not a role property, standing and broad. Every standing credential in a tenant (API tokens, OAuth secrets, service accounts, agent tokens) is a shared password by another name. Okta at work is the on-ramp; the lab IdP is where identity attacks get run and detected.
- **Agent identity is the merge.** An agent with broad permissions is a confused deputy waiting for an injection; scope is the containment. The track ends with the lab agent running under its own scoped identity, S10 run against it, and detections for what nobody has written detections for yet.
- **Make it real.** Threat-model a homelab AI deployment, build a **detection** for an AI attack, and publish it. Scenario **S10** (prompt-injection exfil) is that bridge: an AI attack you run in your own range and catch with your own telemetry. Lean defensive, since that's your strength and the field's biggest gap.

**Order rule stands:** don't advance the track past an unpassed checkpoint. Understanding compounds, speed doesn't. But the daily file never waits on the track. The homelab scenarios are always enough on their own.

---

## The roll-up: Riddles in the Dark

**Every 30 files, write one roll-up.** Patterns you noticed, the most interesting case, how your process changed, and the detections you shipped and what they'd catch in production. **The roll-up is the blog post.** You never sit down to "make content." Content is what 30 days of practice compresses into. (Roll-ups can quote the private scenarios freely. The blog is yours, and only the `casefiles` repo stays cases-only.)

- Format: something hidden → the clues → the solve. Leave the failures in. A riddle isn't interesting if you skip to the answer. And the solve is yours: you built the attack and the detection, so the write-up shows a full loop that a downloaded exercise can't.
- **One series only for the first six months.** Everything else waits.
- Distribution, in order of effort: post it on the blog → one honest LinkedIn post → one Reddit post where it genuinely fits (r/blueteamsec, r/netsec, r/cybersecurity). No threads, no clips, no funnel. Save Hacker News for something that surprises even you.
- Cadence matters most: a roll-up every ~30 files puts you ahead of ~95% of security bloggers within a year.

---

## The queue: ideas.md

One file in this (private) repo. Every new idea (hardware build, tool, video, series, business scheme) gets two sentences there, then the file closes and today's case file gets done. The idea isn't killed, it's queued.

**The 90-file rule.** No new project starts until 90 case files exist. No YouTube until 6–8 roll-ups exist.

**Queued until file 90+, in full:** all hardware/ESP32 builds (evil-twin detector, BLE tracker detector, canary box, threat dashboard, Marauder, TinyML, BadUSB, FIDO2 key) · YouTube · the two-engine reach/depth model · $10 Security Gadget series · Breaking My Own ___ · Can AI Do My Job? · Wazuh-from-scratch series · explainer posts. They're good ideas. They're better at file 90, and "I built a gadget and hunted it in my SIEM" only works once the SIEM half of you is real, which is exactly what the daily homelab reps are building.

---

## Streak protection

1. **Quality inflation** (kills streaks ~day 10): files get good, sessions balloon, then a tired day arrives and you can't imagine doing it badly, so you skip. Fix: the 45-minute ceiling is as mandatory as the 15-minute floor.
2. **The novelty pivot** (~week 3–4): a new idea (a new scenario, a new gadget) will feel more exciting than day 24 of files. That feeling is just the routine getting old, not a reason to switch. Fix: two sentences in ideas.md, close the file, do today's rep.
3. **The lab rabbit hole** (homelab-specific): a broken agent, a Sysmon config that won't parse, a scenario that won't fire. Debugging the range is not a case file. Fix: if the lab fights you past the 45-minute ceiling, the rep becomes a case file about the failure. "Here's what wouldn't fire and why" is a real investigation. The file still ships.
4. **Never miss twice.** One missed day is a data point. Two is the start of quitting. The day-after file can be three sentences. It just has to exist and get pushed.

---

## Two hard rules

**Homelab / clean-room.** Everything published comes from the homelab, generalized. No work data, logs, PHI, internal detections, or anything tied to your employer, ever. Anything borderline goes past your manager first. The range is the clean-room: every attack, payload, and tool stays inside a lab you own and points at nothing you don't. Everything published stays on the safe side of that line. (Lab safety specifics: `lab/SETUP.md`.)

**Job first.** The daily file is the warm-up, not the main event. It exists to make you better at the SOC job, never to compete with it. Give work your real attention. When an alert lands, the lab and the learning track both wait.

---

## Claude Code boundary

Claude Code can touch the code and the range: scaffolding the tiny agent, wiring Wazuh telemetry, authoring scenario files, writing detection rules, debugging the homelab. It never touches the case file. The write-up is the rep. If a tool writes it, you did zero reps and the streak means nothing. The investigation and the sentences are always yours.
