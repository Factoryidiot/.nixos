# ./lib/home/shell/deja.nix
{ config
, lib
, pkgs
, ...
}:
let
  deja = pkgs.buildGoModule {
    pname = "deja";
    version = "0.4.2";
    src = pkgs.fetchFromGitHub {
      owner = "Giammarco-Ferranti";
      repo = "deja";
      rev = "v0.4.2";
      hash = "sha256-9AzqGDZLlv5BxpuuV3JUfJxW5a2ljZakVHnegQgdO+0=";
    };
    vendorHash = "sha256-XHcZUtx82zT3yPCYzJG+a7zfARPW4clbMn77/4luskw=";
    subPackages = [ "cmd/deja" ];
    doCheck = false;
  };
in
{
  home.packages = [
    deja
  ];

  # Co-located persistence for Deja's SQLite DB, models, and session sockets
  home.persistence."/persistent" = {
    directories = [
      ".local/share/deja"
    ];
  };

  programs.zsh = {
    # Deja replaces zsh-autosuggestions; disable to prevent conflicts
    autosuggestion.enable = lib.mkForce false;

    initContent = ''
      # Move Deja alternatives cycling to Ctrl+N so fzf-tab keeps Tab
      export DEJA_CYCLE_KEY='^N'
    '';

    zplug.plugins = [
      { name = "Giammarco-Ferranti/deja"; }
    ];
  };
}
