# S01 — SSH Brute Force to Successful Login

**Tier 1 · ATT&CK: T1110 (Brute Force), T1078 (Valid Accounts)**

## Story
An internet-facing Linux box (`vic-lin`) exposes SSH. Overnight, something hammered it. The morning question: did anyone get *in* — and if so, as whom, from where, and what did they do first?

## Lab setup
- `vic-lin` running `sshd`, Wazuh agent active. Create a weak account so a run can actually succeed on random draws:
  ```bash
  sudo useradd -m -s /bin/bash svc-backup && echo 'svc-backup:Autumn2026' | sudo chpasswd
  ```
- Attacker `kali` with `hydra` and a small wordlist that *may or may not* contain the real password (that's the randomized unknown).

## Run it
From `kali` (randomize source, target user, and whether the real password is in the list):
```bash
# Recon first (this also generates telemetry worth finding)
nmap -Pn -p22 --open 10.10.10.20

# Brute force. Swap in a list; include the real pw on ~50% of runs.
hydra -l svc-backup -P wordlist.txt ssh://10.10.10.20 -t 4 -f
```
If it lands, simulate a first action so "successful login" has a consequence to find:
```bash
ssh svc-backup@10.10.10.20 'id; uname -a; cat /etc/passwd | tail -5'
```

## Cleanup / revert
Revert `vic-lin` to `baseline`. (Or `sudo userdel -r svc-backup` if you kept the box live.)

## What telemetry this generates
- `/var/log/auth.log` on `vic-lin`: bursts of `Failed password ... from <ip>`, and on success `Accepted password for svc-backup from <ip>`.
- **Wazuh**: sshd rules fire — repeated failures trigger the brute-force/auth-failure group; the `Accepted password` is a separate alert. The pairing (many failures + one accept, same source IP) is the whole case.
- The post-login `id`/`cat /etc/passwd` shows up via auditd `exec` key if enabled.

## Your investigation (fill cold)
Did it succeed? Which account, which source IP, at what time? How many failures preceded success? What did the attacker do in the first 60 seconds? Was there recon before the brute force? **Then write the detection question:** would Wazuh's default rules have *told you it succeeded*, or only that it was attacked?

## Detection engineering (optional artifact)
Write/tune a rule that correlates ≥N failures followed by an `Accepted password` from the *same* source within a window, and fires at a higher level than either alone. That "brute force that worked" alert is more valuable than either raw signal — ship it to `lab/rules/`.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Ground truth per run lives sealed in `lab/.groundtruth/`. The dealer records: source IP, target user, whether the password was in the list (success/fail), timestamp, and whether recon ran first.
- **What good looks like:** you state success/failure with the *evidence* (the `Accepted password` line, not a guess), name the source IP and account, give the failure count and window, and list the post-login commands. Bonus: you noticed the nmap SYN scan preceding it.
- **Common miss:** reporting "brute force detected" and stopping — that's the alert, not the verdict. The verdict is *did it work.* If default rules didn't make success obvious, that blind spot IS the finding, and the correlation rule above is the fix.
</details>
