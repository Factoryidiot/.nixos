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

  # SSD (/persistent) - Fast I/O: System state, Dotfiles, Development & Configuration
  environment.persistence."/persistent" = {
    hideMounts = true;
    # sets the mount option x-gvfs-hide on all the bind mounts
    directories = [
      "/etc/nix/inputs"
      "/var/lib/iwd"
      "/var/lib/nixos"
      "/var/log" # logs and troubleshooting
    ];

    files = [
      "/etc/machine-id"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
    ];

    # the following directories will be passed to /persistent/home/$USER
    users.${username} = {
      directories = [
        ".dotfiles"
        ".nixos"
        "Documents"
        "Music"
        "Pictures"
        "Projects"
        "tmp"

        {
          directory = ".gnupg";
          mode = "0700";
        }

        {
          directory = ".ssh";
          mode = "0700";
        }

        # misc
        ".config/pulse"
        ".pki"

        #+----- Browser --------------------------
        ".config/Bitwarden"
        #".config/google-chrome"
        #".config/helium"
        #".config/net.imput.helium"
        #".config/BraveSoftware"
        #".config/obsidian"

        #+----- Applications ---------------------
        ".local/share/applications"

        ".local/state"

      ];
    };
  };

  # Storage Drive (/storage) - Bulk & High-Capacity: Steam Games, Videos, VMs, Downloads
  environment.persistence."/storage" = {
    hideMounts = true;
    users.${username} = {
      directories = [
        "Downloads"
        "Videos"
        "Games"
      ];
    };
  };

}
