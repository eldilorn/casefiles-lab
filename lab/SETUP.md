# Homelab Setup: The Range

The scenarios in `scenarios/` are written against a generic range so they stay
portable. This file is that generic contract: the four roles, the placeholder
addresses, and pointers to the real specifics.

**`documentation/LabArchitecture.md` is the source of truth** for my actual range: real
hostnames and IPs, the telemetry wiring (auditd, Sysmon, PowerShell logging),
the snapshot discipline, and the safety rules. This file does not repeat those;
it points at them, so the two never drift.

---

## Topology (generic)

A minimum viable range is four machines on an **isolated lab network**:

| Role       | Generic host | Real host (mine) | OS                  | Notes                                              |
|------------|--------------|------------------|---------------------|----------------------------------------------------|
| Manager    | `wazuh`      | Amon Hen         | Ubuntu Server       | Wazuh manager + indexer + dashboard                |
| Victim-lin | `vic-lin`    | Moria            | Ubuntu Server 22.04 | Wazuh agent + auditd. Web scenarios add nginx/DVWA |
| Victim-win | `vic-win`    | Erebor           | Windows 11          | Wazuh agent + Sysmon                               |
| Attacker   | `kali`       | Barad-dûr        | Kali / Parrot       | No agent. Foothold and toolbox; runs the runner Draghunt dispatches |

Optional later: a second Linux victim for the S08 SSH pivot, a Windows domain
controller for full S08, and a small LLM-app host for S10.

## Placeholder IP convention

The scenario files use `10.10.10.x`. Read them against the real range with this map:

| Scenario placeholder | Real host  | Real IP        |
|----------------------|------------|----------------|
| `10.10.10.10` (wazuh)| Amon Hen   | 192.168.45.53  |
| `10.10.10.20` (vic-lin)| Moria    | 192.168.45.74  |
| `10.10.10.30` (vic-win)| Erebor   | 192.168.45.73  |
| `10.10.10.5` (attacker)| Barad-dûr| 192.168.45.75  |

Draghunt randomizes source IPs, and the runner reads the real addresses from
`lab/lab.env`, so nothing in the scenario files needs editing.

## Telemetry, snapshots, and safety

All in **`documentation/LabArchitecture.md`**:

- **Telemetry the scenarios need** — auditd on the Linux victim, Sysmon and
  PowerShell logging on Windows, and the "prove it before trusting it" test.
  Stock Wazuh alone covers only the Tier-1 Linux scenarios.
- **Snapshot discipline** — clean `baseline` snapshot before every scenario,
  revert after every one, no exceptions.
- **Safety rules** — isolated network, nothing leaves the lab, fake credentials
  only, live malware is graduate-only on a disposable no-egress VM, ground truth
  stays sealed until the verdict is written.

Each scenario file also has a **"What telemetry this generates"** section naming
the exact log source, the Wazuh location, and the fields that matter. Learn to
read the raw source and the Wazuh alert both; the gap between them is where
detections get written.

## Running a scenario

Build the range with `Lab-Buildout.md`, then run everything through **Draghunt**.
Point Draghunt's profile at this repo as its runner catalog (`control.catalog_dir`),
set the target's Wazuh `agent_id`, indexer URL, and read credential, and mark the
scenarios you've wired `"live": true`. Then:

```bash
# From the dashboard: choose Blind assessment or a named drill, then Run exercise.
python -m draghunt web            # http://127.0.0.1:8787

# Or the CLI, selecting the profile that points at this catalog:
python -m draghunt --config /path/to/range.toml list
python -m draghunt --config /path/to/range.toml lay --scenario S05 --fire --reset
```

Draghunt picks a scenario, randomizes and seals the parameters, runs the matching
runner in `lab/runners/` (via runner protocol v1), and pulls the Wazuh alerts into
the case. See `lab/runners/README.md` for the runner prerequisites (SSH keys,
Windows OpenSSH, Atomic Red Team, per-scenario tools). Before the range exists, or
when you just want a rep, Draghunt's synthetic exercises run with no lab.

## What goes to GitHub

Two repos, split by audience (see `documentation/One-Wall.md`):

- **Public repo `casefiles`:** only the daily case files (`cases/YYYY-MM-DD.md`),
  the `cases/TEMPLATE.md`, and a light README. This is the wall employers read.
- **Private repo `casefiles-lab` (this one):** the playbook, the `scenarios/`,
  the `lab/` tooling (runners, setup), and everything else. This repo is also
  Draghunt's private runner catalog; Draghunt itself lives in its own repo.
- **Never committed anywhere:** raw captures, sealed answer keys, and anything
  with a real credential. Draghunt keeps its sealed keys and case database in its
  own private data directory, not here. The legacy `lab/.groundtruth/` directory,
  `*.pcap`, and `*.log` stay git-ignored; keep it that way.
