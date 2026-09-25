# ./lib/home/shell.nix
{ config
, pkgs
, ...
}: {

  imports = [
    ./shell/bat.nix
    ./shell/deja.nix
    ./shell/eza.nix
    ./shell/fast-syntax-highlighting.nix
    ./shell/fastfetch.nix
    ./shell/fzf.nix
    ./shell/starship.nix
    ./shell/zoxide.nix
    ./shell/zsh.nix
  ];

  home.sessionPath = [
    "${config.home.homeDirectory}/.dotfiles/bin"
  ];

  home.packages = with pkgs; [
    #+----- Shell & CLI Tools ---------------------
    fd # Simple, fast and user-friendly alternative to `find`
    jq # Needed for many Waybar scripts
    ripgrep # Search tool
    #terminaltexteffects # Screensaver
    wget # Classic command-line file downloader
  ];

}
