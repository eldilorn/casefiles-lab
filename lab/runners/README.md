# Runners

One runner per scenario (`S01.sh` … `S10.sh`), plus the shared library `_lib.sh`.
These are the attack content **Draghunt** drives: it picks a scenario, randomizes
and seals the parameters, then invokes the matching runner and captures its
result. Everything runs **from Barad-dûr** (the Kali attacker); Draghunt itself
runs on the workstation and dispatches to Barad-dûr.

You don't call these directly in normal use; lay an exercise in Draghunt instead.
They live here so each attack is readable, reviewable, and easy to tune. The
standalone `../dealer.sh` is the original prototype Draghunt grew out of, kept for
manual runs and for previewing a plan with `--dry-run` when Draghunt isn't handy.

## Before the first live run

The range isn't assumed to exist. Until it does, practice against Draghunt's
synthetic exercises (no lab needed), and preview a live scenario without touching
a box:

```bash
./lab/dealer.sh --scenario S05 --dry-run   # prints the full plan, touches nothing
```

Dry-run is the fastest way to review exactly what a scenario will do. When you
wire a scenario for Draghunt live mode, mark it `"live": true` in the catalog
metadata Draghunt reads; live runs get a read-only preflight before anything fires.

### Prerequisites for live runs

Range config lives in `lab/lab.env` (IPs, users, key path, staging dir), which the
runner reads. Draghunt's own profile (`~/.config/draghunt/range.toml`) points at
this repo as its catalog and holds the Wazuh `agent_id`, indexer URL, credential,
and reset mode. Then:

1. **SSH key from Barad-dûr into the victims.** Generate a throwaway lab key and
   install its public half on the admin account of each victim:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/lab_id_ed25519 -N ''
   ssh-copy-id -i ~/.ssh/lab_id_ed25519 labadmin@192.168.45.74   # Moria
   ```
2. **OpenSSH Server on Erebor (Windows).** The Windows runners drive the box over
   SSH. Enable it once:
   ```powershell
   Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
   Start-Service sshd; Set-Service -Name sshd -StartupType Automatic
   ```
   Install the same public key into `C:\Users\labadmin\.ssh\authorized_keys`
   (and, for an admin account, `C:\ProgramData\ssh\administrators_authorized_keys`).
3. **Attacker tools on Barad-dûr:** `hydra`, `nmap`, `xfreerdp` (freerdp2/3),
   `dnscat2`, `iconv`, `python3`. Kali has most; install what's missing.
4. **Atomic Red Team on Erebor** for S05–S07 (`Install-AtomicRedTeam`,
   `Invoke-AtomicTest`). See the Atomic docs.
5. **DVWA on Moria** for S03; **dnscat2** on Moria for S09; the **Stage-2 LLM app**
   on the LLM host for S10.

### Notes

- `dealer.sh --dry-run` prints commands and writes them to the seal, but touches
  no box. Draghunt's live preflight is read-only in the same spirit.
- `dealer.sh --seal-only` randomizes and seals, then leaves you to run the scenario
  by hand. Under Draghunt this maps to laying a scenario without `--fire`.
- Some pieces are honest stubs when their host doesn't exist yet: S08's SSH-pivot
  falls back to RDP if the second Linux victim is absent, and S10 seals a plan and
  exits if the LLM host isn't built.
- These runners are written against the documented target range and have **not**
  been run against live boxes yet. Validate each one with `--dry-run`, then a
  single live run, before trusting its telemetry. A scenario that "didn't show up"
  is usually a wiring problem, not a quiet attack.
- Captures (pcap) stay on the victim under `/var/tmp/`. Keep them local. They must
  never be committed to the public `cases` repo.
