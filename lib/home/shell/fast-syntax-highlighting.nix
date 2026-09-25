# ./lib/home/shell/fast-syntax-highlighting.nix
{ pkgs
, lib
, ...
}: {

  programs.zsh = {
    # Disable default zsh-syntax-highlighting in favor of fast-syntax-highlighting
    syntaxHighlighting.enable = lib.mkForce false;

    plugins = [
      {
        name = "fast-syntax-highlighting";
        file = "fast-syntax-highlighting.plugin.zsh";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/plugins/fast-syntax-highlighting";
      }
    ];
  };

}
