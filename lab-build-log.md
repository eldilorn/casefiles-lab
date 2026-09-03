Homelab Build Log

**September 2026**
**Host:** Palantir

This is a running log of my home security lab build: moving away from a Windows/VMware setup, installing Proxmox on bare metal, standing up a Wazuh SIEM, and bringing the first monitored endpoint online.

I’m documenting the problems along with the successful parts because the troubleshooting has been just as useful as the finished setup.

---

## Goal

The goal is to build a small detection and attack lab where I can generate activity, collect endpoint telemetry, and investigate it from a SIEM.

The planned environment is one Proxmox host running four main VMs:

- **Amon Hen** — Wazuh SIEM
- **Erebor** — Windows victim
- **Moria** — Linux victim
- **Barad-dûr** — Kali attacker

The naming follows the Lord of the Rings theme I already use across the rest of my network. (Big LoTR nerd)

Before this rebuild, Palantir was running Windows Home with VMware Workstation. I managed it remotely through RustDesk since Windows Home doesn’t support hosting normal RDP sessions. It worked, but it always felt temporary.

The better setup was to wipe the host and install Proxmox directly on the hardware. That gives me a proper type-1 hypervisor and lets me manage every VM through the Proxmox web interface.

### Hardware

- 16 CPU cores
- 64 GB RAM
- 1 TB WD Green SN350 NVMe
- 1 TB Seagate HDD
- 240 GB SSD

The lab sits on its own `192.168.45.0/24` network behind my UniFi gateway and is isolated from my normal home network. My main laptop, **Rivendell**, runs Omarchy, and I use WireGuard when I need to access the lab remotely.

---

## Phase 1 — Creating the Proxmox Installer

I created the Proxmox installer from my Linux laptop.

Before writing anything to the USB, I checked the available block devices:

```bash
lsblk
```

The USB was `/dev/sda`, while my laptop’s internal drive was `nvme0n1`. Since `dd` will happily overwrite whatever device it is given, this was worth verifying before continuing.

I unmounted the existing USB partition and wrote the ISO:

```bash
sudo umount /dev/sda1
sudo dd if=~/Downloads/proxmox-ve_*.iso of=/dev/sda bs=4M status=progress oflag=sync
```

My first attempt appeared to do nothing. The issue was simple: the wildcard didn’t match the actual Proxmox 9.2 ISO filename.

After listing the directory and using the exact filename, the image wrote correctly.

---

## Phase 2 — Proxmox Installer Hanging on Nvidia

Palantir booted from the installer USB, but Proxmox froze during startup.

Both the graphical and terminal installers stopped at essentially the same place, immediately after Nvidia-related drivers started loading.

The problem was the `nova` driver stack used by the newer Linux kernel included with Proxmox 9.2. Common fixes like blacklisting `nouveau` or adding only `nomodeset` weren’t enough because `nouveau` wasn’t actually the driver causing the hang.

At the Proxmox boot menu, I highlighted the installer entry, pressed `e`, found the line beginning with `linux`, and appended:

```
nomodeset modprobe.blacklist=nova_core,nova_drm,nova,nouveau
```

I then booted with `Ctrl-X`.

That got the installer past the freeze immediately.

The same issue could affect the first boot of the installed OS, so the temporary GRUB edit was enough to get the machine running, but the blacklist also needed to be made permanent afterward.

---

## Phase 3 — Installing to the Wrong Disk

The first real mistake of the build happened during disk selection.

I installed Proxmox to the wrong drive.

The installation completed normally, but after rebooting the machine came back into the old Windows installation that was still sitting on another disk.

I reinstalled Proxmox onto the disk I actually wanted to use: the 240 GB SSD.

That layout made more sense anyway:

- 240 GB SSD for the Proxmox OS
- 1 TB NVMe for VM storage
- 1 TB HDD left untouched temporarily

The accidental Proxmox install was still consuming the NVMe, so before removing anything I verified exactly where the live system was running.

```bash
findmnt /
```

The active root filesystem was under `/dev/mapper/pve-root`.

I then checked the LVM volume groups:

```bash
vgs
```

There were two:

- `pve` — roughly 222 GB, which matched the SSD and was the active installation
- `pve-OLD-B6A5A8B5` — roughly 930 GB, which matched the NVMe and was the accidental install

At that point there was no guessing involved.

That became one of the more useful habits from this build: before doing anything destructive to storage, verify the target from the system itself instead of relying on memory.

---

## Phase 4 — Reclaiming the NVMe

I initially tried wiping the NVMe through the Proxmox interface, but Proxmox reported that the disk still had a holder.

The old LVM volume group was still active.

Using the exact volume group name returned by `vgs`, I removed it:

```bash
vgremove pve-OLD-B6A5A8B5
```

The command prompted for confirmation before removing the logical volumes for data, swap, and root.

Once the volume group was gone, I cleared the remaining filesystem and partition signatures:

```bash
wipefs -a /dev/nvme0n1
```

The GPT signatures were removed and the disk was available again.

I checked the target multiple times before running both commands. `vgremove` and `wipefs` are not commands where I want to discover afterward that I was "pretty sure" I had the right drive.

### VM Storage

With the NVMe clean, I created a new LVM-thin pool from:

**Proxmox → Node → Disks → LVM-Thin → Create Thinpool**

The pool uses `/dev/nvme0n1` and gives me roughly 930 GB for virtual machines.

LVM-thin fits the lab well because VM disks only consume physical storage as they fill, and snapshots will be useful when running attack scenarios. I can snapshot a victim, run a test, collect telemetry, and then return it to a clean state.

### Storage Layout

Current layout:

- **240 GB SSD** — Proxmox OS
- **1 TB NVMe** — VM thin pool
- **1 TB Seagate HDD** — Undecided what to use it for yet

I’ll likely use the Seagate HDD for backups, ISOs, or other lab storage.

---

## Phase 5 — Proxmox Housekeeping

A fresh Proxmox installation is configured to use the enterprise repository, which requires a subscription.

I disabled the enterprise repository and enabled the no-subscription repository, then updated the host:

```bash
apt update && apt -y full-upgrade
```

---

## Phase 6 — Building Amon Hen

The first VM I built was **Amon Hen**, which will act as the SIEM.

I went through the Proxmox VM wizard manually rather than accepting every default.

### VM Configuration

**Name**

```
amon-hen
```

VM ID: `100`

**Operating System**

Ubuntu Server 26.04 ISO with Linux selected as the guest OS.

**System**

I kept SeaBIOS and enabled the QEMU Guest Agent so Proxmox can communicate with the guest for functions such as clean shutdowns and IP reporting.

**Disk**

Proxmox initially wanted to place the VM on `local-lvm`, which is storage on the smaller SSD. I changed it to the NVMe thin pool.

Disk size:

```
60 GB
```

Wazuh can accumulate a fair amount of indexed log data, so I wanted enough room without reserving more storage than necessary up front.

**CPU**

```
1 socket
4 cores
```

**Memory**

```
16 GB
```

The SIEM is the VM I expect to use the most memory. The Wazuh indexer is the heavier component, so this made more sense than spreading RAM evenly across every system in the lab.

**Network**

VirtIO attached to `vmbr0`, which places it on the lab network.

Before creating the VM, I read through the final confirmation screen and specifically verified that its disk was being created on the NVMe pool rather than `local-lvm`.

That final screen is an easy place to catch storage or sizing mistakes before they turn into cleanup work.

---

## Phase 7 — Ubuntu Server

I booted Amon Hen from the Ubuntu Server ISO and kept the base installation fairly standard.

### Network Configuration

Since agents and my own bookmarks will need a consistent address for the SIEM, I configured a static IP:

```
IP:      192.168.45.53/24
Gateway: 192.168.45.1
DNS:     192.168.45.1
```

I don’t want the SIEM receiving a different DHCP address after a reboot and breaking every agent pointed at it. I'll also likely just configure statics for all VMs to make my life easy.

### Storage

I used the full 60 GB virtual disk with LVM enabled.

I skipped LUKS encryption. For this particular VM, requiring an encryption passphrase every time it boots would create more operational hassle than value.

### Remote Administration

I created the local user and made sure to select:

```
Install OpenSSH server
```

That lets me administer Amon Hen directly from Rivendell instead of relying on the Proxmox console.

Once Ubuntu finished installing, I rebooted into the new system.

---

## Phase 8 — First Boot and SSH

Amon Hen booted normally and the login banner showed the expected address:

```
192.168.45.53
```

I ran a few basic checks:

```bash
ip a
ping -c3 1.1.1.1
sudo apt update && sudo apt upgrade -y
```

The system had the correct address and outbound connectivity.

When I tried connecting from Rivendell, SSH returned:

```
REMOTE HOST IDENTIFICATION HAS CHANGED
```

In this case, the warning made sense.

An older SIEM VM had previously used `192.168.45.53`. My laptop still had the SSH key associated with that system in `known_hosts`, but the old VM had been destroyed and this was now a completely new server using the same IP.

I removed the stale entry:

```bash
ssh-keygen -R 192.168.45.53
```

Then connected again:

```bash
ssh gandalf@192.168.45.53
```

---

## Phase 9 — Installing Wazuh

With SSH working, I installed Wazuh using the official all-in-one deployment.

The VM is currently running all three major Wazuh components:

- **Manager** — receives agent data and evaluates rules
- **Indexer** — stores and searches event data
- **Dashboard** — web interface

During installation I saved the generated administrator password in Bitwarden (I have a fresh Bitwarden account for all of my lab passwords.). It’s randomly generated and printed at the end of the install, so I didn’t want to depend on scrolling back through terminal output later.

After installation, I opened:

```
https://192.168.45.53
```

Logged in successfully and the manager itself was generating some baseline events, but there were no victim systems reporting into it yet.

---

## Phase 10 — Building Erebor (Windows Victim)

The second VM was **Erebor**, a Windows 11 victim.

Windows took a little more setup than the Linux VM because the installer expects specific platform features and doesn’t have Proxmox’s VirtIO drivers available by default.

Setting the guest OS type to Windows 11 handled most of the platform configuration automatically. Proxmox selected the q35 machine type and OVMF firmware and added an EFI disk and TPM 2.0 device. I pointed the EFI and TPM storage at the NVMe pool, enabled the QEMU Guest Agent, and continued through the wizard.

The two other choices were mainly about using virtual hardware the Windows installer could recognize without loading additional drivers:

- **SATA disk instead of VirtIO.** The Windows installer didn’t have the VirtIO storage driver loaded, so SATA was the straightforward option.
- **Intel E1000 network card instead of VirtIO.** Same idea. Windows could use the emulated Intel adapter without needing an additional VirtIO network driver during setup.

I sized Erebor at 4 cores and 8 GB of RAM. It’s a victim endpoint rather than a heavy service, so it doesn’t need the memory Amon Hen gets. Its 60 GB disk also lives on the NVMe pool.

The Windows installer had a couple of small detours. The "press any key to boot from CD" prompt timed out the first time and dropped me into the boot-device menu, so I selected the DVD manually.

To bypass the annoying internet/Microsoft account requirement I opened a command prompt with `Shift+F10` and ran:

```
oobe\bypassnro
```

After the reboot, I was able to continue setup with a local account.(Go through the prompts normally, then choose work or school, then sign-in options, then domain joined)

---

## Phase 11 — The Console Paste Problem and RDP

Installing the Wazuh agent on Erebor turned into more of a fight than it should have, and the root cause wasn’t Wazuh.

I couldn't figure out pasting from the Proxmox console. This was probably user error, but Claude kept leading me astray saying I could enable clipboard on the left side of the screen...never figured that out..problem for another day. Anyways, the agent installation eventually failed with:

```
installation package could not be opened
```

Looking more closely, the actual problem was the filename. The download had saved the package as `wazuh-agent` with no extension, while the install command was looking for `wazuh-agent.msi`.

Two different filenames, so `msiexec` had nothing to open.

It was basically the same lesson as the ISO problem from Phase 1: in a multi-step command, verify that the first step actually produced the file the next step expects.

Rather than keep fighting the console, I set up RDP into Erebor from Rivendell.

Remmina was giving me input problems under Hyprland/Wayland, so I used `xfreerdp` directly:

```bash
xfreerdp3 /v:192.168.45.73 /u:gandalf /dynamic-resolution +clipboard
```

The important part was `+clipboard`. Once copy/paste worked normally, managing the Windows VM became much easier.

I reran the Wazuh installation as separate steps: download the package, verify that the file exists and has a real size, then run the installer against that exact filename.

Erebor appeared in the Wazuh dashboard as an active agent.

The SIEM finally had something to monitor.

One note on account naming: I’m using `gandalf` across several lab hosts for convenience, but each system has a different fake password. Using the same username isn’t the credential-reuse problem I’m interested in testing. If I introduce reused credentials later, I want it to be deliberate as part of a scenario rather than an accidental weakness in the lab.

---

## Phase 12 — Sysmon and PowerShell Logging

Getting an agent connected is only the first step. I also need enough endpoint telemetry to make the activity I care about visible.

The default Windows event channels give me a baseline, but they don’t provide the level of process and script visibility I want for the attack scenarios. Erebor therefore needed Sysmon and PowerShell Script Block Logging.

After downloading the SwiftOnSecurity configuration from https://github.com/SwiftOnSecurity/sysmon-config/blob/master/sysmonconfig-export.xml:

```powershell
sysmon -accepteula -i c:\users\gandalf\downloads\sysmonconfig-export.xml
```

For PowerShell, I enabled Script Block Logging through the registry.

That gives me event ID `4104` and visibility into the script content PowerShell executes, including decoded script blocks when something is launched using an encoded command.

That will matter later when I start running PowerShell download and execution scenarios.

---

## Phase 13 — Validating the Pipeline

This was the step I wanted to complete before trusting any of the telemetry: prove that events actually make it from the endpoint to the SIEM.

I first confirmed locally on Erebor that Sysmon was generating events using `Get-WinEvent`.

Then I went looking for them in Wazuh.

My first test was a `notepad.exe` process launch. I knew Sysmon had recorded it locally, but I couldn’t find it in the Threat Hunting view.

The process launch existed in Sysmon, but a normal Notepad launch didn’t trigger a Wazuh rule. The default dashboard views are centered around events that generated alerts, so the event never showed up there.(New to Wazuh)

By default, I’m not storing every non-alerting event in a searchable archive. Enabling Wazuh archives with `logall_json` would give me that additional visibility, but it would also increase storage usage significantly.

For now I’m leaving archives disabled. The early scenarios are controlled enough that I can work primarily from alerting data. When I hit a scenario where I need to investigate activity that doesn’t generate a rule match, I can enable archives and expand Amon Hen’s storage at the same time.

To validate the pipeline with an actual alert, I opened a `net user` discovery event that Wazuh had flagged.

The event showed:

- Command line: `net user`
- Process image: `net1.exe`
- Execution context: SYSTEM
- Parent/context tied back to the Wazuh agent

The rule classified the activity as discovery, which makes sense because `net user` is commonly used for account enumeration.

---

## Phase 14 — Centralized Configuration

Editing `ossec.conf` by hand on every endpoint would work in a tiny lab, but it doesn’t scale well and would be a bad habit to build.

Wazuh agent groups give me a better model: define shared configuration on the manager and assign agents to the appropriate groups.

An agent can belong to multiple groups, and those configurations are merged.

Every agent starts in the `default` group. In my setup, that already carries the baseline configuration and Wazuh-provided content I want to keep.

I created a separate `windows` group and added Erebor to it.

Erebor is now a member of both:

```
default
windows
```

The main thing I wanted the Windows-specific group to handle was the additional event channels I had just enabled.

Instead of duplicating the rest of the baseline configuration, `windows/agent.conf` only contains the additions:

```xml
<agent_config>
  <localfile>
    <location>Microsoft-Windows-Sysmon/Operational</location>
    <log_format>eventchannel</log_format>
  </localfile>
  <localfile>
    <location>Microsoft-Windows-PowerShell/Operational</location>
    <log_format>eventchannel</log_format>
  </localfile>
</agent_config>
```

That keeps the group configuration small and makes its purpose obvious.

### Proving the Group Configuration Worked

I also wanted to make sure Erebor was actually receiving the centralized configuration rather than continuing to work because of something left over in its local configuration.

I generated a process with a unique marker:

```powershell
cmd.exe /c "echo WAZUH-TEST-RIDDLES-42"
```

Then I searched Wazuh for:

```
data.win.system.eventID:1
```

The event appeared with the marker in the command line.

Using a made-up string was intentional. Searching for something generic like `cmd.exe` would return a lot of unrelated activity, while a unique marker gives me one event that I know I generated.

That validated the full chain:

```
Sysmon
  ↓
Wazuh Agent
  ↓
Centralized Group Configuration
  ↓
Wazuh Manager
  ↓
Indexer
  ↓
Dashboard
```

At that point I knew the centralized Windows telemetry configuration was working.

---

# Current State

The platform and first monitored victim are both functional. I now have a working detection pipeline and an endpoint I can use for actual investigations.

### Completed

- Palantir wiped and converted from Windows/VMware to Proxmox VE 9.2
- Proxmox running from the 240 GB SSD
- 1 TB NVMe reclaimed and configured as LVM-thin VM storage
- Amon Hen (Wazuh SIEM) built with static IP `192.168.45.53`
- Wazuh dashboard operational
- Erebor (Windows 11 victim) built with static IP `192.168.45.73`
- Wazuh agent installed on Erebor and reporting as active
- Sysmon installed on Erebor
- PowerShell Script Block Logging enabled
- Centralized `windows` group configured for Windows-specific telemetry
- Full pipeline validated with a unique-marker test
- First alert triage completed on a `net user` discovery event

The lab has gone from a Windows host running VMware to a dedicated virtualization platform with a working SIEM and a monitored Windows endpoint.

---

# Next Steps

Erebor has enough telemetry in place to start running real investigations. I don’t need to finish the entire range before using it.

### First Case Investigation

The first planned case is **S05 — PowerShell download cradle**.

I can use Rivendell as the download source for now, which means I don’t need the Kali attacker VM yet.

Before running it:

1. Snapshot Erebor as `baseline`.
2. Run the PowerShell download cradle.
3. Investigate the activity from Wazuh without relying on what I know I launched.
4. Find the PowerShell process and related telemetry.
5. Decode and reconstruct what the command did.
6. Determine whether the connection to Rivendell succeeded.
7. Write the verdict.
8. Compare the investigation against the known ground truth.

That becomes case file number one.

### Build the Rest of the Lab

- **Moria** — Linux victim. Install the Wazuh agent and enroll it directly into a `linux` group so auditd and other Linux-specific telemetry can be managed centrally from the start.
- **Barad-dûr** — Kali attacker. This will be used for scenarios that need a separate adversary host, including S01, S03, S08, and S09.

### Later, When a Scenario Needs It

Enable Wazuh archives with `logall_json` when I need searchable access to non-alerting telemetry.

The DNS exfiltration scenario will likely be the first case where that additional visibility matters.

When I enable it, I’ll also expand Amon Hen’s disk to account for the additional event storage.

---

# Lessons So Far

A few things from the build are worth carrying forward:

- Check the actual filename instead of assuming a wildcard matched it.
- Proxmox 9.2 can hang during installation with Nvidia hardware because of the `nova` modules. Blacklisting `nova_core,nova_drm,nova,nouveau` got this host through the installer.
- Verify storage before destructive operations. `findmnt /` and `vgs` gave me a definitive answer when I had multiple similar-looking installations.
- Treat `vgremove` and `wipefs` as irreversible operations and verify the target every time.
- Separating the hypervisor OS from VM storage gives me a cleaner layout and makes better use of the larger NVMe.
- VM resources should match the workload. Wazuh gets the RAM; disposable victim machines don’t need to.
- An SSH host-key change can be completely legitimate after a rebuild, but it should never be dismissed without understanding why it changed.
- Match virtual hardware to what the guest installer can support. SATA and E1000 were the simplest choices for Windows because I didn’t have the VirtIO drivers loaded during installation.
- Don’t fight the Proxmox console for text-heavy work. RDP or SSH with clipboard support is much easier. `xfreerdp ... +clipboard` solved that problem for me under Wayland.
- An agent reporting as active doesn’t mean I have all the telemetry I need. Sysmon and PowerShell logging add the process and script visibility that will matter during investigations.
- Alerts and telemetry are not the same thing. An event can exist on the endpoint without producing a Wazuh alert. Archives are available when I need to retain and search those non-alerting events.
- A detection rule is only the starting point. The full context of the event determines whether the behavior is actually suspicious. The `net user` alert was my first example of a suspicious-looking behavior that made sense once I identified its source.
- Configuration should be centralized where possible instead of hand-edited on every endpoint. Group-specific `agent.conf` files let me add only the telemetry each OS needs while keeping the baseline separate.
- Don’t delete unfamiliar SIEM content just to clean up a directory. Understand what it does first.
- Use unique markers when validating a logging pipeline. A string like `WAZUH-TEST-RIDDLES-42` is much easier to trace than a generic process name.

The infrastructure is now far enough along to use rather than just build. I have a working SIEM, a monitored Windows victim, and a telemetry path I’ve validated end to end.

The next stage is less about standing up servers and more about generating activity, investigating what happened, and documenting each scenario as a case file.
