# 🛠️ tahi — NixOS Installation Guide

This document provides an installation runbook for **`tahi`** (HPE ProLiant MicroServer Gen10 headless server & NAS).

---

## 📋 Host Overview

- **Host Target:** `tahi`
- **Primary User:** `factory` (Server mode)
- **Target OS Disk:** `/dev/sda` (240 GB SATA SSD)
- **Data Array Disks (DO NOT OVERWRITE):** `/dev/sdb`, `/dev/sdc`, `/dev/sdd`, `/dev/sde` (4x 6 TB HDDs)
- **Network Interface:** `br0` (`enp2s0f0`) with static IP `172.16.1.200`

---

## 🚀 Installation Runbook

### Step 1: Boot & Elevate to Root

1. Boot into the NixOS Minimal Live ISO on `tahi`.
2. Elevate to root:
   ```bash
   sudo -i
   ```
3. Verify network connectivity:
   ```bash
   ip a
   ping -c 3 nixos.org
   ```

---

### Step 2: Clone Configuration Repository

```bash
git clone https://github.com/factoryidiot/.nixos.git ~/.nixos
cd ~/.nixos
```

---

### Step 3: Prepare OS Disk with Disko

> [!CAUTION]
> **CRITICAL: VERIFY TARGET DISK BEFORE PARTITIONING**
> Ensure `/dev/sda` corresponds to the 240 GB SATA SSD. **Do NOT run Disko on `/dev/sdb`, `/dev/sdc`, `/dev/sdd`, or `/dev/sde` as they contain storage array data.**
>
> Run `lsblk -o NAME,SIZE,MODEL,TRAN` to verify disk assignments.

1. Execute Disko partitioning targeting `tahi`:
   ```bash
   nix --experimental-features "nix-command flakes" \
     run github:nix-community/disko/latest -- \
     --mode disko \
     ./hosts/tahi/disko.nix
   ```

2. Enable and verify the swapfile:
   ```bash
   swapon /mnt/swap/swapfile
   swapon -s
   ```

3. Verify active mounts:
   ```bash
   lsblk
   df -h
   ```
   Confirm `/mnt`, `/mnt/boot`, `/mnt/nix`, `/mnt/persistent`, and `/mnt/tmp` are mounted.

---

### Step 4: Generate Hardware Configuration & UUIDs

1. Generate hardware configuration scan:
   ```bash
   nixos-generate-config --root /mnt
   ```

2. Retrieve the filesystem UUIDs:
   ```bash
   blkid -s UUID -o value /dev/sda2
   blkid -s UUID -o value /dev/sda1
   ```

3. Update [`hosts/tahi/hardware-configuration.nix`](file:///home/factory/.nixos/hosts/tahi/hardware-configuration.nix) with the SSD UUIDs for `/dev/sda2` (`uuid`) and `/dev/sda1` (`/boot`).

4. Clean up temporary template files:
   ```bash
   rm -rf /mnt/etc/nixos/*
   ```

---

### Step 5: Execute NixOS Installation

1. Stage local changes:
   ```bash
   git add .
   ```

2. Run the NixOS installer targeting `tahi`:
   ```bash
   nixos-install --root /mnt --no-root-password --flake .#tahi --no-write-lock-file
   ```

---

### Step 6: Post-Installation Persistence & SSH Bootstrap

Because `tahi` is a headless server with password authentication disabled (`PasswordAuthentication = false`), **you MUST inject your SSH public key into `/persistent` before rebooting**.

1. Create persistent directory structure:
   ```bash
   mkdir -p /mnt/persistent/home/factory/.ssh
   mkdir -p /mnt/persistent/home/factory/.nixos
   mkdir -p /mnt/persistent/etc
   ```

2. Move generated SSH host keys:
   ```bash
   mv /mnt/etc/ssh /mnt/persistent/etc/
   ```

3. Copy the configuration repository to persistent storage:
   ```bash
   cp -r ~/.nixos/* ~/.nixos/.* /mnt/persistent/home/factory/.nixos/ 2>/dev/null || cp -r ~/.nixos /mnt/persistent/home/factory/
   ```

4. Add your authorized client SSH public key:
   ```bash
   echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ factory@whio" >> /mnt/persistent/home/factory/.ssh/authorized_keys
   ```

5. Set strict permissions and ownership (`1000:100` for user `factory`):
   ```bash
   chmod 700 /mnt/persistent/home/factory/.ssh
   chmod 600 /mnt/persistent/home/factory/.ssh/authorized_keys
   chown -R 1000:100 /mnt/persistent/home/factory
   ```

---

### Step 7: Reboot & Verify Remote Access

1. Reboot the server:
   ```bash
   reboot
   ```

2. From your workstation (`whio`), verify SSH connectivity once `tahi` comes online:
   ```bash
   ssh factory@172.16.1.200
   ```
