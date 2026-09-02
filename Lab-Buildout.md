# Lab Buildout

The one-time procedure to rebuild the range on Proxmox, using the existing lab network (192.168.45.0/24) and the documented IPs. You wipe Palantir, install Proxmox, and create four VMs on the flat lab network. When you're done you'll have a working range with baseline snapshots. After this, LabArchitecture.md is the doc you keep open.

Budget a few evenings, not one. Proxmox installs quickly; the four VMs and their telemetry wiring are the real time.

## End state

One Proxmox host on the lab network, four VMs on the same network, all reachable from the laptop and over WireGuard:

- Palantir, Proxmox host, 192.168.45.49
- Amon Hen, Wazuh, 192.168.45.53
- Erebor, Windows 11 victim, 192.168.45.73
- Moria, Ubuntu victim, 192.168.45.74
- Barad-dûr, Kali attacker, 192.168.45.75

Everything sits on 192.168.45.0/24 behind the UniFi gateway, which already isolates the lab from the home network. One virtual bridge (vmbr0) is all you need. There's no separate attack subnet; the whole lab segment is the boundary. (If you later work with live malware, make a throwaway internal-only bridge just for that VM, per the safety note in LabArchitecture.md.)

## Host capacity and how to size VMs

Palantir has 16 CPU cores, 64GB RAM, and ~2TB of datastore. That's roomy for this lab, so the constraint is comfort, not scarcity. Two rules keep it sane:

RAM is reserved, not shared. Memory handed to a running VM is genuinely taken from the host until that VM shuts down. So the sum of RAM across running VMs must stay under 64GB (leave a couple GB for Proxmox itself).

Cores are shared. VMs draw from the same 16 cores and share them when idle, so you can assign more total vCPUs than 16 across all VMs without a problem; just don't give one box more cores than it needs.

The principle: size each VM to its workload, not to the host. The host's size tells you the plan fits (it does, easily), but each VM still gets only what its role needs. Over-assigning RAM wastes it; over-assigning cores adds scheduling overhead. The one box worth spending surplus on is Amon Hen, because Wazuh's indexer is a Java search database that genuinely benefits from more RAM.

Planned totals with all four running: roughly 12–16 + 8 + 4 + 4 = ~30GB RAM committed against 64GB, under half. That leaves headroom for the later boxes (a domain controller, an LLM host) and lets you run everything at once without thinking about it.

## Before you wipe anything

The VMs on Palantir are about to be destroyed. Make sure nothing important lives only there. Your playbook, scenarios, and case files should already be in git or on Rivendell. If any config or notes live only inside the current SIEM-01 or Windows VM, copy them to the laptop now.

Gather install ISOs onto the laptop:

- Proxmox VE, current stable release, from proxmox.com. (My version knowledge may be stale; grab whatever the site lists as current.)
- Ubuntu Server LTS, from ubuntu.com.
- Windows 11, from Microsoft.
- Kali Linux installer image (not the live image), from kali.org.

## Step 1 — Make the Proxmox USB from the laptop

Plug in a USB stick (8GB+, it gets wiped) and find its device name:

```bash
lsblk
```

It'll be something like /dev/sdb. Be certain, because dd doesn't ask twice. Write the ISO to the whole disk (not a partition):

```bash
sudo dd if=~/Downloads/proxmox-ve_*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## Step 2 — Install Proxmox on Palantir

1. Boot Palantir from the USB and enter BIOS/UEFI (usually Del or F2).
2. Turn on virtualization (Intel VT-x or AMD-V / SVM). Required, and the most-forgotten step.
3. Set the USB as boot device, save, reboot.
4. Choose "Install Proxmox VE (graphical)".
5. Accept the license, pick the target disk (this wipes it).
6. Set country, timezone, keyboard.
7. Set a strong root password and an email.
8. Network: pick the wired NIC. Hostname `palantir.lab`. IP 192.168.45.49/24. Gateway 192.168.45.1. DNS 192.168.45.1 or 1.1.1.1.
9. Confirm and install. It reboots into Proxmox.

From the laptop, open https://192.168.45.49:8006 (expect a self-signed cert warning). Log in as root.

## Step 3 — First-login housekeeping

Proxmox ships pointed at a paid repo, so updates fail until you switch to the free one. In the UI: node `palantir`, Updates, Repositories. Disable the "enterprise" repo, then Add the "No-Subscription" repo. Open the node Shell and update:

```bash
apt update && apt -y full-upgrade
reboot
```

The "no valid subscription" popup is harmless; dismiss it.

## Step 4 — Confirm the network bridge

The installer already made vmbr0 on your physical NIC, bridged to the lab network. That's all you need. Check under node `palantir`, System, Network: vmbr0 should be there with your NIC as its bridge port. Every VM attaches to vmbr0 and gets a static 192.168.45.x address with gateway 192.168.45.1.

## Step 5 — Upload the ISOs

In the UI: node `palantir`, `local` storage, ISO Images, Upload. Upload the four ISOs.

## Step 6 — Build Amon Hen (Wazuh)

Create VM:
- Name: amon-hen
- ISO: Ubuntu Server
- System: defaults (SeaBIOS is fine for Linux); tick Qemu Agent
- Disk: 60GB on the NVMe thin pool (not local-lvm; the indexer accumulates log data)
- CPU: 1 socket, 4 cores
- Memory: 12288 MB (12GB). This is the box worth spending surplus RAM on; 8GB is the bare floor, 12–16GB is where the indexer stays smooth as log volume grows. 16384 (16GB) is fine too.
- Network: vmbr0

Install Ubuntu. Set a static address: 192.168.45.53/24, gateway 192.168.45.1, DNS 192.168.45.1.

Install Wazuh (all-in-one manager, indexer, dashboard) per Wazuh's quickstart while the box still has internet. Then apply the ufw rules from LabArchitecture.md, and only after the install finishes, add the UniFi outbound-deny rule for 192.168.45.53. Confirm the dashboard loads from the laptop at https://192.168.45.53.

## Step 7 — Build Erebor (Windows victim)

Windows 11 needs a few things set at create time or it won't install.

Create VM:
- Name: erebor
- ISO: Windows 11
- System: BIOS = OVMF (UEFI), Machine = q35, add an EFI disk, and add a TPM (TPM State, v2.0). Windows 11 refuses to install without UEFI and a TPM.
- Disk: 60GB on the NVMe thin pool, bus = SATA for a simple install (VirtIO is faster but needs the driver ISO during install; skip for now).
- CPU: 1 socket, 4 cores
- Memory: 8192 MB (8GB). Leave it here even with spare RAM; Windows 11 wants ~8GB to feel normal and this is a victim, not a workhorse. More buys nothing.
- Network: model Intel E1000 on vmbr0 (E1000 needs no extra drivers)

Install Windows. At the "let's connect you to a network" screen, to make a local account instead of signing into a Microsoft account, press Shift+F10, type `oobe\bypassnro`, Enter; it reboots into a flow that lets you skip the Microsoft sign-in and create a local account. (Keep lab credentials fake.)

After install:
- Set the static address: 192.168.45.73/24, gateway 192.168.45.1.
- Windows Update.
- Install the Wazuh agent, manager address 192.168.45.53.
- Install Sysmon with a maintained config, add the Sysmon and PowerShell localfile blocks to the agent config, and turn on script block logging and command-line auditing per LabArchitecture.md.
- Confirm the agent shows Active and that opening Notepad produces a process-creation event in the dashboard.

Snapshot as `baseline` (step 10).

## Step 8 — Build Moria (Ubuntu victim)

Create VM:
- Name: moria
- ISO: Ubuntu Server
- Disk: 25GB on the NVMe thin pool
- CPU: 1 socket, 2 cores
- Memory: 4096 MB (4GB). A Linux victim needs very little; 4GB is comfortable, don't go higher.
- Network: vmbr0

Install Ubuntu. Static address 192.168.45.74/24, gateway 192.168.45.1. Then:
- Update the system.
- Install the Wazuh agent, manager 192.168.45.53.
- Install and configure auditd per LabArchitecture.md.
- Confirm the agent shows Active and a test command produces an execve event.

Snapshot as `baseline`.

## Step 9 — Build Barad-dûr (Kali attacker)

Create VM:
- Name: barad-dur
- ISO: Kali installer
- Disk: 40GB on the NVMe thin pool
- CPU: 1 socket, 2 cores
- Memory: 4096 MB (4GB; bump to 6GB only if you run heavy tooling later)
- Network: vmbr0

Install Kali. Static address 192.168.45.75/24, gateway 192.168.45.1. Update and install the tools the scenarios lean on (hydra, the Atomic Red Team runner, dnscat2 or iodine, and so on). No Wazuh agent; this is the adversary. Snapshot as `baseline`.

## Step 10 — Baseline snapshots

For each victim (Erebor, Moria) and optionally Barad-dûr, take a Proxmox snapshot named `baseline` while the VM is clean: VM, Snapshots, Take Snapshot, name `baseline`. This is what you revert to after every scenario, every time.

## Step 11 — First real morning

The range is built. Don't spend the next two weeks polishing it. Pick one Windows scenario (S05 is a good first one), stage it tonight against Erebor with the laptop hosting the download, and investigate it tomorrow before work. Wire anything remaining and build toward S08/S10 in slack time, and let each piece of lab work become its own case file when it fights you.

## Later additions

When they earn a place in the queue: Minas Morgul (a Windows Server domain controller, 192.168.45.76) for full S08, and a small Linux LLM-app host (192.168.45.77) for S10. Add them to the tables in LabArchitecture.md as you go.
