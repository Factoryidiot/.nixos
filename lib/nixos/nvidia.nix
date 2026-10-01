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

  # Mitigate upstream NVIDIA Bug #1289 / #1371 & RTD3 EVO Pushbuffer Deadlock:
  # 1. Conceal display VRR capabilities from the driver to prevent nvDIFRPrefetchSurfaces
  #    from entering an infinite spinloop and deadlocking KMS pmlock upon display wake/modeset.
  # 2. Explicitly disable Runtime D3 (RTD3). On Ada Lovelace notebook GPUs, the driver
  #    defaults to 0x02 (fine-grained RTD3). When an external display is driven via
  #    the dGPU (HDMI-A-1 on whio), entering RTD3 stalls the EVO pushbuffer (nvWriteGpEntry deadlock).
  boot.extraModprobeConfig = ''
    options nvidia-modeset conceal_vrr_caps=1
    options nvidia NVreg_DynamicPowerManagement=0x00
  '';

  # for Nvidia GPU
  services.xserver.videoDrivers = [ "nvidia" ]; # will install nvidia-vaapi-driver by default

}

