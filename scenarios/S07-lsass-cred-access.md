# S07 — Credential Access: LSASS Read

**Tier 3 · ATT&CK: T1003.001 (LSASS Memory)**

## Story
Something opened a handle to `lsass.exe` on `vic-win` with access rights that only a credential dumper needs. No creds leave this lab. The question is purely detection: can you catch the *access* before the theft?

> Lab-only, on a range you own. This is about generating and detecting the telemetry, not exfiltrating credentials. Keep `vic-win` isolated and revert after.

## Lab setup
- `vic-win`, Sysmon config that logs **Event 10 (ProcessAccess)** for `lsass.exe` (SwiftOnSecurity/Olaf configs do). Wazuh reading the Sysmon channel.

## Run it
Use Atomic Red Team's safe, reversible test. It is built for exactly this:
```powershell
Invoke-AtomicTest T1003.001
```
It exercises LSASS-access techniques (e.g. via `comsvcs.dll` MiniDump or a procdump) that trip Event 10. Randomize which sub-test runs.

## Cleanup / revert
`Invoke-AtomicTest T1003.001 -Cleanup`, then revert to `baseline`.

## What telemetry this generates
- **Sysmon Event 10 (ProcessAccess)**: `TargetImage: lsass.exe` with `GrantedAccess` like `0x1010`/`0x1410`/`0x143a`. This is the high-access-rights handle a dumper needs. `SourceImage` names the tool (rundll32/procdump/etc.).
- **Sysmon 11** if a dump file (`lsass.dmp`) hits disk.
- **Wazuh**: Sysmon decoder surfaces Event 10; the `GrantedAccess` value is the field that separates a dumper from benign AV/EDR access.

## Your investigation (fill cold)
Which process accessed LSASS, with what `GrantedAccess` mask, at what time? Was a dump written to disk (Event 11)? How do you distinguish this from legitimate LSASS access (AV, MsMpEng)? What is the discriminator? Given no creds left the lab, what's the *earliest* point you could have alerted?

## Detection engineering
An Event-10 rule where `TargetImage` ends in `lsass.exe` and `GrantedAccess` is in the dumper set, excluding known-good `SourceImage`s. This is a high-value endpoint detection. Ship it and document the allowlist you had to build.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: which sub-test/source image, the GrantedAccess mask, and whether a dump file was created.
- **Good:** you identify the source process and the access mask, know the mask is the discriminator (not just "something touched lsass"), and address the false-positive problem (benign LSASS access exists). Bonus: you caught the on-disk dump via Event 11.
- **Miss:** alerting on *any* LSASS access — you'll drown in AV noise. The rep is the `GrantedAccess` discrimination.
</details>
