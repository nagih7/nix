{ config, pkgs, ... }:

{
  # === GTK THEME CONFIGURATION ===
  # adw-gtk3 is the neutral base targeted by matugen; switchwall.sh swaps
  # between adw-gtk3 / adw-gtk3-dark via gsettings on each wallpaper change,
  # and matugen.css overlays the Material You palette on top.
  gtk = {
    enable = true;

    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "macOS";
      package = pkgs.apple-cursor;
      size = 24;
    };

    font = {
      name = "JetBrainsMono Nerd Font";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-cursor-theme-name = "macOS";
      gtk-font-name = "JetBrainsMono Nerd Font 11";
    };

    gtk3.extraCss = ''
      @import url("matugen.css");
    '';

    gtk4.extraConfig = {
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-cursor-theme-name = "macOS";
      gtk-font-name = "JetBrainsMono Nerd Font 11";
    };

    gtk4.extraCss = ''
      @import url("matugen.css");

      /* LiveCaptions: strip the GTK theme's default window background so the
         app's own transparent-mode CSS (rgba black) is not obscured, and
         force white text with shadow for contrast on any wallpaper. */
      window.transparent-mode {
          background-color: transparent;
          background: transparent;
      }
      window.transparent-mode label {
          color: white;
          text-shadow: 0 1px 6px rgba(0, 0, 0, 1), 0 0 16px rgba(0, 0, 0, 0.8);
      }
    '';
  };

  # Qt platform theme + widget style are handled by kvantum.nix (qt6ct +
  # Kvantum MaterialAdw). Don't redeclare here.

  # === CUSTOM ICONS ===
  xdg.dataFile."icons/custom".source = ./icons;
}
