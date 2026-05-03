{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    gcc
    cmake
    gnumake
    gdb
    clang-tools
  ];
}
