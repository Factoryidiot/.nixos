# ./lib/nixos/nvidia.nix
{ config
, lib
, ...
}: {

  hardware = {

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      open = lib.mkDefault false;
      package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

      # Nvidia power management.
      powerManagement = {
        enable = true;
        finegrained = lib.mkDefault false;
      };
    };
  };

  # Mitigate upstream NVIDIA Bug #1289 / #1371:
  # Conceal display VRR capabilities from the driver to prevent nvDIFRPrefetchSurfaces
  # from entering an infinite spinloop and deadlocking KMS pmlock upon display wake/modeset.
  boot.extraModprobeConfig = ''
    options nvidia-modeset conceal_vrr_caps=1
  '';

  # for Nvidia GPU
  services.xserver.videoDrivers = [ "nvidia" ]; # will install nvidia-vaapi-driver by default

}

