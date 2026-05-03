{ pkgs, ... }:

{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      stdenv.cc.cc
      openssl
      glibc
      zlib
      libgcc
    ];
  };
}
