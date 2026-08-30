# S08 — Lateral Movement (SSH pivot / RDP)

**Tier 3 · ATT&CK: T1021.001 (RDP), T1021.004 (SSH)**

## Story
The attacker isn't staying on the first box. Using creds harvested earlier, they moved from `vic-lin` to a second host (`vic-win` via RDP, or a second Linux box via SSH). Trace the pivot: which account, source→dest, and what they did on arrival.

## Lab setup
- The foothold host (`vic-lin`) + a destination host with the Wazuh agent. For RDP use `vic-win`; for SSH add a second Linux VM (`vic-lin2`).
- Reuse a credential from S01/S07 so there's a believable chain.

## Run it
Randomize direction and protocol:
```bash
# SSH pivot from vic-lin to vic-lin2 using stolen creds
sshpass -p 'Autumn2026' ssh svc-backup@10.10.10.21 'hostname; whoami; ss -tnp'
```
```powershell
# RDP into vic-win (from a box with a GUI) or use xfreerdp from kali:
xfreerdp /u:localadmin /p:'Winter2026!' /v:10.10.10.30
```

## Cleanup / revert
Revert both hosts to `baseline`.

## What telemetry this generates
- **SSH dest**: `auth.log` `Accepted password for svc-backup from 10.10.10.20`. Note the source is *another internal host*, not the attacker's usual IP. That internal→internal auth is the tell.
- **RDP dest**: **Event 4624 Logon Type 10** (RemoteInteractive) + Sysmon 3 inbound on 3389. `4778`/`4779` for session connect/reconnect.
- **Wazuh**: authentication-success rules on both; the value is correlating the *same account* appearing on host A then host B minutes apart.

## Your investigation (fill cold)
Reconstruct the path: which account moved from where to where, and when? RDP or SSH? Which log told you? What did they run on the destination in the first minute? Why is *internal-to-internal* authentication the signal, versus the external brute force in S01? Could you chain this to the earlier case (same credential)?

## Detection engineering
A rule that flags the same account authenticating to a second host shortly after the first (impossible-travel-lite for a flat lab), or Logon Type 10 / SSH-accept where the source is an internal asset that shouldn't be initiating admin sessions. Ship the cross-host correlation.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: protocol, account, source host, dest host, timestamps, on-arrival commands.
- **Good:** you draw the A→B path from two hosts' logs, identify the protocol from the right event (4624 type 10 for RDP), and flag internal-origin auth as the discriminator. Bonus: you linked the reused credential back to its harvest case.
- **Miss:** treating the destination login as an isolated event — lateral movement only exists as a *relationship between two hosts*, and the case is that relationship.
</details>
