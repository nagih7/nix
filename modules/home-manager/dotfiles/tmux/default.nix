{
  config,
  pkgs,
  hostVars,
  nagih7-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${nagih7-dots}/tmux/.tmux.conf";

  finalConfig =
    builtins.replaceStrings
      [ "set -g status on" ".tmux.conf" "set -g @continuum-restore 'on'" "~/scratch/notes.md" ]
      [ "set -g status off" "tmux.conf" " " "~/Documents/Scratch/notes.md" ]
      rawConfig;
in

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      sensible
      catppuccin
      cpu
      weather
    ];

    extraConfig = finalConfig;
  };

  home.packages = with pkgs; [
    pkgs.unstable.tmuxinator
  ];

  home.shellAliases = {
    mux = "tmuxinator";
  };

  home.sessionVariables = {
    TMUXINATOR_CONFIG = "${config.home.homeDirectory}/Workspaces/tmuxinator";
  };
}
