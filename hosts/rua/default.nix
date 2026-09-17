# ./hosts/rua/default.nix
{ pkgs
, lib
, specialArgs
, ...
}:
let
  inherit (specialArgs) hostname username;
in
{

  imports = [
    #+----- Host specific configuration ----------
    ./hardware-configuration.nix
    ./persistence.nix

    #+----- Basic configuration ------------------
    ../../lib/nixos/base-packages.nix
    ../../lib/nixos/base-security.nix
    ../../lib/nixos/btrfs.nix
    ../../lib/nixos/maintenance.nix
    ../../lib/nixos/multimedia.nix
    ../../lib/nixos/zram.nix
  ];

  hardware.cpu.intel.updateMicrocode = true;

  # Hardware Video Acceleration for Intel UHD 630 (QuickSync / QSV)
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # Primary VA-API / QSV driver for Intel Coffee Lake (UHD 630)
      intel-vaapi-driver # Fallback driver
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  boot = {
    supportedFilesystems = [ "nfs" ];
    kernel.sysctl = {
      "vfs_cache_pressure" = 50;
      "vm.swappiness" = 10;
      "vm.dirty_background_ratio" = 5;
      "vm.dirty_ratio" = 10;
      "net.ipv4.conf.all.arp_ignore" = 1;
      "net.ipv4.conf.all.arp_announce" = 2;
    };
  };

  # Time and locale
  time.timeZone = "Pacific/Auckland";
  i18n.defaultLocale = "en_NZ.UTF-8";

  # Networking: Replicated from tahi with systemd-networkd + nftables
  networking = {
    hostName = hostname;
    useNetworkd = true;
    useDHCP = false;
    nftables.enable = true;
    nameservers = [
      "1.1.1.2"
      "9.9.9.9"
    ];
    defaultGateway = {
      address = "172.16.1.1";
      interface = "eno1";
    };
    firewall = {
      enable = true;
      trustedInterfaces = [ "eno1" "wlan0" ];
      allowedTCPPorts = [
        22 # SSH
        8096 # Jellyfin HTTP
      ];
      allowedUDPPorts = [
        1900 # SSDP
        7359 # Jellyfin client discovery
      ];
    };
    interfaces = {
      eno1 = {
        useDHCP = true;
        ipv4.addresses = [
          {
            address = "172.16.1.220";
            prefixLength = 24;
          }
        ];
        macAddress = "98:fa:9b:0d:e6:58";
      };
      wlan0.useDHCP = true;
    };
    wireless.iwd.enable = true;
  };

  systemd.network.networks."40-eno1" = {
    matchConfig.Name = "eno1";
    networkConfig.DHCP = lib.mkForce "ipv4";
    dhcpV4Config = {
      ClientIdentifier = "mac";
      RouteMetric = 100;
    };
    linkConfig.MACAddress = "98:fa:9b:0d:e6:58";
  };

  systemd.network.networks."40-wlan0" = {
    matchConfig.Name = "wlan0";
    networkConfig.DHCP = lib.mkForce "ipv4";
    dhcpV4Config.RouteMetric = 2048;
  };

  # Trust root certificate from tahi for local secure services
  security.pki.certificateFiles = [
    ../tahi/tahi_root.crt
  ];

  # NFS Mount from tahi for media library
  fileSystems."/data/media" = {
    device = "172.16.1.200:/storage/data/media";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "hard"
      "intr"
      "nfsvers=4.2"
      "_netdev"
    ];
  };

  # Symlinks so Jellyfin library paths match existing structure (/data/tv and /data/movies)
  systemd.tmpfiles.rules = [
    "d /data 0755 root root -"
    "L+ /data/tv - - - - /data/media/tv"
    "L+ /data/movies - - - - /data/media/movies"
  ];

  # 1. Jellyfin Media Server with Intel QuickSync
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    user = "jellyfin";
    group = "jellyfin";
  };
  users.users.jellyfin.extraGroups = [ "video" "render" ];

  # 2. Secondary Redundant Pi-hole (rua-pihole) - Disabled temporarily to get network baseline solid
  # virtualisation.docker = {
  #   enable = true;
  #   autoPrune.enable = true;
  # };
  # virtualisation.oci-containers = {
  #   backend = "docker";
  #   containers.pihole = {
  #     image = "pihole/pihole:latest";
  #     autoStart = true;
  #     ports = [
  #       "53:53/tcp"
  #       "53:53/udp"
  #       "8080:80/tcp"
  #     ];
  #     environment = {
  #       TZ = "Pacific/Auckland";
  #       FTLCONF_LOCAL_IPV4 = "172.16.1.220";
  #       DNSMASQ_LISTENING = "all";
  #       FTLCONF_DNS_LISTENINGMODE = "all";
  #       PIHOLE_DNS_ = "172.16.1.203;1.1.1.1"; # Upstream via tahi-unbound or Cloudflare
  #     };
  #     volumes = [
  #       "/persistent/var/lib/pihole/etc-pihole:/etc/pihole"
  #       "/persistent/var/lib/pihole/etc-dnsmasq.d:/etc/dnsmasq.d"
  #     ];
  #   };
  # };

  services = {
    avahi.enable = true;
    resolved.enable = true;
    udev.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "prohibit-password";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    jellyfin-ffmpeg
    libva-utils # includes `vainfo` for checking Intel QSV acceleration
    nfs-utils
    pciutils
  ];

  # User Configuration
  users = {
    users.${username} = {
      home = "/home/${username}";
      isNormalUser = true;
      extraGroups = [
        "audio"
        "docker"
        "input"
        "network"
        "render"
        "users"
        "video"
        "wheel"
      ];
      initialHashedPassword = "$7$GU..../....S9EPW0eEM5JL4uh1Bo1yr/$bDP2HRn7G8LV8jLV2yj3DQHJJPE0svzRh0Q2fEPePN9";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ rhys@whio"
      ];
    };

    # Temporary fallback user for migration continuity
    users.ruru = {
      home = "/home/ruru";
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialHashedPassword = "$7$GU..../....S9EPW0eEM5JL4uh1Bo1yr/$bDP2HRn7G8LV8jLV2yj3DQHJJPE0svzRh0Q2fEPePN9";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ rhys@whio"
      ];
    };

    users.root = {
      initialHashedPassword = "$7$GU..../....S9EPW0eEM5JL4uh1Bo1yr/$bDP2HRn7G8LV8jLV2yj3DQHJJPE0svzRh0Q2fEPePN9";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFJCkeOcvLsmdbtI/gkuqGSB5XQYLaLdF74M3Ck2vPuQ rhys@whio"
      ];
    };
  };

}
