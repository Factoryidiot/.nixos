# ./lib/nixos/default.nix
{ ...
}:
{

  imports = [
    ./arr.nix
    ./core.nix
    ./pihole.nix
    ./step-ca.nix
    ./traefik.nix
    ./unbound.nix
  ];

}
