{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    terraform
    ansible
    vagrant
  ];
}
