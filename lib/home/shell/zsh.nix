# ./lib/home/zsh.nix
{ config
, ...
}: {

  programs.zsh = {
    enable = true;

    autocd = true;

    autosuggestion = {
      enable = true;
      strategy = [ "completion" ];
    };

    dotDir = "${config.home.homeDirectory}/.config/zsh";

    history = {
      ignoreAllDups = true;
      path = "${config.programs.zsh.dotDir}/.zsh_history";
      save = 10000;
      size = 10000;
    };

    initContent = ''
      if [ "$TERM" = "linux" ]; then
        fastfetch
      fi
    '';

    setOptions = [
      #+----- Hostory ----------------------------
      "APPEND_HISTORY"
      "SHARE_HISTORY"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_FIND_NO_DUPS"
      #+----- Shell ------------------------------
      "NOBEEP"
      "NUMERIC_GLOB_SORT"
    ];

    shellAliases = {
      diff = "--color=auto";
      grep = "rg --color=auto";
      crash-log = "journalctl -b -1 -p 3 -n 80";
      crash-cores = "coredumpctl list -n 10";
    };

    syntaxHighlighting.enable = true;

    zplug = {
      enable = true;
      zplugHome = "${config.programs.zsh.dotDir}/.zplug";
      plugins = [
        { name = "Aloxaf/fzf-tab"; }
        { name = "zsh-users/zsh-history-substring-search"; }
        #{ name = "jeffreytse/zsh-vi-mode"; }
        #{ name = "zdharma-continuum/fast-syntax-highlighting"; }
      ];
    };

  };

}
