# Homelab Setup — The Range

Everything in `scenarios/` assumes this range. You already have Wazuh running stock; this doc adds the victim VMs, the endpoint telemetry (Sysmon / auditd) that stock Wazuh doesn't ship, and the safety discipline that keeps a lab from becoming an incident.

---

## Topology

A minimum viable range is four machines on an **isolated lab network** (a host-only / internal virtual network, no bridge to your home LAN unless a scenario explicitly needs egress):

| Role       | Host              | OS                     | Notes                                                        |
|------------|-------------------|------------------------|-------------------------------------------------------------|
| Manager    | `wazuh`           | Ubuntu Server          | Wazuh manager + indexer + dashboard (stock, already up)     |
| Victim-lin | `vic-lin`         | Ubuntu Server 22.04    | Wazuh agent + auditd. Web scenarios add nginx/DVWA.         |
| Victim-win | `vic-win`         | Windows 10/11 or Srv   | Wazuh agent + Sysmon. Non-domain is fine to start.          |
| Attacker   | `kali`            | Kali / Parrot          | No agent. Your foothold and toolbox.                        |

Optional later: a second Windows box + a domain controller for lateral-movement scenarios (S08), and a tiny Linux box running an LLM app for S10.

**IP convention used in the scenarios:** attacker `10.10.10.5`, `vic-lin` `10.10.10.20`, `vic-win` `10.10.10.30`, `wazuh` `10.10.10.10`. Adjust to your subnet; the dealer randomizes source IPs anyway.

---

## Telemetry you must add (stock Wazuh isn't enough)

Stock Wazuh reads syslog/auth and does FIM, which covers the Tier-1 Linux scenarios. The interesting scenarios need endpoint telemetry:

### Linux — auditd
```bash
sudo apt install -y auditd audispd-plugins
# A starter ruleset; scenarios reference these keys.
sudo tee /etc/audit/rules.d/lab.rules >/dev/null <<'RULES'
-a always,exit -F arch=b64 -S execve -k exec
-w /etc/passwd -p wa -k identity
-w /etc/sudoers -p wa -k identity
-w /etc/crontab -p wa -k persistence
-w /etc/systemd/system -p wa -k persistence
-a always,exit -F arch=b64 -F euid=0 -S setuid -k privesc
RULES
sudo augenrules --load && sudo systemctl restart auditd
```
Point the Wazuh agent at auditd by ensuring `<localfile>` for `audit` (JSON via `audisp-json`, or read `/var/log/audit/audit.log` with `audit` log_format) in `/var/ossec/etc/ossec.conf`, then restart the agent.

### Windows — Sysmon
Install Sysmon with a maintained config (SwiftOnSecurity or Olaf Hartong's `sysmonconfig`), then point Wazuh at the Sysmon channel:
```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```
Also enable **PowerShell Script Block Logging** (Event 4104) and **Process Creation auditing with command line** (Event 4688) via Group Policy / local policy — several scenarios read these.

### Where each scenario's telemetry lands
Every scenario file has a **"What telemetry this generates"** section naming the exact log source, Wazuh location, and the fields that matter. Learn to read the raw source *and* the Wazuh alert — the gap between them is where detections get written.

---

## Snapshot & revert discipline (non-negotiable)

1. **Clean baseline snapshot** of every victim VM *before* any scenario. Name it `baseline`.
2. Run the scenario.
3. Investigate from the telemetry, not by poking the live box (poking the live box teaches you nothing about detection).
4. **Revert to `baseline`.** Every time. A dirty victim contaminates the next case's ground truth.
5. Snapshots are cheap; a lab that's slowly accumulating half-cleaned attacks is worthless.

---

## Safety rules (this is the "One Wall" for the lab)

- **Isolated network by default.** Victims reach the attacker and the manager, nothing else. Give a scenario internet egress only when it explicitly calls for it, and revert immediately after.
- **Nothing leaves the lab.** No attacks, scans, or payloads pointed at anything you don't own. The whole point is that this is *yours*.
- **Live malware (S-graduate only) = no egress, disposable VM, snapshot, and a hard revert.** Never on `vic-win`/`vic-lin` baselines you reuse — spin a throwaway.
- **Attack tooling stays in the lab.** Kali's toolbox, Atomic Red Team, C2 frameworks — all fine here, all authorized because you own the range. None of it points outward.
- **Credentials are fake.** Never seed the lab with real passwords, tokens, or data you use anywhere else.
- **Ground truth stays sealed** until the verdict is written (`lab/.groundtruth/`, git-ignored). That's an integrity rule, not a safety one, but it's just as load-bearing for this practice.

---

## What gets committed to GitHub

- `scenarios/*.md` — the labs (public, reproducible, portfolio).
- `cases/YYYY-MM-DD.md` — your daily investigations (public wall).
- `lab/*.md`, `lab/dealer.sh`, `lab/rules/*` — setup and tooling.
- **Never:** `lab/.groundtruth/`, raw captures with real personal data, anything with a real credential. The `.gitignore` seals the ground-truth directory; keep it that way.
