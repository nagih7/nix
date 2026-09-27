{
  config,
  pkgs,
  lib,
  ...
}:

let
  # The AppImage is behind a Cisco login, so it can't be fetched. requireFile
  # keeps the flake pure: add it once with
  #   nix-store --add-fixed sha256 packettracer.AppImage
  # and the build finds it by hash.
  src = pkgs.requireFile {
    name = "packettracer.AppImage";
    hash = "sha256-Pv47+xsBslKtPuTIjVukjW83Ef3pS3JL0mzBpNPKtHc=";
    message = ''
      Download Cisco Packet Tracer 9.0.0 (packettracer.AppImage) from
      https://www.netacad.com and run:
        nix-store --add-fixed sha256 packettracer.AppImage
    '';
  };

  cisco-packet-tracer = pkgs.appimageTools.wrapType2 rec {
    pname = "cisco-packet-tracer";
    version = "9.0.0";

    inherit src;

    extraPkgs =
      pkgs: with pkgs; [
        libpng
        libxkbfile

        qt5.qtbase
        qt5.qtmultimedia

        libxcb
        xcb-util-cursor
        # xcb-util-image
        # xcb-util-keysyms
        # xcb-util-renderutil
        # xcb-util-wm

        libGL
        libdrm
        mesa

        dbus
        fontconfig
        freetype
      ];

    extraInstallCommands = ''
      source ${pkgs.makeWrapper}/nix-support/setup-hook

      wrapProgram $out/bin/cisco-packet-tracer \
        --set QT_QPA_PLATFORM xcb \
        --prefix QT_PLUGIN_PATH : "${pkgs.qt5.qtbase}/${pkgs.qt5.qtbase.qtPluginPrefix}"
    '';

    meta = with lib; {
      description = "Cisco Packet Tracer - Network simulation tool";
      homepage = "https://www.netacad.com/courses/packet-tracer";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
    };
  };

  ciscoPacketTracerDesktopItem = pkgs.makeDesktopItem {
    name = "cisco-packet-tracer";
    desktopName = "Cisco Packet Tracer";
    exec = "cisco-packet-tracer";
    icon = "cisco-packet-tracer";
    terminal = false;
    categories = [ "Development" ];
    startupWMClass = "cisco-packet-tracer";
  };
in
{
  home.packages = with pkgs; [
    cisco-packet-tracer
    ciscoPacketTracerDesktopItem
  ];
}
