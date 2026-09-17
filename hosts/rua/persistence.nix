# ./hosts/rua/persistence.nix
{ impermanence
, specialArgs
, ...
}:
let
  inherit (specialArgs) username;
in
{

  imports = [
    impermanence.nixosModules.default
  ];

  environment.persistence."/persistent" = {
    hideMounts = true;
    directories = [
      "/etc/nix/inputs"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/log"
      "/var/lib/docker"
      "/var/lib/pihole"
      {
        directory = "/var/lib/jellyfin";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0750";
      }
      {
        directory = "/var/cache/jellyfin";
        user = "jellyfin";
        group = "jellyfin";
        mode = "0750";
      }
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    users.${username} = {
      directories = [
        ".dotfiles"
        ".nixos"

        {
          directory = ".ssh";
          mode = "0700";
        }
      ];
      files = [
        ".config/zsh/.zsh_history"
      ];
    };
  };

}

