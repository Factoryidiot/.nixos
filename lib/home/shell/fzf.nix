# ./lib/home/shell/fzf.nix
{ pkgs
, ...
}: {

  programs.fzf = {
    enable = true;

    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --strip-cwd-prefix --exclude .git";
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
    ];

    enableZshIntegration = true; # Adds keybindings and completions

    #+----- CTRL+T File Widget -------------------
    fileWidgetCommand = "${pkgs.fd}/bin/fd --type f --hidden --strip-cwd-prefix --exclude .git";
    fileWidgetOptions = [
      "--preview '${pkgs.bat}/bin/bat --style=numbers,changes --color=always --line-range :500 {}'"
      "--preview-window=right:60%,border-left"
      "--bind=ctrl-/:toggle-preview"
    ];
    #+----- CTRL+R History Widget ----------------
    historyWidgetOptions = [
      "--preview-window=hidden"
      "--sort"
    ];

    tmux.enableShellIntegration = true;
  };

  programs.zsh.zplug.plugins = [
    { name = "Aloxaf/fzf-tab"; }
  ];

}
