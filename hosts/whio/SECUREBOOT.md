# 🔒 whio — Secure Boot & TPM2 LUKS Auto-Unlock Guide

This guide details how to configure UEFI Secure Boot via **Lanzaboote** and bind disk decryption to the system's **TPM 2.0** chip, enabling passwordless boot security without compromising disk encryption integrity.

---

## 📋 Prerequisites

Ensure your system configuration has the following enabled in NixOS:
- `tpm2-tss` package
- `boot.initrd.systemd.enable = true;`
- Lanzaboote module imported in [`lib/nixos/secureboot.nix`](file:///home/factory/.nixos/lib/nixos/secureboot.nix)

---

## 🔐 Part 1: Secure Boot Key Creation & Enrollment

### 1. Verify UEFI & TPM2 Readiness

Check the current firmware boot status:

```bash
bootctl status
```

Confirm that `TPM2 Support: yes` and `Secure Boot: disabled (setup)` or similar setup mode is displayed.

---

### 2. Generate Custom Secure Boot Keys

Generate your owner UUID and cryptographic keys using `sbctl`:

```bash
sudo nix run nixpkgs#sbctl create-keys
```

---

### 3. Build & Verify EFI Signing

Rebuild the system to generate signed Unified Kernel Images (UKIs):

```bash
sudo nixos-rebuild switch --flake ~/.nixos#whio
```

Verify that all boot binaries and kernels are signed:

```bash
sudo nix run nixpkgs#sbctl verify
```

> [!IMPORTANT]
> Ensure all files listed in `/boot/EFI/...` indicate signed status (`✓`).

---

### 4. Enroll Keys into UEFI Firmware

Enroll your custom keys along with Microsoft vendor keys (necessary for GPU option ROMs and firmware updates):

```bash
sudo nix run nixpkgs#sbctl enroll-keys -- --microsoft
```

---

### 5. Enable Secure Boot & Verify

1. Reboot the system:
   ```bash
   sudo reboot
   ```
2. Enter UEFI / BIOS settings and ensure **Secure Boot** is set to **Enabled** (if not already enabled automatically).
3. Once booted into NixOS, verify Secure Boot is active:
   ```bash
   bootctl status
   ```
   *Expected result: `Secure Boot: enabled (user)`*

---

## 🔑 Part 2: TPM2 Automatic LUKS Unlocking

Once Secure Boot is enforced, bind LUKS volume `/dev/nvme0n1p2` to the TPM2 chip using PCRs `0+2+7` (Firmware + Option ROMs + Secure Boot Policy measurements).

### 1. Enroll TPM2 on the NVMe Drive

```bash
sudo systemd-cryptenroll --tpm2-device auto --tpm2-pcrs "0+2+7" --wipe-slot tpm2 /dev/nvme0n1p2
```

---

### 2. Generate & Save a LUKS Recovery Key

Generate a secondary recovery passphrase in case firmware or PCR measurements change:

```bash
sudo systemd-cryptenroll --recovery-key /dev/nvme0n1p2
```

> [!CAUTION]
> **Store this recovery key in a safe, offline location (such as a password manager or physical safe).** If firmware updates alter TPM measurements, you will need this key to unlock the drive.

---

### 3. Verify Enrollment

Inspect the keyslots on the LUKS header:

```bash
sudo cryptsetup luksDump /dev/nvme0n1p2
```

Confirm that both a `tpm2` token and a `recovery` keyslot are present. On next reboot, the system will unlock automatically via TPM2 without requiring a manual passphrase.
