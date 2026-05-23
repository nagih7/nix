{
  config,
  pkgs,
  lib,
  end-4-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${end-4-dots}/dots/.config/dolphinrc";
in
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

  # xdg.configFile."dolphinrc".source = config.lib.file.mkOutOfStoreSymlink "${end-4-dots}/dots/.config/dolphinrc";

  home.activation.configureDolphin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SRC="${end-4-dots}/dots/.config/dolphinrc"
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
