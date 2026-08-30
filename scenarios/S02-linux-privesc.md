# S02 — Linux Privilege Escalation (SUID / sudo misconfig)

**Tier 1 · ATT&CK: T1548.001 (Setuid/Setgid), T1068 (Exploitation for Priv Esc)**

## Story
A low-priv user on `vic-lin` (say the `svc-backup` foothold from S01) became root. No exploit CVE, just a misconfiguration a careful eye would have caught. Which one, and what did root do next?

## Lab setup
Pick ONE misconfig per run (the dealer randomizes which):
- **A - SUID binary abuse:** `sudo chmod u+s /usr/bin/find` (a GTFOBins classic).
- **B - sudoers wildcard/NOPASSWD:** add `svc-backup ALL=(ALL) NOPASSWD: /usr/bin/vim` to `/etc/sudoers.d/lab`.
- **C - writable cron/PATH:** a root cron that runs a script from a user-writable dir.
- auditd loaded with the `lab.rules` from `lab/SETUP.md`.

## Run it
As `svc-backup`, escalate via the seeded path, e.g. for A:
```bash
find . -exec /bin/sh -p \; -quit   # -p keeps the SUID euid=0 shell
id                                  # euid=0
# root action to detect:
echo 'attacker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/lab
useradd -M -s /bin/bash attacker 2>/dev/null; id attacker
```
For B: `sudo vim -c ':!/bin/sh'`. For C: write to the cron'd script and wait.

## Cleanup / revert
Revert to `baseline`.

## What telemetry this generates
- **auditd** `exec` key: the `find`/`vim` invocation and the resulting `/bin/sh` with `euid=0`. The `identity`/`persistence` watches fire on the `/etc/sudoers.d/lab` write and the `useradd`.
- **Wazuh**: auditd decoder surfaces the execve records; the write to `/etc/sudoers` and `useradd` map to privilege-escalation / account-manipulation rules.

## Your investigation (fill cold)
What was the escalation vector (which binary, which misconfig)? Reconstruct the exact moment euid went to 0 from the audit record. What did the new root do (new account, sudoers edit)? Is there persistence now? Which single control would have prevented it?

## Detection engineering
A rule on `execve` where a known-SUID interactive shell spawns with `euid=0` from a non-login-shell parent, or a FIM/auditd high-severity alert on any write to `/etc/sudoers*`. Ship whichever your run exercised.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: which misconfig (A/B/C), the exact escalation command, and the root actions (sudoers write + `useradd attacker`).
- **Good:** you name the vector from the audit trail (not by guessing), pin the euid=0 timestamp, and list post-escalation persistence. Bonus: you identify the misconfig's origin (the `chmod u+s` / sudoers line) as the root cause and propose the specific control.
- **Miss:** "user ran find" without connecting it to the SUID bit and the euid=0 shell — the escalation is the point, not the command.
</details>
