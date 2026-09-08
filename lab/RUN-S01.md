# Running S01 against Moria

A checklist for firing the first live scenario, **S01 — SSH brute force**, through
Draghunt against Moria and investigating the result in your own Wazuh. Everything
runs inside the lab network; nothing leaves it.

S01 in one line: from Barad-dûr, guess passwords over SSH against a seeded account
on Moria, land (or not) depending on the draw, and leave real sshd auth telemetry
for you to investigate cold.

---

## 1. One-time prerequisites

**On Barad-dûr (the attacker):**
- `hydra` and `nmap` installed (`sudo apt install -y hydra nmap`).
- A throwaway lab SSH key whose public half is on Moria's admin account:
  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/lab_id_ed25519 -N ''
  ssh-copy-id -i ~/.ssh/lab_id_ed25519 labadmin@192.168.45.74
  ssh -i ~/.ssh/lab_id_ed25519 labadmin@192.168.45.74 'sudo -n true && echo sudo-ok'
  ```
  You want `sudo-ok`: the run seeds and later deletes a user, so the admin needs
  passwordless sudo. Confirm `casefiles-lab/lab/fire.sh` and `lab.env` are present
  in `~/casefiles-lab/lab` on this box.

**On Moria (the target):**
- Wazuh agent active and reporting: `systemctl is-active wazuh-agent`.
- sshd running, and its auth log flowing to Wazuh. Stock Wazuh already reads
  `/var/log/auth.log`, so no extra endpoint telemetry is needed for S01.

**Snapshot:** take (or confirm) Moria's clean `baseline` snapshot first, or let
Draghunt reset the target if you have Proxmox configured. See `LabArchitecture.md`.

---

## 2. Point Draghunt at the range

Start the app and open **Settings**:

```bash
python -m draghunt web      # then http://127.0.0.1:8787
```

| Field | Value |
|---|---|
| Attacker host / user / SSH key | `192.168.45.75` · `kali` · `~/.ssh/lab_id_ed25519` |
| Target host / admin user / agent ID | `192.168.45.74` · `labadmin` · Moria's Wazuh agent ID |
| Wazuh indexer URL | `https://192.168.45.53:9200` (HTTPS, verified) |
| Wazuh read username / password | your read-only indexer account |
| CA file | your lab CA, if the indexer cert is self-signed |
| Private scenario catalog directory | `~/casefiles-lab/lab/catalog` |

Save. The readiness banner should turn green and the status pill should read
**Live range**. If a secret field is blank it keeps the stored value.

> The indexer URL must be HTTPS and is certificate-verified. For a self-signed lab
> cert, set the CA file rather than disabling verification.

---

## 3. Fire it

1. On **Practice**, choose **S01 — SSH brute force against a Linux host** (or
   Blind draw), tick **Run against my real lab**, and click **Run**.
2. Confirm the named target in the dialog.
3. Draghunt runs a read-only preflight, fires the attack, then moves the case to
   **awaiting telemetry** and waits out the ingest delay.
4. Click **Refresh evidence**. The real sshd events from your Wazuh load into the
   case: repeated `Failed password for <account>` from `192.168.45.75`, and an
   `Accepted password` line if the attack landed this draw.

Whether it landed is randomized per run and reported from the actual hydra result,
not from what was requested, so investigate it cold.

---

## 4. Investigate and submit

Work the case as you would a real alert:

- **Did it succeed?** Look for `Accepted password` from the same source after the
  burst of failures, not just the failures themselves.
- Fill the scored findings: disposition, technique (`T1110.001`), the source IP,
  the account, and whether the objective succeeded. Cite the event IDs that prove
  each call.
- Submit. The debrief reveals the answer key and scores you.

Optional detection rep: write a Wazuh rule that correlates N failures followed by an
`Accepted password` from the same source, deploy it, run a fresh replay, and record
a **detection check** with the rule ID and revision.

---

## 5. Reset

If you did not have Draghunt reset the target, revert Moria to `baseline` so the
next case starts clean. The runner's own cleanup removes the seeded account, but a
snapshot revert is the reliable reset.

---

## Troubleshooting

- **Preflight blocks with a named check.** `runner` means fire.sh/lab.env aren't
  where expected on Barad-dûr; `target` means SSH to Moria failed; `telemetry`
  means Moria's Wazuh agent isn't active.
- **No events after refresh.** Give ingestion time, then refresh again. An empty
  result is not proof nothing happened; check the agent ID matches Moria and that
  the indexer credential can search the alert index.
- **"cannot grade an unverifiable run" / unknown outcome.** The run timed out or
  returned nothing usable; reset the target before firing again.
- **Attack won't fire.** Confirm `hydra` is installed and the admin has
  passwordless sudo on Moria.
