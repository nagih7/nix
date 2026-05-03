{ config, pkgs, ... }:

{
  home.file.".config/chrome-flags.conf".text = ''
    --password-store=gnome-libsecret
    --ozone-platform-hint=wayland
    --gtk-version=4
    --ignore-gpu-blocklist
    --enable-features=TouchpadOverscrollHistoryNavigation
    --enable-wayland-ime
  '';

  home.file.".config/code-flags.conf".text = ''
    --password-store=gnome-libsecret
    --ozone-platform-hint=wayland
    --gtk-version=4
    --ignore-gpu-blocklist
    --enable-features=TouchpadOverscrollHistoryNavigation
    --enable-wayland-ime
  '';

  home.file.".config/thorium-flags.conf".text = ''
    --password-store=gnome-libsecret
    --ozone-platform-hint=wayland
    --gtk-version=4
    --ignore-gpu-blocklist
    --enable-features=TouchpadOverscrollHistoryNavigation
  '';
}
