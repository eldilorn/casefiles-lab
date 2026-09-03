# The Queue

*Every new idea lands here in two sentences, then the file closes and today's case file gets done. Nothing here starts until 90 case files exist (YouTube waits for 6–8 roll-ups). The idea isn't killed, it's parked. Rules: `documentation/One-Wall.md`.*

## Locked until file 90

**Hardware / ESP32 builds.** Evil-twin detector, BLE tracker detector, canary box, threat dashboard, Marauder, TinyML sensor, BadUSB, FIDO2 key. Each becomes a "built it, then hunted it in my own SIEM" case once the SIEM half of me is real.

**YouTube channel.** Video versions of the roll-ups and builds. Waits for 6–8 written roll-ups so there's a back catalogue before the camera turns on.

**Two-engine reach/depth model.** A content structure with one engine for reach and one for depth. Two sentences here until there's an audience to structure.

**$10 Security Gadget series.** A recurring cheap-build series, one gadget per post. Pairs naturally with the ESP32 queue above.

**"Breaking My Own ___" series.** Attack something I built, then write the detection. S10 is the prototype; the format generalizes to any app or device I make.

**"Can AI Do My Job?" piece.** An honest look at what an LLM can and can't do in a SOC seat, from someone doing both tracks. Strongest after the AI-security Learning Track has real reps behind it.

**Explore Kali Purple** How is it for getting hands-on SOC experience.

**Agent Identity Solution** Small/Mid sized companies deploying agents.
There is no security safeguards in place currently, need to limit scope and find IAM solution for agents so they don't run wild.

## Learning-Track work (not gated by file 90, lands when its stage does)

**S11: identity attack against the lab IdP.** MFA fatigue, token replay, consent-phishing, or provisioning abuse run against Keycloak/Authentik in the range, detected in Wazuh. Authored as a scenario once it runs cleanly (Learning Track, Stage I5).

**S12: agent token abuse.** Leak, replay, or over-scope the lab agent's own credential and see what the IdP log and Wazuh show. The merge stage's scenario (Learning Track, Stage I6).

**"Agent identity in a homelab" roll-up.** The delegation chain, where scope narrowed, where attribution broke, and what caught it. The strongest thing the track can produce; it is a roll-up, not a new project.

## In progress (not queued, already underway)

- Rebuild the homelab onto a Proxmox server and rebuild Wazuh from scratch. Procedure: `Lab-Buildout.md`. Target state: `documentation/LabArchitecture.md`.
