{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
    hyfetch
  ];

  xdg.configFile."fastfetch".source = ./config;

  home.shellAliases = {
    ff = "fastfetch";
    neofetch = "fastfetch";
  };
}
