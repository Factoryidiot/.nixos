# 🚀 rua — Compute & Media Streaming Node

`rua` (`172.16.1.220`) is a headless compute and media streaming server running NixOS on a **Lenovo ThinkCentre M720q Tiny**. It hosts the **Jellyfin Media Server** daemon with hardware-accelerated video transcoding via **Intel QuickSync Video (QSV)**, streaming directly to smart displays (such as the living room Samsung TV via the native Jellyfin app) and network clients.

Media libraries are mounted over NFS v4.2 directly from the central storage server (`tahi`).

---

## ⚙️ Hardware Specifications

| Component | Specification | Details / Notes |
| :--- | :--- | :--- |
| **Chassis / Model** | Lenovo ThinkCentre M720q Tiny | Ultra-compact 1-liter desktop |
| **Processor (CPU)** | Intel Core 8th / 9th Gen (Coffee Lake) | Low-power desktop CPU |
| **Graphics (iGPU)** | Intel UHD Graphics 630 | Hardware H.264/HEVC/AV1 decoding & encoding via Intel QuickSync (`jellyfin-ffmpeg`, `vainfo`) |
| **Memory (RAM)** | DDR4 SODIMM | Fast buffer caching for transcode operations |
| **Network Interfaces** | Intel I219-V Gigabit Ethernet (`enp1s0`) | Primary connection (`172.16.1.220`) via `systemd-networkd` (route metric 1024) |
| **Secondary Network** | Intel Wi-Fi (`wlan0`) | Managed via `iwd` as failover (route metric 2048) |
| **Security Chip** | Discrete TPM 2.0 | Automated LUKS2 volume auto-decryption on boot |
| **Primary Storage** | M.2 NVMe SSD (`/dev/nvme0n1`) | LUKS2 encrypted Btrfs with stateless `tmpfs` root |

---

## 💽 Storage & Filesystem Architecture

```
Drive: /dev/nvme0n1 (M.2 NVMe SSD)
├── /dev/nvme0n1p1 (500 MiB FAT32) ──────────────── /boot (EFI System Partition)
└── /dev/nvme0n1p2 (LUKS2 Container 'crypted')
    ├── / (tmpfs, 8 GiB RAM) ────────────────────── Ephemeral stateless root
    ├── subvol=@nix ──────────────────────────────── /nix (Nix Store, zstd:1)
    ├── subvol=@persistent ───────────────────────── /persistent (SSH keys, Jellyfin db & transcode cache)
    ├── subvol=@swap ─────────────────────────────── /swap (16 GiB swapfile)
    ├── subvol=@tmp ──────────────────────────────── /tmp (Temporary files)
    └── subvolid=5 ───────────────────────────────── /btr_pool

Network Storage (NFS from tahi):
└── 172.16.1.200:/storage/data/media ───────────── /data/media (Automounted via systemd, NFS v4.2)
    ├── /data/tv ────────────────────────────────── Symlink to /data/media/tv
    └── /data/movies ────────────────────────────── Symlink to /data/media/movies
```

---

## 🎬 Jellyfin & Transcoding Architecture

- **Backend Daemon:** Native NixOS systemd unit (`services.jellyfin`) running under `jellyfin:jellyfin`.
- **GPU Acceleration:** Dedicated access to `/dev/dri/renderD128` via `video` and `render` groups.
- **Client Playback:** Streams directly to the native **Samsung Smart TV Jellyfin app** and across the local network via `https://jellyfin.lan` (reverse proxied by `tahi-traefik`).
- **Remote Administration:** Managed headlessly via OpenSSH with public key authentication.

---

## 🔗 Related Documentation

- 📖 [**rua Installation Guide**](file:///home/factory/.nixos/hosts/rua/INSTALL.md) — Step-by-step clean installation and TPM2 enrollment runbook.
