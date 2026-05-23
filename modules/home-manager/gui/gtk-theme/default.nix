{ config, pkgs, ... }:

{
  # === GTK THEME CONFIGURATION ===
  gtk = {
    enable = true;

    theme = {
      name = "Catppuccin-Mocha-Compact-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        size = "compact";
        variant = "mocha";
      };
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
      gtk-application-prefer-dark-theme = true;
      gtk-theme-name = "Catppuccin-Mocha-Compact-Blue-Dark";
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-cursor-theme-name = "macOS";
      gtk-font-name = "JetBrainsMono Nerd Font 11";
    };

    gtk3.extraCss = ''
      @import url("matugen.css");
    '';

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
      gtk-theme-name = "Catppuccin-Mocha-Compact-Blue-Dark";
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-cursor-theme-name = "macOS";
      gtk-font-name = "JetBrainsMono Nerd Font 11";
    };

    gtk4.extraCss = ''
      @import url("matugen.css");
    '';
  };

  # === QT THEME CONFIGURATION ===
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # === CUSTOM ICONS ===
  xdg.dataFile."icons/custom".source = ./icons;
}
