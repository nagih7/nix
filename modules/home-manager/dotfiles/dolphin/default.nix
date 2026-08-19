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

  home.activation.configureDolphin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SRC="${config.custom.desktopShell.dolphin.rcPath}"
    DEST="${config.xdg.configHome}/dolphinrc"

    # Chỉ copy nếu file nguồn thay đổi hoặc file đích chưa tồn tại
    if [ ! -f "$DEST" ] || [ "$(readlink -f "$DEST")" != "$DEST" ]; then
      echo "Configuring writable dolphinrc..."
      rm -f "$DEST"
      cp -f "$SRC" "$DEST"
      chmod u+w "$DEST"
    fi
  '';
}
