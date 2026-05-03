{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch
  ];

  xdg.configFile."fastfetch".source = ./config;

  home.shellAliases = {
    ff = "fastfetch";
    neofetch = "fastfetch";
  };
}
