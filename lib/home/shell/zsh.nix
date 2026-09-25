# ./lib/home/zsh.nix
{ config
, ...
}: {

  home.persistence."/persistent" = {
    files = [
      ".config/zsh/.zsh_history"
    ];
  };

  programs.zsh = {
    enable = true;

    autocd = true;

    dotDir = "${config.home.homeDirectory}/.config/zsh";

    history = {
      ignoreAllDups = true;
      path = "${config.programs.zsh.dotDir}/.zsh_history";
      save = 10000;
      size = 10000;
    };

    setOptions = [
      #+----- History ----------------------------
      "APPEND_HISTORY"
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_FIND_NO_DUPS"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_REDUCE_BLANKS"
      "INC_APPEND_HISTORY"
      "SHARE_HISTORY"
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

    zplug = {
      enable = true;
      zplugHome = "${config.programs.zsh.dotDir}/.zplug";
      plugins = [
        #{ name = "zsh-users/zsh-history-substring-search"; }
        #{ name = "jeffreytse/zsh-vi-mode"; }
      ];
    };

  };

}
