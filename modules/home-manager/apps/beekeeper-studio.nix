{
  config,
  pkgs,
  lib,
  ...
}:

let
  pname = "beekeeper-studio";
  version = "5.5.6";

  src = pkgs.fetchurl {
    url = "https://github.com/beekeeper-studio/beekeeper-studio/releases/download/v${version}/Beekeeper-Studio-${version}.AppImage";
    sha256 = "sha256-skAX39XnmCzAzt8Fp52aLJ+L/IDtviTTqG9hga74Tmw=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };

  iconPath = "${appimageContents}/usr/share/icons/hicolor/512x512/apps/beekeeper-studio.png";

  beekeeper-studio-pkg = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs =
      pkgs: with pkgs; [
        libGL
        vulkan-loader
        libglvnd
        xorg.libX11
      ];
  };

  beekeeperStudioDesktopItem = pkgs.makeDesktopItem {
    name = pname;
    desktopName = "Beekeeper Studio";
    exec = "${pname} --disable-gpu";
    icon = "${iconPath}";
    terminal = false;
    categories = [
      "Development"
      "Database"
    ];
    startupWMClass = "beekeeper-studio";
  };
in
{
  home.packages = [
    beekeeper-studio-pkg
    beekeeperStudioDesktopItem
  ];
}
