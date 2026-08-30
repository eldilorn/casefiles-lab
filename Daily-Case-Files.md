# Daily Case Files: The Practice

*The spine. One investigation, one file, every morning before work. This is the streak, and everything else in the system feeds it or rides on it. Rules live in One Wall. This file covers what a rep actually is.*

*As of 2026-08-30 the source changed: no more grading other people's answer keys. You build the attack in your own homelab, monitor it with Wazuh, and investigate the telemetry you generated. The wall stops being a scrapbook of downloaded pcaps and becomes a lab notebook: attacks you ran, detections you wrote, and verdicts you reached on ground truth you own.*

---

## Why the change

Public exercises (malware-traffic-analysis, LetsDefend, CyberDefenders) are someone else's incident, frozen. You investigate toward a key that already exists. That's real practice, but it caps out: you never own the ground truth, you can't tune a detection against it, and every analyst on earth has the same files in their "portfolio."

A homelab flips it. You own the whole loop: **attack → telemetry → detection → investigation → verdict**. The scenario is yours, the Wazuh rule you write is yours, the pcap is yours, and no one else has run exactly your randomized variant. That's a portfolio that reads as *"I can build detections,"* not *"I finished a course."* And it feeds the Learning Track directly: Stage 5 asks you to build a detection for an AI attack in a homelab, which is just a case file with a fancier scenario.

---

## The rep

Pull one scenario. Run it (or better, have already run it). Investigate the telemetry cold. Write it up. Commit. Push.

**The template (same seven headings every day, the spine never changes):**

```
# YYYY-MM-DD — [title]
## The question
## Indicator / subject
## What I did (pivots/tools, in order)
## What I found
## Verdict & confidence
## One thing I learned
## Tomorrow's first move
```

Full template with homelab prompts: `cases/TEMPLATE.md` in the repo.

**Timing:** morning, before the shift. 15 minutes minimum, 45 maximum, hard stop. The staging happens the night before, but staging is now a lab action, not a copy-paste. See below.

**Completion:** committed means complete. "Inconclusive, ran out of time, next pivot would be X" counts fully. A verdict you can't reach is still a case file, so write why you can't reach it. If you couldn't tell whether the attack succeeded from the logs alone, **that is the finding**: it means your detection has a blind spot, and naming the blind spot is the rep.

---

## The staging loop (this replaces "paste in the indicator")

Morning-you never decides and never runs attacks against a clock. **Evening-you, or the dealer, seeds the telemetry, and morning-you investigates it blind.** Three ways to stage, in order of preference:

1. **The dealer (best).** Run `lab/dealer.sh` the night before. It picks a random scenario, randomizes the parameters (source IP, usernames, timing, whether the attack succeeds), fires some benign noise alongside, executes it against the lab, and writes the ground truth to a **sealed** file you don't open (`lab/.groundtruth/`, git-ignored). Morning-you sees only Wazuh alerts and logs, the same as a real shift, and grades against the sealed file after writing the verdict.
2. **Batch and forget.** On a weekend, run five or six scenarios in one sitting with the dealer, sealed. Investigate them across the week. By Wednesday you've forgotten which fired when, so the timeline reconstruction is real again.
3. **Manual, cold-enough.** Pick a scenario, run it with randomized params yourself, then don't look at the answer section. This is the weakest option, since you know the family, but the specifics (did it succeed? which account? what time? was there noise?) are still yours to reconstruct.

**The cold problem, stated plainly:** the risk of self-authored cases is that you already know the answer. The whole staging design exists to break that. If you can run a scenario and immediately narrate exactly what the logs will say, you didn't stage it hard enough, so turn up the randomization, add noise, or let it sit a few days.

---

## Every rep still starts with a question

A bare alert is an answer with no question. A case file starts with something genuinely unresolved: *Did this brute force succeed? Is this PowerShell benign admin work or a download cradle? Which host did the attacker touch first? Did anything leave the network?* If the sealed scenario fired and you can't yet answer "did it work," you have your question for free.

---

## Raw material (priority order, homelab-first)

1. **The scenario library (`scenarios/`).** Ten runnable, MITRE-mapped attack scenarios on a difficulty ladder, from SSH brute force to prompt-injection exfil. Each is a self-contained lab: story, setup, exact run commands, cleanup, and where the telemetry lands. This is day-one material and the core of the repo.
2. **The dealer, on random.** Once the library feels familiar, let `dealer.sh` choose. Not knowing the scenario going in is the closest thing to a real alert.
3. **Your own scenarios.** When a technique catches your eye (something from an ATT&CK page, a DFIR Report section, a CVE writeup) rebuild it as a new file in `scenarios/` using the template. Authoring the attack teaches as much as investigating it. This is how the library grows past ten.
4. **Learning-Track crossovers (`Stage 4–5`).** A Gandalf solve, a PortSwigger LLM lab, or an injection against your own homelab app. Each is a legitimate daily rep, and several belong in `scenarios/` as reproducible labs (see S10).
5. **The DFIR Report / CISA advisories, rebuilt in-lab.** Read one section, pick one technique, and reproduce it in the homelab instead of just pivoting on their IOCs. Your file is the detection you wrote against your own reproduction, not their indicators.
6. **Real feeds (ThreatFox · URLhaus · OpenPhish), graduate material.** Detonate a live sample in an **isolated, no-egress** lab VM and hunt the telemetry. Only once your lab hygiene (snapshots, network isolation, revert discipline) is second nature. This isn't day-one material, which is why it's last. Lab safety rules: `lab/SETUP.md`.

*Public exercises aren't banned. If you want a change of pace, malware-traffic-analysis is still excellent. They're just no longer the spine.*

---

## The pivot toolkit (homelab edition)

Inside the lab: **Wazuh** (alerts, the archives, the rule set) · **Sysmon** (Windows process/network/registry telemetry) · **auditd** (Linux syscalls, execve, file access) · **the raw logs** on each host (`/var/log/auth.log`, access logs, `journalctl`, Windows Event Logs) · **pcap** from a span/tap or `tcpdump` on the victim.

Outside the lab, when a scenario borrows a real indicator: VirusTotal · urlscan.io · Shodan/Censys · WHOIS + passive DNS · AnyRun. Two or three pivots done carefully beat six done shallow, same rule as always.

**New muscle:** every case can end in a **detection artifact**: a tuned Wazuh rule, a Sigma rule, or a hunting query. Optional per day, but a case file that ships a working rule is worth three that don't. See the optional `## Detection` addendum in the template.

---

## Cadence markers

- **Every 30 files → one roll-up.** Patterns, the best case, how your process changed, and (new) the detections you shipped and what they'd catch in production. The roll-up is the Riddles in the Dark post. (Distribution rules: One Wall.)
- **File 90 → ideas.md unlocks.** One queued project may start, alongside the daily file, never instead of it.
- **Every ~30 files, re-read One Wall.** Five minutes. You drift from the rulebook slowly, and the re-read is the correction.
- **Every ~30 files, add or retire one scenario.** The library should grow with you. Retire what's become trivial, and add one that scares you a little.

---

## Rep variants (all count)

- **The standard:** one scenario, run and investigated end to end.
- **The blind draw:** the dealer picked it, and you don't know the family until the logs tell you. The hardest and most valuable variant.
- **The detection rep:** no new attack. Take a past case's telemetry and write the rule that would have caught it, then test that the rule fires. Pure detection engineering. Counts fully.
- **The learning crossover:** a Learning-Track concept in your own words, or an AI-security lab (S10-style). Optional, never required.
- **The recovery rep:** three sentences after a missed day. Exists so the streak survives. Never miss twice.
- **The deep case:** a multi-day investigation, a full intrusion chain across several scenarios (recon → foothold → privesc → lateral → exfil). Each day's file is that day's pivots and tomorrow's first move. One case spread across several files.

---

## What this is building

Ninety dated investigations against ground truth you authored, each potentially shipping a detection, is a portfolio no cert and no course-completion matches, because no one else ran your randomized variants or wrote your rules. Three hundred is a detection engineer emerging from a SOC analyst. The repo is the record, and today adds one file to it. Go seed the lab, or open what the dealer left you.
