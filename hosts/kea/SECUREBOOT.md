# 🔒 kea — Secure Boot & Dual-Drive TPM2 Auto-Unlock Guide

This guide details how to configure UEFI Secure Boot and bind **both LUKS containers** (`crypted_ssd` on `/dev/sda2` and `crypted_storage` on `/dev/sdb1`) to the **TPM 2.0** chip on `kea`.

---

## 📋 Prerequisites

Ensure your system configuration has the following enabled:
- `tpm2-tss` package
- `boot.initrd.systemd.enable = true;`
- Lanzaboote module imported in [`lib/nixos/secureboot.nix`](file:///home/factory/.nixos/lib/nixos/secureboot.nix)

---

## 🔐 Part 1: Secure Boot Key Creation & Enrollment

### 1. Verify UEFI & TPM2 Readiness

```bash
bootctl status
```

Confirm `TPM2 Support: yes` and firmware is in setup mode.

---

### 2. Generate Custom Secure Boot Keys

```bash
sudo nix run nixpkgs#sbctl create-keys
```

---

### 3. Build & Verify EFI Signing

Rebuild the system to generate signed Unified Kernel Images:

```bash
sudo nixos-rebuild switch --flake ~/.nixos#kea
```

Verify that all boot binaries and kernels are signed:

```bash
sudo nix run nixpkgs#sbctl verify
```

---

### 4. Enroll Keys into UEFI Firmware

Enroll custom keys with Microsoft vendor keys:

```bash
sudo nix run nixpkgs#sbctl enroll-keys -- --microsoft
```

---

### 5. Enable Secure Boot & Verify

1. Reboot the laptop:
   ```bash
   sudo reboot
   ```
2. Enter BIOS and ensure **Secure Boot** is enabled.
3. Boot into NixOS and confirm status:
   ```bash
   bootctl status
   ```
   *Expected: `Secure Boot: enabled (user)`*

---

## 🔑 Part 2: Dual-Drive TPM2 LUKS Auto-Unlock

Enroll the TPM2 chip on **both** the primary SSD container and the secondary storage container:

### 1. Enroll Primary SSD Container (UUID `183e165a-c486-46eb-b124-cef8f85a2892`)

```bash
sudo systemd-cryptenroll --tpm2-device auto --tpm2-pcrs "0+2+7" --wipe-slot tpm2 /dev/disk/by-uuid/183e165a-c486-46eb-b124-cef8f85a2892
```

### 2. Enroll Secondary Storage Container (UUID `0d983907-2c76-42eb-9567-3c639b0fca81`)

```bash
sudo systemd-cryptenroll --tpm2-device auto --tpm2-pcrs "0+2+7" --wipe-slot tpm2 /dev/disk/by-uuid/0d983907-2c76-42eb-9567-3c639b0fca81
```

---

### 3. Generate & Save Recovery Keys

Generate recovery keys for both containers and record them in a secure password manager:

```bash
# Recovery key for SSD
sudo systemd-cryptenroll --recovery-key /dev/disk/by-uuid/183e165a-c486-46eb-b124-cef8f85a2892

# Recovery key for Storage HDD
sudo systemd-cryptenroll --recovery-key /dev/disk/by-uuid/0d983907-2c76-42eb-9567-3c639b0fca81
```

---

### 4. Verify LUKS Key Slots

```bash
sudo cryptsetup luksDump /dev/disk/by-uuid/183e165a-c486-46eb-b124-cef8f85a2892
sudo cryptsetup luksDump /dev/disk/by-uuid/0d983907-2c76-42eb-9567-3c639b0fca81
```

Both containers will now unlock seamlessly at boot via TPM2.
