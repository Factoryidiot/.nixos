# lib/nixos/secrets.nix
{ inputs
, specialArgs
, ...
}:
let
  inherit (specialArgs) username;
in
{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/persistent/etc/ssh/ssh_host_ed25519_key"
  ];
  age.secrets = {
    "git-config" = {
      file = ../../secrets/git-config.age;
      owner = username;
    };
    "github-token" = {
      file = ../../secrets/github.age; # Make sure this matches the filename!
      owner = username;
    };
  };

  #+----- Impermanence Persistence -------------
  # Modular persistence: persist Agenix keys and decryption state
  environment.persistence."/persistent" = {
    directories = [
      "/etc/agenix"
      "/var/lib/agenix"
    ];
  };

}
