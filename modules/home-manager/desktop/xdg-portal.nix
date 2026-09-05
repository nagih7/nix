{ config, pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
    configPackages = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    xdgOpenUsePortal = true;
  };

  # OpenURI pinned to kde: xdg-open detects DE=flatpak on this system
  # (xdg-utils' upstream heuristic false-positives on a stray
  # /run/user/$UID/flatpak-info) and always calls OpenURI.OpenFile via the
  # portal rather than consulting mimeapps.list directly. Without an explicit
  # preference here it falls to the "default" (hyprland;gtk), and neither
  # backend correctly resolves inode/directory to Dolphin's mimeapps.list
  # entry the way KDE's KApplicationTrader-based resolution does.
  xdg.configFile."xdg-desktop-portal/hyprland-portals.conf".text = ''
    [preferred]
    default=hyprland;gtk
    org.freedesktop.impl.portal.FileChooser=kde
    org.freedesktop.impl.portal.OpenURI=kde
  '';
}
