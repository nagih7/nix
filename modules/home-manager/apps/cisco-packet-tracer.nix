{
  config,
  pkgs,
  lib,
  ...
}:

let
  cisco-packet-tracer = pkgs.appimageTools.wrapType2 rec {
    pname = "cisco-packet-tracer";
    version = "9.0.0";

    src = /home/nagih/Documents/packages/CiscoPacketTracer/packettracer.AppImage;

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

    extraInstallCommands =
      let
        contents = pkgs.appimageTools.extractType2 {
          name = "cisco-packet-tracer";
          src = /home/nagih/Documents/packages/CiscoPacketTracer/packettracer.AppImage;
        };
      in
      ''
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
