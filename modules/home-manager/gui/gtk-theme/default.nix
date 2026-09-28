{ config, lib, pkgs, ... }:

let
  # gtk3.extraCss/gtk4.extraCss below only make sense for a provider that
  # actually drives matugen (its switchwall.sh writes ~/.config/gtk-{3,4}.0/
  # matugen.css on every wallpaper change) — same null-means-no-opinion
  # signal gui/matugen/default.nix uses.
  usesMatugen = config.custom.desktopShell.matugen.finalConfig != null;
in
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
      name = "SF Pro Text";
      size = 11;
    };

    gtk3.extraConfig = {
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-cursor-theme-name = "macOS";
      gtk-font-name = "SF Pro Text 11";
    };

    gtk3.extraCss = lib.mkIf usesMatugen ''
      @import url("matugen.css");
    '';

    gtk4.extraConfig = {
      gtk-icon-theme-name = "Papirus-Dark";
      gtk-cursor-theme-name = "macOS";
      gtk-font-name = "SF Pro Text 11";
    };

    # Whole value (not just the matugen.css import) is gated: home-manager
    # must either fully own ~/.config/gtk-4.0/gtk.css (matugen-driven
    # providers) or not touch it at all. Managing it with *some* content
    # (e.g. just the LiveCaptions fix below) still symlinks the file, which
    # collides the same way with a provider whose own tooling writes there
    # directly (caelestia-cli's theme.enableGtk) — see dotfiles/caelestia-shell.
    gtk4.extraCss = lib.mkIf usesMatugen ''
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

  # caelestia-shell's icon lookup (Quickshell.iconPath, see
  # caelestia-dots/utils/Icons.qml) logs "Could not load icon ..." and
  # renders blank for a lot of standard freedesktop icon names. Traced live
  # via `journalctl --user -u caelestia.service`: it resolves icons from
  # exactly two places, regardless of the theme actually configured in GTK
  # (gtk-icon-theme-name=Papirus-Dark) or Qt (kdeglobals [Icons]
  # Theme=breeze-dark) —
  #   1. `hicolor`, any size/category directory (the universal spec
  #      fallback) — confirmed by installing networkmanagerapplet: its
  #      nm-stageNN-connectingNN(-secure) icons land in
  #      hicolor/22x22/apps/ and immediately started resolving.
  #   2. `Adwaita/symbolic/*` specifically — confirmed by installing
  #      adwaita-icon-theme: every missing "-symbolic" name (and generic
  #      MIME/folder names living in Adwaita's non-symbolic dirs, which
  #      apparently still get bundled into the same closure) started
  #      resolving, while a plain (non-symbolic) Adwaita icon that
  #      objectively exists on disk (input-keyboard.svg) did not.
  # Neither Papirus-Dark nor breeze-dark/breeze is ever actually read, even
  # for files that exist directly in them with no Inherits involved (e.g.
  # breeze-dark ships its own preferences-system-network.svg — still fails).
  #
  # So the fix for anything left over after the two packages above is to
  # place it directly under hicolor ourselves, sourced from breeze (which
  # has the best coverage of classic freedesktop names). This is
  # nm-connection-editor's "Advanced Network Configuration" launcher icon
  # (preferences-system-network) plus the handful of others seen going
  # missing the same way.
  home.packages = [
    pkgs.adwaita-icon-theme # *-symbolic, generic MIME/folder/action icons
    pkgs.networkmanagerapplet # nm-stageNN-connectingNN(-secure), nm-no-connection(-secure)
  ];

  xdg.dataFile = {
    "icons/hicolor/scalable/apps/preferences-system-network.svg".source =
      "${pkgs.kdePackages.breeze-icons}/share/icons/breeze/preferences/32/preferences-system-network.svg";
    "icons/hicolor/scalable/apps/utilities-terminal.svg".source =
      "${pkgs.kdePackages.breeze-icons}/share/icons/breeze/apps/64/utilities-terminal.svg";
    "icons/hicolor/scalable/actions/application-exit.svg".source =
      "${pkgs.kdePackages.breeze-icons}/share/icons/breeze/actions/32/application-exit.svg";
    "icons/hicolor/scalable/actions/view-refresh.svg".source =
      "${pkgs.kdePackages.breeze-icons}/share/icons/breeze/actions/32/view-refresh.svg";
    "icons/hicolor/scalable/devices/input-keyboard.svg".source =
      "${pkgs.kdePackages.breeze-icons}/share/icons/breeze/devices/64/input-keyboard.svg";

    # === CUSTOM ICONS ===
    "icons/custom".source = ./icons;
  };
}
