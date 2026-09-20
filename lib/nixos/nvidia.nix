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

  # for Nvidia GPU
  services.xserver.videoDrivers = [ "nvidia" ]; # will install nvidia-vaapi-driver by default

}
