# 💻 whio — Hardware Specifications & Architecture

`whio` is the primary daily-driver workstation and gaming laptop running NixOS with a fully stateless root on `tmpfs`, LUKS2 disk encryption, and UEFI Secure Boot.

---

## ⚙️ Hardware Specifications

| Component | Specification | Details / Notes |
| :--- | :--- | :--- |
| **Chassis / Model** | ASUS TUF Gaming A15 (FA507UI_FA507UI 1.0) | High-performance AMD/NVIDIA gaming laptop |
| **Processor (CPU)** | AMD Ryzen 9 8945H | 8 Cores / 16 Threads, base 4.0 GHz, boost up to 5.26 GHz (Zen 4 / Hawk Point) |
| **Graphics (dGPU)** | NVIDIA GeForce RTX 4070 Laptop GPU | 8 GB GDDR6, 140W max TGP, proprietary driver with PRIME offload (`PCI:01:0:0`) |
| **Graphics (iGPU)** | AMD Radeon 780M (Phoenix3) | Integrated RDNA 3 graphics (`PCI:65:0:0`) |
| **Memory (RAM)** | 32 GiB DDR5 | Dual-channel high-speed system memory |
| **Primary Display** | 15.6″ IPS Panel (NE156FHM-NX6) | Full HD (1920 × 1080) @ 144 Hz refresh rate |
| **External Displays** | USB-C (DP 1.4) / HDMI 2.1 | e.g. 27″ QHD (2560 × 1440) @ 100 Hz |
| **Storage** | 1 TB NVMe SSD (`/dev/nvme0n1`) | PCIe Gen4 NVMe M.2 Solid State Drive |
| **Network & Wireless** | Wi-Fi 6 (802.11ax) + Bluetooth 5.3 | Managed by `iwd` (Intel iwlwifi module configured) |
| **Security Hardware** | TPM 2.0 Module | Used for Lanzaboote UKI validation & LUKS automated key unlock |

---

## 💽 Storage & Filesystem Architecture

The system uses a single encrypted NVMe drive partitioned with [`disko`](file:///home/factory/.nixos/hosts/whio/disko.nix), featuring a stateless `tmpfs` root and Btrfs subvolumes for persistent data and system snapshots.

```
/dev/nvme0n1 (1 TB NVMe)
├── /dev/nvme0n1p1 (500 MiB FAT32) ──────────────── /boot (EFI System Partition)
└── /dev/nvme0n1p2 (Rest of Drive, LUKS2)
    └── /dev/mapper/crypted (Btrfs Pool)
        ├── / (tmpfs, 16 GiB RAM) ────────────────── Ephemeral stateless root
        ├── subvol=@nix ──────────────────────────── /nix (Nix Store, zstd:1, ssd, discard=async)
        ├── subvol=@persistent ───────────────────── /persistent (Impermanence bind-mount source)
        ├── subvol=@swap ─────────────────────────── /swap (Contains 24 GiB swapfile, nodatacow)
        ├── subvol=@tmp ──────────────────────────── /tmp (Fast transient builds)
        ├── subvol=@guix ─────────────────────────── /gnu (Guix compatibility layer)
        └── subvolid=5 ───────────────────────────── /btr_pool (Top-level Btrfs filesystem access)
```

### Mountpoints & Compression Settings

| Mountpoint | Device / Source | FS Type | Mount Options | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| `/` | `tmpfs` | `tmpfs` | `relatime,mode=755,size=16G` | Stateless root; wiped completely on reboot |
| `/boot` | `/dev/nvme0n1p1` | `vfat` | `fmask=0077,dmask=0077` | UEFI bootloader & kernel UKI images |
| `/nix` | `/dev/mapper/crypted` (`@nix`) | `btrfs` | `noatime,compress=zstd:1,ssd,discard=async` | Nix store and derivations |
| `/persistent` | `/dev/mapper/crypted` (`@persistent`) | `btrfs` | `noatime,compress=zstd:1,ssd,discard=async` | All persistent system state & user dotfiles |
| `/swap` | `/dev/mapper/crypted` (`@swap`) | `btrfs` | `noatime,nodatacow` | 24 GiB swapfile for hibernation and memory overflow |
| `/tmp` | `/dev/mapper/crypted` (`@tmp`) | `btrfs` | `noatime,compress=zstd:1,ssd,discard=async` | Temporary build directories |

---

## 🖥️ Software Environment & Services

- **Target User:** `factory`
- **Window Manager / Compositor:** Hyprland (Wayland)
- **Status Bar & Launcher:** Waybar + Walker (Application & Clipboard Launcher)
- **Terminal Emulator:** Ghostty
- **Shell:** Zsh with Powerlevel10k theme
- **Kernel:** Linux Zen Kernel (`pkgs.linuxPackages_zen`) with `amd_pstate=active`
- **Hardware Integration:**
  - `asusd` / `supergfxctl` for ASUS TUF power profiles and keyboard backlight control.
  - NVIDIA PRIME render offloading (`nvidia-offload` utility for discrete GPU tasks).
  - OpenSSL custom certificate authority trust (`tahi_root.crt`).
  - Docker & Flatpak containers with state preserved under `/persistent`.

---

## 🔗 Related Documentation

- 📖 [**whio Installation Guide**](file:///home/factory/.nixos/hosts/whio/INSTALL.md) — Step-by-step installation runbook from the live installer.
- 🔒 [**whio Secure Boot & TPM2 Guide**](file:///home/factory/.nixos/hosts/whio/SECUREBOOT.md) — Lanzaboote key enrollment and TPM2 LUKS auto-unlock configuration.
