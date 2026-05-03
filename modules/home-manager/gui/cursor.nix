{ config, pkgs, ... }:

{
  # === CURSOR THEME CONFIGURATION ===
  home.pointerCursor = {
    name = "macOS";
    package = pkgs.apple-cursor;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # === ENSURE CURSOR THEME FILES ARE AVAILABLE ===
  home.packages = with pkgs; [
    apple-cursor
  ];
}
