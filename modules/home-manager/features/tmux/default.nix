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
      [ "set -g status on" ".tmux.conf" "set -g @continuum-restore 'on'" ]
      [ "set -g status off" "tmux.conf" " " ]
      rawConfig;
in

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      # continuum
      sensible
      catppuccin
      cpu
      weather
    ];

    extraConfig = ''
      ${finalConfig}
    '';
  };

  home.packages = with pkgs; [
    pkgs.unstable.tmuxinator
  ];

  xdg.configFile."tmuxinator".source =
    config.lib.file.mkOutOfStoreSymlink "${hostVars.homeConfig}/features/tmux/tmuxinator";

  home.shellAliases = {
    mux = "tmuxinator";
  };
}
