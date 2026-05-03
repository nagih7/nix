{
  config,
  pkgs,
  lib,
  ...
}:

{
  xdg.configFile."wlogout".source = ./config;

  home.shellAliases = {
    logout-menu = "wlogout";
    wl = "wlogout";
  };

  home.sessionVariables = {
    WLOGOUT_STYLE = "${config.xdg.configHome}/wlogout/style.css";
  };
}
