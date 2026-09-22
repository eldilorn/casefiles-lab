# SecOps Lab

A reference for my home security lab. This grows as I add VMs, containers, and services. Palantir is moving from VMware on Windows Home to Proxmox; the diagram and tables below reflect the target state. To build it, follow Lab-Buildout.md. This document supersedes the interim Lab.md.

## Current Setup

```
Internet
   |
Verizon Router
   |
Minas Tirith (UniFi Cloud Gateway, 192.168.45.1)
   |
Osgiliath (UniFi 8-port PoE switch, 192.168.45.84)
   |
   +-- Amon Sûl (UniFi AP, 192.168.45.118)
   |      |
   |      +-- Rivendell (Omarchy Linux laptop, 192.168.45.63)   <- I work here
   |
   +-- Palantir (Proxmox host, 192.168.45.49)
          |
          +-- Amon Hen  (Wazuh manager, 192.168.45.53)
          +-- Erebor    (Windows 11 victim, 192.168.45.73)
          +-- Moria     (Ubuntu victim, 192.168.45.74)
          +-- Barad-dûr (Kali attacker, 192.168.45.75)
```

The UniFi gateway is double-NATed behind the Verizon router (not ideal, but there are no cable runs from the basement yet). I mainly work from the Omarchy laptop. When remote, I use WireGuard to reach the lab.

The lab network and the regular home network cannot reach each other. Everything in the range lives on the one lab network, which is already walled off from home at the gateway. That segment is the isolation boundary: attacks happen inside it and touch nothing outside it.

## Networks

| Network | Purpose |
|---|---|
| `192.168.45.0/24` | SecOps lab network behind the UniFi gateway |
| `192.168.2.0/24` | WireGuard VPN network used to access the lab |

## Devices

| Display name | Type | IP | Notes |
|---|---|---:|---|
| Minas Tirith | UniFi Cloud Gateway | 192.168.45.1 | Lab router and firewall |
| Osgiliath | UniFi 8-port PoE switch | 192.168.45.84 | Connected to Minas Tirith |
| Amon Sûl | UniFi Access Point | 192.168.45.118 | Lab wireless; connected to Osgiliath |
| Palantir | Proxmox host | 192.168.45.49 | 16 cores / 64GB / ~2TB. The hypervisor for the whole range |
| Rivendell | Omarchy Linux laptop | 192.168.45.63 | On the lab network via Amon Sûl |
| Amon Hen | Wazuh manager (Ubuntu) | 192.168.45.53 | 4 vCPU / 12GB / 60GB. Was SIEM-01. Dashboard on 443. Blocked outbound. The RAM-hungry box |
| Erebor | Windows 11 victim | 192.168.45.73 | 4 vCPU / 8GB / 60GB. Was "SecOps Lab". Agent + Sysmon. SATA disk, E1000 NIC |
| Moria | Ubuntu victim | 192.168.45.74 | 2 vCPU / 4GB / 25GB. Ubuntu 26.04. Wazuh agent (linux group) + auditd, both active. sauron attacker account (NOPASSWD sudo) |
| Barad-dûr | Kali attacker | 192.168.45.75 | 2 vCPU / 4GB / 40GB. Kali Rolling. No agent. My toolbox and C2; hydra, nmap, iodine. Hosts the Draghunt runner under sauron |

Hostnames stay plain ASCII and lowercase (amon-hen, erebor, moria, barad-dur) even where the display names keep accents. VM disks live on the NVMe thin pool, not local-lvm. All four running is ~30GB RAM against 64GB, leaving room for the planned domain controller and LLM host.

## Scenario IP mapping

The scenario files use placeholder addresses on 10.10.10.x. Read them against the real lab IPs; nothing in the scenarios needs editing if you substitute:

| Scenario placeholder | Real host | Real IP |
|---|---|---|
| 10.10.10.10 (wazuh) | Amon Hen | 192.168.45.53 |
| 10.10.10.20 (vic-lin) | Moria | 192.168.45.74 |
| 10.10.10.30 (vic-win) | Erebor | 192.168.45.73 |
| 10.10.10.5 (attacker) | Barad-dûr | 192.168.45.75 |

## Amon Hen (Wazuh)

### UniFi firewall

Amon Hen is blocked from initiating outbound internet traffic, scoped to its IP. Apply this rule after Wazuh is installed, since the install itself needs internet.

```text
Action: Deny
Source: 192.168.45.53
Destination: Internet
Direction: Outbound
```

### Host firewall (ufw) **These are not current, only Unifi rule in place

```bash
sudo ufw default deny incoming

# WireGuard VPN access
sudo ufw allow from 192.168.2.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 443 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 1514 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 1515 proto tcp

# Local lab access (agents live on this network)
sudo ufw allow from 192.168.45.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.45.0/24 to any port 443 proto tcp
sudo ufw allow from 192.168.45.0/24 to any port 1514 proto tcp
sudo ufw allow from 192.168.45.0/24 to any port 1515 proto tcp

sudo ufw enable
sudo ufw status numbered
```

### Allowed ports

| Port | Purpose |
|---:|---|
| `22/TCP` | SSH |
| `443/TCP` | Wazuh dashboard |
| `1514/TCP` | Wazuh agent communication |
| `1515/TCP` | Wazuh agent enrollment |
| `9200/TCP` | Wazuh indexer API. Restricted to the Draghunt controller (Rivendell, 192.168.45.63) |

The victims (Moria, Erebor) run the Wazuh agent and reach the manager on the lab network at 192.168.45.53. Barad-dûr runs no agent.

## Telemetry the scenarios need

Stock Wazuh reads syslog, auth logs, and does file integrity monitoring, which covers the simplest Linux scenarios. The interesting ones need endpoint telemetry that stock Wazuh doesn't ship. Skipping this is the usual reason an attack "doesn't show up."

### Moria (Linux): auditd

```bash
sudo apt install -y auditd audispd-plugins
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

Then add a localfile block for `audit` in the agent's `/var/ossec/etc/ossec.conf` and restart the agent.

### Erebor (Windows): Sysmon and PowerShell logging

Install Sysmon with a maintained config (SwiftOnSecurity or Olaf Hartong), then point the agent at the channels by adding to its `ossec.conf`:

```xml
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
<localfile>
  <location>Microsoft-Windows-PowerShell/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```

Also turn on PowerShell Script Block Logging (event 4104) and Process Creation auditing with command line (event 4688) via local policy.

### Prove it before trusting it

After wiring a box, do the smallest test. On Erebor, open Notepad and confirm a process-creation event lands in the dashboard. On Moria, run a command and confirm the execve appears. If the test event doesn't show, fix that before writing any case file, or you'll conclude an attack was invisible when the agent just wasn't reading the channel.

## Snapshot discipline

Non-negotiable, because a dirty victim poisons the next case's ground truth.

1. Snapshot every victim clean before any scenario, named `baseline`.
2. Run the scenario.
3. Investigate from the telemetry, not by poking the live box.
4. Revert to `baseline`. Every time.

## Safety rules

Nothing leaves the lab. No attacks, scans, or payloads pointed at anything I don't own. The lab segment is the boundary.

Attack tooling stays in the lab. Kali's toolbox, Atomic Red Team, C2 frameworks are fine here because I own the range.

Fake credentials only. Never seed the lab with a real password, token, or data used anywhere else.

Live malware is graduate-only. For real samples, spin a disposable VM with no internet, snapshot it, and hard-revert after. On Proxmox that means an internal-only bridge with no uplink, created just for that VM, so the sample can't reach the lab network or the internet. Never on a baseline I reuse.

Ground truth stays sealed until the verdict is written.

## What runs once the range is built

Windows scenarios (S05 PowerShell cradle, S06 LOLBins, S07 LSASS, Windows half of S08) run once Erebor has Sysmon wired. Early on these don't even need Barad-dûr; the laptop can host the file the cradle downloads.

Linux scenarios (S01 SSH brute force, S02 privesc, S03 web shell, S04 persistence, S09 DNS exfil) run once Moria has auditd wired and Barad-dûr exists.

S08 in full wants both victims plus, later, a domain controller. S10 wants the small LLM app from Learning Track Stage A2. S11 and S12 want the IdP host, and S12 also wants the LLM app registered against it.

## Remote Access

Connect over WireGuard when away, then:
- Proxmox web UI at https://192.168.45.49:8006 to manage the host and VMs.
- Proxmox's built-in console to reach any VM (this replaces RustDesk; Palantir no longer runs Windows Home).
- SSH to Amon Hen for management, browser to https://192.168.45.53 for the dashboard.

## Adding New Systems

| Display name | Type | IP | Purpose | Status |
|---|---|---:|---|---|
| Minas Morgul | Windows Server VM | 192.168.45.76 | Domain controller for full S08 lateral movement | Planned |
| (LLM host) | Linux VM | 192.168.45.77 | Small LLM app for S10 | Planned |
| (IdP host) | Linux VM | 192.168.45.78 | Keycloak or Authentik. Lab identity provider for the identity track (S11, S12); logs into Wazuh | Planned |
|  | VM / Container |  |  | Planned |

## Possible Future Additions

- Docker host
- Additional vulnerable targets
- Windows domain controller (Minas Morgul)
- Security Onion or another monitoring platform alongside Wazuh
- Backup server
- Separate management VLAN, if I outgrow the flat lab net

## Notes and Changes

```text
2026-09-01 - Added Amon Sûl (UniFi AP, .118) and Rivendell (laptop, .63)
2026-09-01 - Planned Palantir wipe to Proxmox; renamed VMs to LOTR (Amon Hen, Erebor);
             added Moria (.74) and Barad-dûr (.75). See Lab-Buildout.md.
2026-09-09 - Built Moria and Barad-dûr. Wired the Draghunt controller (Rivendell) into the
             range: dedicated sauron attacker accounts on Barad-dûr and Moria, key-based
             control chain, protocol-v1 runner on Barad-dûr, read-only draghunt-reader Wazuh
             user. Exposed the indexer on 9200 to the controller only (network.host change).
             Known caveat: the indexer node cert SAN is 127.0.0.1 only and must be reissued
             to include 192.168.45.53 before verified TLS from the controller works.
2026-09-22 - Resolved the cert caveat (reissued indexer node cert with the lab IP; re-signed
             the root CA to add keyUsage for OpenSSL 3.6). Granted draghunt-reader cluster_monitor
             + read on wazuh-alerts-*. Fired S01 end to end: 71 scoped alerts collected. Indexer
             API on 9200 now reachable from the controller over verified TLS.
```
