# SecOps Lab

A simple reference for my home security lab. This will grow as I add more VMs, Docker containers, and services.

## Current Setup

```
Internet
   |
ISP Router
   |
Minas Tirith (UniFi Cloud Gateway)
   |
Osgiliath (8-port UniFi PoE switch)
   |
   +-- Amon Sûl (UniFi AP)
   |      |
   |      +-- Rivendell (Omarchy Linux laptop)
   |
   +-- Palantir (VMware Workstation Pro host)
          |
          +-- SIEM-01
          +-- SecOps Lab
          +-- Future VMs and containers
```

The UniFi gateway is double NATed behind the Verizon router(not ideal but will have to do for now due to no cable runs from the basement). I mainly interact with the homelab on my laptop running Omarchy. If I am remote, I use WireGuard to connect into the lab.

The lab network and regular home network cannot directly reach each other.

## Networks

| Network | Purpose |
|---|---|
| `192.168.45.0/24` | SecOps lab network behind the UniFi gateway |
| `192.168.2.0/24` | WireGuard VPN network used to access the lab |


## Devices

| Name | Type | IP | Notes |
|---|---|---:|---|
| Minas Tirith | UniFi Cloud Gateway | 192.168.45.1 | Lab router and firewall |
| Osgiliath | UniFi 8-port PoE switch | 192.168.45.84 | Connected to Minas Tirith |
| Amon Sûl | UniFi Access Point | 192.168.45.118 | Lab wireless; connected to Osgiliath |
| Palantir | Main lab desktop | `192.168.45.49` | Runs VMware Workstation Pro; remote access through RustDesk |
| Rivendell | Omarchy Linux laptop | `192.168.45.63` | On the lab network via Amon Sûl |
| SIEM-01 | Ubuntu Server VM | `192.168.45.53` | Wazuh all-in-one server |
| SecOps Lab | Windows 11 Pro VM | `192.168.45.73` | Wazuh agent installed |

## SIEM-01

### UniFi firewall

SIEM-01 is blocked from initiating outbound internet traffic.

```text
Action: Deny
Source: 192.168.45.53
Destination: Internet
Direction: Outbound
```

The rule is scoped only to the SIEM-01 IP.

### Ubuntu firewall

```bash
sudo ufw default deny incoming

# WireGuard VPN access
sudo ufw allow from 192.168.2.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 443 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 1514 proto tcp
sudo ufw allow from 192.168.2.0/24 to any port 1515 proto tcp

# Local lab access
sudo ufw allow from 192.168.45.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.45.0/24 to any port 443 proto tcp
sudo ufw allow from 192.168.45.0/24 to any port 1514 proto tcp
sudo ufw allow from 192.168.45.0/24 to any port 1515 proto tcp

sudo ufw enable
sudo ufw status numbered
```

### Allowed ports

| Port | Purpose |
|---:|---|
| `22/TCP` | SSH |
| `443/TCP` | Wazuh dashboard |
| `1514/TCP` | Wazuh agent communication |
| `1515/TCP` | Wazuh agent enrollment |

## Remote Access

- Connect to the UniFi gateway through WireGuard.
- Use SSH to manage SIEM-01.
- Use a browser to access the Wazuh dashboard.
- Use RustDesk to access Palantir because it runs Windows Home and cannot host normal Windows RDP.(This is changing soon as I am going to wipe Palantir and install Proxmox.)

## Adding New Systems

Add new VMs and containers here as the lab grows.

| Name | Type | IP | Purpose | Status |
|---|---|---:|---|---|
|  | VM / Container |  |  | Planned |
|  | VM / Container |  |  | Planned |
|  | VM / Container |  |  | Planned |
|  | VM / Container |  |  | Planned |

## Possible Future Additions

- Docker host
- Vulnerable practice targets
- Windows domain controller
- Linux endpoints
- Security Onion or another monitoring platform
- Automation and reporting services
- Backup server
- Separate management or server VLANs

## Notes and Changes

Use this section for quick updates.

```text
YYYY-MM-DD - Change made
2026-09-01 - Added Amon Sûl (UniFi AP, 192.168.45.118) and Rivendell (Omarchy Linux laptop, 192.168.45.63)
```
