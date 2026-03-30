{ config, pkgs, ... }:
let
  notion-repackaged = pkgs.stdenvNoRuntimeDeps.mkDerivation rec {
    pname = "notion-app";
    version = "3.0.0-1";
    src = pkgs.fetchurl {
      url = "https://github.com/aokellermann/notion-repackaged/releases/download/v${version}/Notion-${version}.AppImage";
      sha256 = "sha256-1l46cyv49025wscykpkzf0kkwdz8rykm83a2gw1nd08fx71xp8jc";
    };
    dontUnpack = true;
    dontConfigure = true;
    installPhase = ''
      mkdir -p $out/bin
      ${pkgs.appimageTools}/bin/appimageTools.wrapType2 rec {
        inherit pname version src;
        extraPkgs = pkgs: [ pkgs.alsa-lib pkgs.at-spi2-atk pkgs.cups pkgs.dbus pkgs.glib pkgs.gtk3 pkgs.libdrm pkgs.libxkbcommon pkgs.pango pkgs.systemd pkgs.xorg.libX11 pkgs.xorg.libXScrnSaver pkgs.xorg.libXcomposite pkgs.xorg.libXcursor pkgs.xorg.libXdamage pkgs.xorg.libXext pkgs.xorg.libXfixes pkgs.xorg.libXi pkgs.xorg.libXrandr pkgs.xorg.libXrender pkgs.xorg.libXtst pkgs.xorg.libxcb ];
        extraInstallCommands = ''
          install -m 444 -D ${pkgs.appimageTools.extract { inherit pname version src; }}/${pname}.desktop $out/share/applications/${pname}.desktop
          substituteInPlace $out/share/applications/${pname}.desktop --replace 'Exec=AppRun' 'Exec=${pname}'
          cp -r ${pkgs.appimageTools.extract { inherit pname version src; }}/usr/share/icons $out/share
        '';
      }/bin/* -> $out/bin/${pname}
    '';
    meta.platforms = [ "x86_64-linux" ];
    mainProgram = "notion-app";
  };
in {
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [ notion-repackaged ];
}
