{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    kdePackages.kdialog
    kdePackages.dolphin
    kdePackages.kio-extras
    python3Packages.kde-material-you-colors
    # Provides plasma-apply-colorscheme, which kde-material-you-colors shells
    # out to in order to write [Colors:*] into ~/.config/kdeglobals.
    kdePackages.plasma-workspace
  ];

  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };

  # kdeglobals is seeded once but left writable so kde-material-you-colors
  # (invoked from matugen/templates/kde/kde-material-you-colors-wrapper.sh on
  # each wallpaper change) can rewrite the [Colors:*] sections. Using
  # home.file with mkForce would lock the palette to the shell provider's
  # snapshot and break dynamic theming for kdialog / xdg-desktop-portal-kde.
  # null means the active shell provider has no kdeglobals opinion.
  home.activation.seedKdeglobals = lib.mkIf (config.custom.desktopShell.kde.kdeglobalsSeed != null) (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      target="${config.home.homeDirectory}/.config/kdeglobals"
      if [ ! -e "$target" ] || [ -L "$target" ]; then
        $DRY_RUN_CMD rm -f "$target"
        $DRY_RUN_CMD install -m 0644 \
          ${pkgs.writeText "kdeglobals-seed" (
            config.custom.desktopShell.kde.kdeglobalsSeed
            + ''
              [KDE]
              widgetStyle=Breeze
            ''
          )} "$target"
      else
        # In-place migrate any pre-existing kdeglobals from the prior
        # widgetStyle=kvantum seed. plasma-apply-colorscheme only touches
        # [Colors:*] sections, so [KDE].widgetStyle stays whatever was seeded
        # first; without this rewrite, an existing user keeps loading Kvantum.
        if ${pkgs.gnugrep}/bin/grep -q '^widgetStyle=kvantum$' "$target"; then
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i 's/^widgetStyle=kvantum$/widgetStyle=Breeze/' "$target"
        fi
      fi
    ''
  );
}
