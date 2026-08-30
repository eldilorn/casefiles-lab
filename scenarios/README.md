# Scenario Library

Ten runnable attack scenarios for the homelab range (`lab/SETUP.md`). Each is a self-contained lab: a story, the setup, the exact commands to run it, cleanup, where the telemetry lands, and — hidden until you expand it — the grading key. You run one (or let `lab/dealer.sh` pick), investigate the Wazuh telemetry cold, write the case file, then check yourself against the key.

**Every scenario ends in a `<details>` block holding the ground truth.** Don't open it until your verdict is written. On GitHub it stays collapsed — so these files double as investigation prompts anyone can try against their own range.

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

Tier 1 needs only stock Wazuh + auth logs. Tier 2 needs auditd (Linux) or Sysmon (Windows). Tier 3 needs pcap and, for S10, a small LLM app. Climb in order the first time through; after that, blind draws.

## How to run one

1. Snapshot victims to `baseline` (`lab/SETUP.md`).
2. Either run the scenario's commands with randomized params, **or** `./lab/dealer.sh --scenario S05` to have it run + seal the ground truth.
3. Investigate from Wazuh + raw logs. Write `cases/YYYY-MM-DD.md`.
4. Expand the scenario's `<details>` (or read `lab/.groundtruth/`) and grade yourself.
5. Revert victims to `baseline`.

## Tooling the scenarios lean on

- **Atomic Red Team** (`Invoke-AtomicTest`) for S04–S07 — safe, reversible, ATT&CK-mapped tests. Install per its docs on the victim; it's your attack library.
- **hydra / ncrack** (S01), **DVWA** (S03), **dnscat2 or iodine** (S09), a **toy LLM app** you build in Learning-Track Stage 2 (S10).

## Coverage map (fill in as you go)

Tick a technique when you've both *run* it and *shipped a detection* for it. The goal is a filled column, not just a filled row.

```
Initial Access   [ ] T1190   [ ] T1110
Execution        [ ] T1059.001
Persistence      [ ] T1053.003  [ ] T1053.006  [ ] T1505.003
Priv Esc         [ ] T1548.001  [ ] T1068
Cred Access      [ ] T1003.001
Lateral Movement [ ] T1021.001  [ ] T1021.004
Exfiltration     [ ] T1048.003  [ ] T1041
```
