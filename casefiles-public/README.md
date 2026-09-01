# casefiles

One security investigation a day, written up and pushed. This repo is the wall.

## What this is

Every morning before work I investigate one thing and write it up as a dated markdown file in `cases/`. Each file is a self-contained case: the question I started with, the pivots I made in order, what I found, and a verdict with a confidence level. Then I commit and push. That is the whole practice.

The investigations run against a homelab I own and control. I build an attack in my own range, monitor it with Wazuh, and then investigate the telemetry cold, the way I would on a shift: attack, telemetry, detection, investigation, verdict. Scenarios are randomized and staged ahead of time so I am not narrating an answer I already know. When a case ends in a working detection rule or hunting query, it goes in the file too.

Everything here is generalized. Hosts, accounts, and addresses are lab assets. Raw captures, credentials, and internal detections from anywhere I work never appear here.

## How to read a case

Every case uses the same seven headings, in the same order. `cases/TEMPLATE.md` is the canonical copy.

1. **The question.** What was actually unresolved at the start.
2. **Indicator / subject.** The alert, artifact, or host that kicked it off.
3. **What I did.** Pivots and tools, in the order I ran them, including dead ends.
4. **What I found.** The evidence, stated plainly.
5. **Verdict and confidence.** The call, and how sure I am.
6. **One thing I learned.** A single takeaway.
7. **Tomorrow's first move.** Where the next session starts.

Some cases end with an optional **Detection** section: a tuned Wazuh or Sigma rule, or a hunting query, tested against the attack that produced the telemetry.

Short files are normal. The floor is five sentences and fifteen minutes, the ceiling is forty-five minutes, and "inconclusive, ran out of time, next pivot would be X" is a complete case. A verdict I could not reach from the logs alone is still a finding, because it names a blind spot.

## Cadence

- One case file per day, committed and pushed.
- Every 30 cases, a roll-up: patterns, the most interesting case, how the process changed, and what the detections I shipped would catch in production.

## What is here

- `cases/` holds the daily case files, one per date.
- `cases/TEMPLATE.md` is the template every case follows.
- This README.

Nothing else. The write-ups are mine, written by hand, every day.
