# /hosts/whio/hardware-configuration.nix
{ config
, lib
, pkgs
, modulesPath
, ...
}:
let
  btrfsOptions = [ "noatime" "compress=zstd:1" "ssd" "discard=async" ];

  # =========================================================================
  # Set all 3 UUIDs here after formatting
  # =========================================================================
  BOOT_ESP_UUID = "6C28-8A6B"; # /dev/nvme0n1p1 (FAT32 EFI partition)
  NVME_LUKS_UUID = "8b152900-298c-4c60-a275-485e1bf2bc9b"; # /dev/nvme0n1p2 (LUKS partition on NVMe)
  BTRFS_UUID = "528baf24-b6fa-4407-8d49-249a8113c303"; # /dev/mapper/crypted (Decrypted BTRFS filesystem)
in
{

  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.systemd-boot.enable = true;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "sd_mod" "usbhid" "usb_storage" ];
  boot.initrd.kernelModules = [ ];
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "amd_pstate=active" "iommu=pt" "nmi_watchdog=1" ];
  boot.kernelModules = [ "amdgpu" "kvm-amd" ];
  boot.extraModulePackages = [ ];
  boot.tmp.cleanOnBoot = true; # clear /tmp on boot to get a stateless /tmp directory
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  boot.initrd.luks.devices."crypted" = {
    device = "/dev/disk/by-uuid/${NVME_LUKS_UUID}";
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  fileSystems."/boot" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BOOT_ESP_UUID}";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  fileSystems."/btr_pool" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = [ "subvolid=5" ];
    };

  fileSystems."/" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "relatime" "mode=755" ];
    };

  fileSystems."/gnu" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@guix" ];
    };

  fileSystems."/nix" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@nix" ];
    };

  fileSystems."/persistent" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@persistent" ];
      neededForBoot = true;
    };


  fileSystems."/swap" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = [ "subvol=@swap" "nodatacow" "noatime" ];
    };

  #fileSystems."/swap/swapfile" =
  #  {
  #    device = "/swap/swapfile";
  #    depends = [ "/swap" ];
  #    fsType = "none";
  #    options = [ "bind" "rw" ];
  #  };

  fileSystems."/tmp" = lib.mkDefault
    {
      device = "/dev/disk/by-uuid/${BTRFS_UUID}";
      fsType = "btrfs";
      options = btrfsOptions ++ [ "subvol=@tmp" ];
    };

  swapDevices = [
    { device = "/swap/swapfile"; }
  ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
