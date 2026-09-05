{
  config,
  pkgs,
  lib,
  ...
}:

{
  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kio
    kdePackages.kio-extras
    kdePackages.breeze
    kdePackages.breeze-icons
    kdePackages.plasma-integration
    kdePackages.qqc2-desktop-style
  ];

  # Nothing else claims inode/directory as a default, so xdg-open/xdg-mime
  # falls back to whatever .desktop file opportunistically advertises
  # support for it — which turned out to be kitty's own kitty-open.desktop
  # (its kitten/open_actions helper), silently opening a terminal instead of
  # Dolphin for any app that opens folders via xdg-open rather than exec'ing
  # dolphin directly.
  xdg.mimeApps.defaultApplications."inode/directory" = "org.kde.dolphin.desktop";

  # null means the active shell provider has no dolphinrc opinion.
  home.activation.configureDolphin = lib.mkIf (config.custom.desktopShell.dolphin.rcPath != null) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      SRC="${config.custom.desktopShell.dolphin.rcPath}"
      DEST="${config.xdg.configHome}/dolphinrc"

      if [ ! -f "$DEST" ] || [ "$(readlink -f "$DEST")" != "$DEST" ]; then
        echo "Configuring writable dolphinrc..."
        rm -f "$DEST"
        cp -f "$SRC" "$DEST"
        chmod u+w "$DEST"
      fi
    ''
  );
}
