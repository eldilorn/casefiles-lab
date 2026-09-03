# Learning Track: AI Security and Identity

*The parallel track. No dates, no daily quota. This runs during slow shift time and whenever you want more. Progress is measured by checkpoints, not calendar. The daily case file never depends on this track. This track feeds it ideas.*

*As of 2026-09-03 the track has two lanes. Lane A is AI security, unchanged. Lane B is identity, new. They run side by side and converge at the end on one problem: what an agent is allowed to do, on whose behalf, and how you'd know when that broke. The bet behind Lane B, in one paragraph: identity is already the control plane of every environment you'll defend, and agents multiply the problem. An agent with broad standing permissions is a confused deputy waiting for an injection; scope is the containment. Nobody has settled how agent identity should work yet, which is exactly why a practitioner who understands both the identity primitives and how agents actually run is rare. Okta at work is the on-ramp. The homelab is where it becomes real.*

**The one hard rule:** work first. Queue empty, alerts handled, then this. The moment an alert lands, this waits. Slow-shift learning stays a privilege by keeping the job visibly handled. Employer-provided Okta training is the most defensible slow-shift use of time there is, and it still waits for an alert.

**The accountability rule:** no written notes required, but a stage is not done until you pass its checkpoint out loud, cold. Say it to a person, or to your phone's camera. If it comes out shaky, the stage isn't done. This replaces the write-ups, and it's the only thing standing between "watched it" and "learned it."

**The clean-room rule applies here too:** anything learned about the work tenant stays at work. Nothing tenant-specific, no real policy names, no real app integrations, ever leaves. Everything published comes from the homelab IdP and the lab agent, generalized. (Full rule: `documentation/One-Wall.md`.)

---

## How the two lanes fit together

```
Lane A (AI security)              Lane B (identity)
A1  what an LLM is                I1  the primitives (OAuth, OIDC, SAML, SCIM, tokens)
A2  build a tiny agent            I2  Okta as an operator (work trainings, shift time)
A3  the attack surface            I3  AWS and Active Directory (cloud + on-prem identity)
A4  attack things                 I4  authorization models and policy-as-code
A5  make it real                  I5  identity threat detection (lab IdP, ATT&CK)
        \                         I6  agent identity
         \                            /
          A5 + I6: the agent gets an identity, then you attack it
```

**Ordering rules:**
- A1 and I1 both start now. Neither waits on the other.
- I2 is shift-time material and runs whenever the Okta trainings are available. It has no prerequisite.
- I3 (AWS and Active Directory) starts any time after I1. The AWS half needs only a throwaway cloud account; the AD half wants the planned domain controller (Minas Morgul).
- I4 wants the Stage A2 agent built, because you write the policy for a real thing.
- I5 wants the lab IdP standing (a small VM, see `documentation/LabArchitecture.md`).
- The merge (A5 + I6) wants A2, A3, I4, and I5 passed. Don't start it early. It's the deliverable everything else exists for.
- The order rule from before stands inside each lane: don't advance past an unpassed checkpoint.

---

## Lane A: AI security

### Stage A1: What an LLM actually is
*Expanded: `learning/A1.md`*

1. ~~Karpathy, Intro to Large Language Models~~ ✅
2. Karpathy, *Deep Dive into LLMs like ChatGPT* (~3 hr, 1.25x) ← **you are mid-video here**
3. Optional: 3Blue1Brown transformer series for visual intuition.

**Checkpoint, say all seven, cold:** what a token is · what the context window physically is · why the model just predicts the next token · base vs. instruction-tuned · what temperature does · what a system prompt is **and why it is not a privileged security boundary** · why hallucination is structural, not a bug. The last two matter most.

### Stage A2: How LLMs become agents
1. **Build a tiny agent:** prompt → model requests a tool → your code runs it → result feeds back → repeat. Two tools (read a file, run a command). AI can help write it, but you go line by line until you own every part. *Note: the build itself needs keyboard time, so evenings or weekends, not shift time. The reading fits shifts, the building doesn't.* Build it plainly now. It gets its own identity in I6, so don't over-engineer auth on the first pass; just make sure every tool call is logged with what asked for it.
2. Anthropic's *Building Effective Agents*.
3. A tiny RAG over your own notes, to feel why retrieved content is untrusted input.
4. MCP intro docs, then wire up one server. Read the authorization section of the MCP spec while you're there; it comes back in I6.

**Checkpoint:** sketch an agentic app's data flow on paper, cold, and point to every place untrusted text enters context: user input, retrieved docs, tool results, memory. That sketch is Stage A3's attack surface, and in I6 you'll add a second layer to it: whose credentials each arrow carries.

### Stage A3: The attack surface
Frameworks in order: **OWASP Top 10 for LLM Apps** → **OWASP Agentic Top 10** → **MITRE ATLAS** (reference, don't memorize, and it'll feel native to a SOC brain).

Attack classes to actually understand: direct injection · **indirect injection** (payloads hidden in content the AI reads, which is where real incidents live) · **the lethal trifecta** (private data + untrusted content + exfil path; any two is survivable, all three is a breach waiting to happen) · memory poisoning · excessive agency · data/model poisoning.

Note for later: "excessive agency" is an identity problem wearing an AI label. The fix is scope, and scope is Lane B.

Follow along: Simon Willison (simonwillison.net) · Johann Rehberger (embracethered.com). Perfect slow-shift reading.

**Checkpoint:** given any AI feature ("a copilot that summarizes customer emails"), rattle off five concrete attacks and mitigations, mapped to OWASP/ATLAS, cold.

### Stage A4: Attack things (hands-on, runs alongside A3)
- **Lakera Gandalf:** beat every level. Browser-based, fits a slow shift.
- **PortSwigger Web LLM attacks labs:** free, structured. Browser-based.
- Self-hosted (home time): ai-goat · Microsoft AI-Red-Teaming-Playground-Labs.
- Ollama + a toy app you build, then inject/jailbreak your own creation. Attacking what you built teaches the most. (Home time.)

**Checkpoint:** PortSwigger LLM labs cleared, and at least one attack reproduced end to end that you could explain to a stranger.

### Stage A5: Make it real (merges with I6)
Threat-model a real AI deployment (homelab). Build a **detection** for an AI attack, leaning defensive, since that's your strength and the field's biggest gap. Publish work someone else could learn from. (HTB AI Red Teamer path: optional, only if still hungry.)

As of the identity lane, the deployment you threat-model is the agent from A2 running under its own scoped identity from I6, and the attack is S10 run against it. The full merge is written under I6 below.

**Checkpoint:** one published piece of AI-security work someone else could learn from, and a clear sense of your lane.

---

## Lane B: Identity

### Stage I1: The primitives
*Expanded: `learning/I1.md`*

Learn the protocols cold, because everything after this is built on them and the work tenant will make more sense once you can see the flows underneath the admin console.

1. **OAuth 2.0 / 2.1.** Authorization code with PKCE (the one that matters), client credentials (how machines and agents get tokens), refresh tokens, scopes, and what a scope does and doesn't promise. Aaron Parecki's *OAuth 2.0 Simplified* is free online and the right first read; oauth.net for the spec map. *OAuth 2 in Action* (Richer and Sanso) if you want the deep version.
2. **OIDC.** ID token vs. access token, and why confusing them is a real bug class. Authentication is not authorization; say it until it's reflex.
3. **SAML.** The assertion flow, why it still runs half of enterprise SSO, and the classic failure modes (signature wrapping, unsigned assertions).
4. **SCIM.** Provisioning and deprovisioning. This is where lifecycle mistakes leave standing access behind.
5. **Tokens and delegation.** JWT anatomy (header, claims, signature, the alg pitfalls). **RFC 8693 token exchange** and on-behalf-of flows: how one identity acts for another with narrower scope. This is the primitive agent delegation will most likely be built on, so learn it now.
6. **Workload identity.** SPIFFE/SPIRE as the "identity for things that aren't people" idea. Read the overview, don't build it yet.

**Checkpoint, cold:** draw authorization-code-plus-PKCE on paper with every hop labeled · explain ID token vs. access token · define a scope and name two things a scope cannot protect you from · explain why a long-lived static API token is the same problem as a shared password · describe token exchange in one sentence and name the case it exists for.

### Stage I2: Okta as an operator (the shift-time lane)
You have Okta training at work. Use it during slow shifts, in this order of value. The goal is the admin side, not just the logs: knowing where every standing credential in a tenant lives is the skill.

1. **The Okta certification path** (Certified Professional, then Administrator). Whatever the work trainings cover, take them all; the cert itself is optional unless work pays.
2. **The System Log**, deeply. Learn the event types for the login chain (MFA challenge, factor enrollment, session start, session refresh, new device, policy evaluation, admin actions, API token creation, app grants). You'll write detections against this.
3. **App integrations.** OIDC and SAML apps, OAuth clients and their secrets, API service integrations, and what consent looks like from the tenant side. Every one of these is a credential.
4. **Policies.** Global session policy, authentication policies per app, MFA enrollment, device trust, network zones. Understand what an attacker gets past if each one is misconfigured.
5. **Lifecycle.** SCIM provisioning, group rules, deprovisioning, and what stays behind when it fails.
6. **Workflows and the API.** Enough to automate a detection response later.

**Checkpoint, cold:** narrate a suspicious login chain (push fatigue → session hijack → new device → privileged group add) as the sequence of System Log events it produces, and name the detection for each step · list every place a standing credential lives in a tenant (API tokens, OAuth client secrets, service accounts, SCIM tokens, agent tokens) and how you'd inventory them. Say it with the lab IdP in mind, never a real tenant.

### Stage I3: AWS and Active Directory (identity everywhere)
The primitives and Okta cover identity as a protocol and as a SaaS console. This stage covers identity where the breaches actually happen: your cloud and your directory. AWS first, because it is your work environment and where you have live CloudTrail and GuardDuty to learn against. Active Directory second, because it is the on-prem identity gap S07 and S08 already brush against, and it runs on the domain controller you have planned (Minas Morgul).

**Part 1: AWS (the priority).**
1. **IAM, cold.** Users vs. roles, policies (identity, resource, permission boundaries, SCPs), and STS AssumeRole. Notice AssumeRole is token exchange from I1 in AWS clothing: a role session is a short-lived scoped credential. That one idea is most of cloud identity.
2. **The credential shapes and how they leak.** Long-lived access keys (the thing that ends up in a git repo), instance profiles and the metadata service (IMDS, and how SSRF turns into credential theft), and why IMDSv2 exists.
3. **CloudTrail, read fluently.** Management vs. data events, the event schema, and the fields that matter in an investigation (userIdentity, sourceIPAddress, assumed-role sessions). This is your work log, so the reps pay double.
4. **GuardDuty, and its limits.** The finding families (credential exfiltration, anomalous API calls, IAM anomalies, recon), what it catches for free, and what it misses, so you know where a hand-written detection earns its place. GuardDuty is a floor, not a ceiling.
5. **The attack paths.** IAM privilege escalation through misconfigured policies (read the Rhino Security Labs "AWS IAM privilege escalation" set), role-assumption chains, cross-account trust abuse, and access-key exfil to API calls.

**AWS hands-on, in order of value:**
- **flaws.cloud and flaws2.cloud** (free, browser). Slow-shift material, attacker and defender tracks. Start here.
- **CloudGoat** (Rhino Security Labs). Vulnerable-by-design AWS you deploy in a throwaway account. This is the cloud S10: run the scenario, then hunt it in CloudTrail and GuardDuty. Case-file material.
- **stratus-red-team** (DataDog). Atomic cloud attack emulation mapped to ATT&CK. Fire one technique, confirm what CloudTrail and GuardDuty show. The cloud detection rep.
- **pacu** for exploitation, in the throwaway account only.
- Cert if work pays: AWS Security Specialty. Solutions Architect Associate for fundamentals. Neither is required; the labs teach more.

Use a dedicated throwaway AWS account with a hard billing alarm, never anything touching work. Fake data and fake credentials only, the same clean-room rule as the rest of the range.

**Part 2: Active Directory.**
1. **The primitives.** Kerberos (AS-REQ, TGT, TGS), NTLM, access tokens, logon types, SIDs, and what a domain controller actually is.
2. **The attacks.** Kerberoasting, AS-REP roasting, pass-the-hash, pass-the-ticket, DCSync, golden and silver tickets. The identity half of the intrusions you already run.
3. **The map.** BloodHound and SharpHound to see attack paths the way an attacker does; Rubeus and impacket to run them. Lab only, on Minas Morgul.
4. **The detection.** Windows event IDs 4768 and 4769 (Kerberos), 4624 logon types, 4662 (DCSync), and Sysmon, wired into Wazuh. Which of these fires on each attack, and which stays silent.

Both halves generate case files, and a clean CloudGoat run or AD attack can be authored as a scenario like any other.

**Checkpoint, cold:** explain AssumeRole as token exchange and trace where a leaked access key becomes API calls in CloudTrail · name three GuardDuty finding families and one thing GuardDuty will not catch · walk one AWS IAM privilege-escalation path end to end · explain Kerberoasting and the event it produces · say which single control breaks each path.

### Stage I4: Authorization models and policy-as-code
1. **RBAC vs. ABAC vs. ReBAC.** Where each breaks. Understand why least privilege has to become a property of the *task*, short-lived and scoped, rather than a property of the *role*, standing and broad. That sentence is the whole identity argument for agents.
2. **One policy engine, hands-on.** Pick Cedar or OPA/Rego. Write policies, run them locally, test them. Home time.
3. **Apply it to the A2 agent.** Write the authorization policy for the tiny agent: which tools it may call, on which paths, with what limits, under which caller. Don't wire it in yet (that's I6). Just write it and make the tests pass.

**Checkpoint, cold:** explain per-task scoped tokens vs. a standing role and why the first contains an injection and the second doesn't · write, on paper, a Cedar or Rego policy for the A2 agent that allows reading one directory and denies everything else.

### Stage I5: Identity threat detection (the bridge to the daily practice)
This is where Lane B becomes case files. Identity attacks need a place to run that isn't work, so the range gets a small IdP.

1. **Stand up a lab IdP.** Keycloak or Authentik on a lab VM (planned host in `documentation/LabArchitecture.md`). Wire its logs into Wazuh. Register the A2 agent and one fake "app" against it. Fake users, fake credentials, never real ones.
2. **The attack classes.** MFA fatigue / push bombing · session token theft and replay · OAuth consent phishing and malicious app grants · token and API-key leakage · SCIM and provisioning abuse · privilege escalation through group membership · device-trust bypass · adversary-in-the-middle phishing (evilginx-style, lab only, against the lab IdP only).
3. **Map to ATT&CK:** T1078 Valid Accounts · T1556 Modify Authentication Process · T1550 Use Alternate Authentication Material · T1528 Steal Application Access Token · T1098 Account Manipulation · T1621 MFA Request Generation.
4. **Write the detections.** Wazuh rules over the IdP log for each step of at least two chains. Prove each fires against your own attack.
5. **Author the scenario.** Once an identity attack runs cleanly in the range, it becomes a new file in `scenarios/` using the template (the queued S11). Then it's dealer material and a normal daily rep.

**Checkpoint, cold:** given an IdP log, walk one identity attack chain end to end and name the detection for each step · explain which controls in a tenant would have stopped it at each hop.

### Stage I6: Agent identity (the merge, with A5)
The unsolved problem. Everything above was so this stage has something to stand on.

1. **Read the state of the art, as a survey, not a syllabus:** the MCP authorization spec and its changelog · OAuth token exchange applied to delegation · what Okta and Microsoft are publishing about agent identity · the non-human-identity vendor landscape (read it to understand the market, not to copy it) · the OWASP Agentic Top 10 again, now through an identity lens.
2. **Give the A2 agent its own identity.** Register it as a client on the lab IdP. It gets a short-lived token per task via client credentials or token exchange, scoped to that task only, never your credentials. The I4 policy gates every tool call. Every call logs the full chain: which agent, acting for which user, on which instruction, called what.
3. **Delegation.** Add one sub-agent. The token it receives must be narrower than the parent's. Make the audit trail survive the hop.
4. **Attack it.** Run S10 against the scoped agent. Did scope contain the injection? Which leg of the trifecta did scope cut? Then run an identity attack from I5 against the agent's credentials (leak its token, replay it, grant it an extra scope) and see what the IdP log and Wazuh show. That's the queued S12.
5. **Detect it.** Rules for: a tool call not traceable to a user turn · an agent token used outside its task window · a delegated token wider than its parent · an agent acting on a resource outside its policy. These are the detections almost nobody has written yet.
6. **Publish.** The roll-up is "agent identity in a homelab": the delegation chain, where scope narrowed, where attribution broke, what caught it. Practitioner writing on this barely exists. This is the Stage A5 published piece.

**Checkpoint, cold:** draw user → agent → sub-agent → tool on paper, and at every hop say what scope should narrow and where attribution can break · explain why a scoped agent turns the lethal trifecta into two legs · one published piece someone else could build from.

---

## Follow along (slow-shift reading)

- **AI security:** Simon Willison · Johann Rehberger.
- **Identity:** oauth.net · Aaron Parecki · Okta's security and developer blogs · Microsoft's identity blog. Watch the MCP spec changelog for auth changes.
- **Cloud and AD:** the AWS security docs · Rhino Security Labs blog · flaws.cloud · DataDog's stratus-red-team · SpecterOps (BloodHound) for Active Directory.

---

## How this track touches the daily practice

- **Crossover reps:** when a concept clicks hard, it may become that morning's case file, in your own words. Optional.
- **Stage A4, A5, I5, and I6 work generates real case files:** a Gandalf solve, a PortSwigger lab, an identity attack against the lab IdP, an injection against your own scoped agent. Each is legitimate daily-rep material whenever you choose.
- **New scenarios come out of I5 and I6.** S11 (identity attack against the lab IdP) and S12 (agent token abuse) get authored when they run cleanly, then they're dealer material like any other.
- **Roll-ups can draw from both lanes.** "30 days of investigations, plus I hit the I1 checkpoint: here's what an OAuth scope actually protects, from a SOC analyst" is a strong post. The I6 roll-up is the strongest thing this track can produce.
- **Order rule stands:** don't advance past an unpassed checkpoint. Understanding compounds, speed doesn't.

No calendar. A stage takes as long as it takes. The only failure mode on this track is skipping a checkpoint. The daily streak lives elsewhere and is never at risk from slow learning.
