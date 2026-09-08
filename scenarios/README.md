# Scenario Library

These are ten attack scenarios I can run against the homelab range (`lab/SETUP.md`). Each one is self-contained: the story, the setup, the exact commands, cleanup, where the telemetry ends up, and a grading key that stays hidden until I expand it. This library is also **Draghunt's private runner catalog**: Draghunt lays one (or picks blind), fires it, seals the answer key, and pulls the telemetry into a case. I investigate cold, write the case file, then check myself against the debrief.

Every scenario ends in a `<details>` block with the ground truth. I don't open it until my verdict is written. It stays collapsed on GitHub, so these files also work as investigation prompts anyone can try on their own range.

## The ladder

| ID  | Scenario                              | Tier | Primary ATT&CK          | Main telemetry              |
|-----|---------------------------------------|------|-------------------------|-----------------------------|
| S01 | SSH brute force → successful login    | 1    | T1110, T1078            | auth.log / Wazuh sshd rules |
| S02 | Linux privilege escalation (SUID/sudo)| 1    | T1548.001, T1068        | auditd execve/privesc       |
| S03 | Web shell upload on DVWA              | 2    | T1505.003, T1190        | FIM + nginx access log      |
| S04 | Persistence: cron / systemd timer     | 2    | T1053.003, T1053.006    | auditd persistence key      |
| S05 | Malicious PowerShell download cradle  | 2    | T1059.001, T1105        | Sysmon 1/3 + PS 4104        |
| S06 | Living-off-the-land download (LOLBins)| 2    | T1105, T1218            | Sysmon 1 + 4688             |
| S07 | Credential access: LSASS read         | 3    | T1003.001               | Sysmon 10                   |
| S08 | Lateral movement (SSH pivot / RDP)    | 3    | T1021.001, T1021.004    | auth.log + Sysmon 3 + 4624  |
| S09 | Exfiltration over DNS                 | 3    | T1048.003, T1071.004    | pcap + DNS query logs       |
| S10 | Prompt-injection exfil vs homelab LLM | 3    | ATLAS + T1041           | app logs + egress pcap      |

Tier 1 needs only stock Wazuh plus auth logs. Tier 2 needs auditd on Linux or Sysmon on Windows. Tier 3 needs pcap, and S10 also needs a small LLM app. I climb them in order the first time through, then draw blind after that.

## How to run one

1. Snapshot the victims to `baseline` (`lab/SETUP.md`), or let Draghunt reset the target for me (`--reset`).
2. Lay it in Draghunt: **Blind assessment** for a random draw, or a named drill (e.g. `draghunt lay --scenario S05 --fire`). Draghunt randomizes, fires, seals the answer key, and collects the Wazuh alerts. Fallback: run the scenario's commands with randomized params by hand.
3. Investigate from the case events, Wazuh, and the raw logs. Write `cases/YYYY-MM-DD.md`.
4. Submit the report in Draghunt and read the debrief and score to grade myself. (Manual fallback: expand the scenario's `<details>`.)
5. Revert the victims to `baseline` if I didn't have Draghunt reset them.

## Tooling the scenarios lean on

- **Atomic Red Team** (`Invoke-AtomicTest`) for S04–S07. Safe, reversible, ATT&CK-mapped tests. Install it per its docs on the victim; it's the attack library.
- **hydra / ncrack** (S01), **DVWA** (S03), **dnscat2 or iodine** (S09), and a **toy LLM app** I build in Learning-Track Stage 2 (S10).

## Coverage map (fill in as you go)

I tick a technique once I've both run it and shipped a detection for it. The goal is a filled column, not just a filled row.

```
Initial Access   [ ] T1190   [ ] T1110
Execution        [ ] T1059.001
Persistence      [ ] T1053.003  [ ] T1053.006  [ ] T1505.003
Priv Esc         [ ] T1548.001  [ ] T1068
Cred Access      [ ] T1003.001
Lateral Movement [ ] T1021.001  [ ] T1021.004
Exfiltration     [ ] T1048.003  [ ] T1041
```
