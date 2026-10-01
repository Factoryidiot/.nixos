# ./lib/nixos/asus.nix
{ inputs
, lib
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  unstable-asusctl = inputs.nixpkgs-unstable.legacyPackages.${system}.asusctl;
  unstable-supergfxctl = inputs.nixpkgs-unstable.legacyPackages.${system}.supergfxctl;
in
{

  environment.systemPackages = [
    unstable-asusctl
    unstable-supergfxctl
  ];

  services.asusd = {
    enable = true;
    asusdConfig.text = ''
      (
        charge_control_end_threshold: 80,
        base_charge_control_end_threshold: 80,
        disable_nvidia_powerd_on_battery: true,
        ac_command: "",
        bat_command: "",
        platform_profile_linked_epp: true,
        platform_profile_on_battery: Quiet,
        change_platform_profile_on_battery: true,
        platform_profile_on_ac: Performance,
        change_platform_profile_on_ac: true,
        profile_quiet_epp: Power,
        profile_balanced_epp: BalancePower,
        profile_custom_epp: Performance,
        profile_performance_epp: Performance,
        ac_profile_tunings: {
          Performance: (
            enabled: false,
            group: {},
          ),
        },
        dc_profile_tunings: {},
        armoury_settings: {},
      )
    '';
    # enableUserService = true;
    package = unstable-asusctl;
  };

  services.supergfxd.enable = lib.mkDefault false;

  #+----- Impermanence Persistence -------------
  # Modular persistence: persist ROG laptop charge limit, lighting, and fan profiles
  environment.persistence."/persistent" = {
    directories = [
      "/etc/asusd"
    ];
  };

}
