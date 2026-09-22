Draghunt Integration

**September 2026**
**Controller:** Rivendell

This documents wiring the Draghunt controller into the range so I can fire a scenario,
collect the evidence in Wazuh, and grade my own report against a sealed answer key. It
covers the accounts, the SSH trust chain, and the network changes. No keys or passwords
are recorded here on purpose; those live only on the machines that need them.

---

## What Draghunt runs on

Draghunt runs on Rivendell, my laptop, not on any lab VM. It reaches out over SSH to fire
scenarios and pulls evidence from Wazuh over the indexer API. Its profile lives at
`~/.config/draghunt/range.toml`, owner-only (mode 0600). Secrets never go in that file:
the Wazuh reader password and any Proxmox token are passed through environment variables
(`DRAGHUNT_SIEM_PASSWORD`, `DRAGHUNT_PROXMOX_SECRET`) instead.

## The attacker account: sauron

I created a dedicated adversary account named **sauron** rather than reusing my personal
**gandalf** login. Keeping the two separate means the attacker identity is distinct from
me, and I can tell my own admin activity apart from scenario activity later in the SIEM.

- **Barad-dûr (attacker, .75)** — sauron is the account Draghunt logs into. It needs no
  sudo here; it just launches the scenario tooling (hydra, nmap).
- **Moria (Linux victim, .74)** — sauron is the account the runner uses to set up and tear
  down each scenario. It has passwordless sudo so the runner can seed and remove the weak
  target account without an interactive prompt.
- **Erebor (Windows victim, .73)** — a sauron account will be added here when I run the
  Windows scenarios; it is created differently and isn't needed yet.

The infrastructure boxes get no attacker account. Amon Hen (Wazuh) and Palantir (Proxmox)
are reached over their APIs, not SSH.

## SSH trust chain

Everything is key-based, no passwords in the loop once it's set up:

```
Rivendell (controller) --> Barad-dûr (sauron) --> Moria (sauron, passwordless sudo)
```

The controller holds a key that authenticates as sauron on Barad-dûr. Barad-dûr holds a
separate key that authenticates as sauron on the victims. The attack itself still comes
from Barad-dûr over the network against the victim's SSH; the sauron login on the victim
is only there so the runner can prepare and clean up the scenario.

## The runner

The private runner from casefiles-lab lives in sauron's home on Barad-dûr. Draghunt invokes
`lab/fire.sh` over SSH following the runner protocol: a read-only preflight, then a run that
reports the actually observed result (source, account, outcome), then a cleanup. The sealed
ground truth is generated on Barad-dûr and is never copied to the laptop, so I stay blind
to the answer while I investigate.

## Wazuh read-only account

I added an internal Wazuh user, **draghunt-reader**, scoped to read the alerts index. The
controller uses it to pull scoped evidence for a case. Using a dedicated read-only account
keeps the admin credentials out of the tooling.

## Network changes

- Opened the indexer port (9200 on Amon Hen) to the controller's address only, not the
  whole lab subnet.
- Found that the Wazuh indexer was bound to localhost, so opening the firewall wasn't
  enough on its own; the indexer still has to be told to listen on the lab interface, and
  its node certificate has to cover that address for verified TLS to pass.

## Live path status

Done: indexer bound to the lab interface, node cert reissued with 192.168.45.53 in its SAN,
root CA re-signed to add Key Usage (OpenSSL 3.6 rejected it otherwise), reader role granted
cluster_monitor plus read on wazuh-alerts-*, Moria agent ID (002) and the indexer CA recorded
in the profile. S01 has fired end to end and collected 71 scoped alerts.

## Still open

- Create the sauron account on Erebor for the Windows scenarios.
- Configure Proxmox snapshot reset (baseline snapshots already exist).
- Acceptance checks still untested: a forced reset/preflight failure stopping a run, and a
  detection-rule replay recording a new revision.

## What I'd tell myself next time

- Give the adversary its own account from the start. A dedicated sauron is cleaner to
  reason about in the SIEM than attacks arriving as my personal admin login.
- A controller is a separate identity from the boxes it drives. It needs its own key onto
  the attacker, which is easy to forget when everything else already talks to everything.
- Opening a firewall port proves the packet arrives; it doesn't prove anything is
  listening. The indexer being bound to localhost looked identical to a firewall block
  until I checked from two different hosts.
- Interactive account setup (creating users, setting passwords, copying keys) has to be
  done from a real terminal. Piping those commands without a TTY just fails on the password
  prompt every time.
