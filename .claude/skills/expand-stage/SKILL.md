---
name: expand-stage
description: Expand one Learning-Track stage (A1..A5, I1..I6) into a targeted learning/<ID>.md file with verified material, hands-on, and a self-test. Use when the user asks to branch out, expand, or lay out a stage in full.
---

# Expand a Learning-Track stage

The user keeps a study map in `learning/Learning-Track.md` (two lanes: A = AI security, I = identity). When they reach a stage, they want it expanded into a single file, `learning/<ID>.md`, that lays the whole stage out in front of them. This skill is that procedure. Run it for exactly the stage the user names.

## Procedure

1. **Read the stage.** Open `learning/Learning-Track.md` and read the named stage in full, plus the ordering rules and the stage's checkpoint. Also read `learning/README.md` and one existing stage file (`learning/A1.md` or `learning/I1.md`) so the new file matches the format and voice.
2. **Verify every resource before writing it down.** Use WebSearch (and WebFetch where a URL needs confirming) to check that each item in the stage still exists, is at the URL you give, and whether it is free or paid. Check for anything newer or better than what the track lists, but do not replace the track's picks without saying so in the file. Never list a resource you did not verify this session. Record the length of videos and rough reading time.
3. **Write `learning/<ID>.md`** using the template below. Voice: instructions to self, second person, the same as the track. No em-dashes. No calendar dates or deadlines. Mark every item **shift time** (browser or video, interruptible, work first) or **home time** (keyboard, building, anything that needs focus). Say explicitly what is free and what costs money.
4. **Copy the checkpoint verbatim from the track**, then expand each item into "what a passing answer sounds like." That is the shape of a good answer, not a script to memorize.
5. **Add a link back.** Under the stage's header in `learning/Learning-Track.md`, add one italic line: `*Expanded: \`learning/<ID>.md\`*`. Add a row to the table in `learning/README.md`.
6. **Do not touch anything else.** Not the case files, not the scenarios, not the checkpoint wording. If the stage in the track looks wrong or out of date, say so to the user rather than silently changing it.
7. **Report back** in a few lines: what the file contains, anything you could not verify, and anything you recommend changing in the track.

## Template

```markdown
# Stage <ID>: <title from the track>

*Expanded from `learning/Learning-Track.md`. The stage is done when the checkpoint passes out loud, cold. Everything below exists to get you there. <Where the user currently is, if known.>*

---

## The checkpoint, and what passing sounds like
Numbered list. Each item: **the checkpoint phrase**, then one to three sentences on what a passing answer contains.

---

## Why this stage matters for a SOC analyst
Two to four sentences tying the stage to the job, the homelab, or a later stage.

---

## The path, in order
### N. <Resource or activity>. (<author>, <length>, <shift time | home time>, <free | paid>)
One or two lines on what it is and where to find it (plain URL or site name, no tracking links).
**Extract:** which checkpoint items this covers and what to be able to say afterward.

### Optional, only if hungry (home time)
Deeper material, clearly marked optional.

### Reference, not reading
Specs, RFCs, books to keep open rather than read through.

---

## Self-test (say these cold)
The checkpoint items, plus four to seven scenario questions phrased the way they would come up at work or in the lab.

## Done when
One or two sentences: the passing condition, then what to mark in `learning/Learning-Track.md` and which stage opens next.
```

## Conventions that must hold

- Free, browser-based, interruptible material is preferred for shift time; anything requiring a keyboard or focus is home time.
- Hands-on always uses fake data and fake credentials, in the lab or a throwaway account. Never suggest touching the work tenant, the work AWS account, or a real token.
- Keep the two-repo boundary: these files are private playbook material and never go to the public `casefiles` repo.
- Prefer primary sources (the spec, the author's own site, the official docs) over summaries of them.
