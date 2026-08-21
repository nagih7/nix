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
