{ config
, ...
}: {

  programs.fastfetch.enable = true;

  # Run fastfetch automatically on Linux virtual console (TTY)
  programs.zsh.initContent = ''
    if [ "$TERM" = "linux" ]; then
      fastfetch
    fi
  '';

  xdg.configFile = {
    "fastfetch/config.jsonc".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/fastfetch/config.jsonc";
  };

}
