{ pkgs, ... }:

{
  # i18n.inputMethod sets GTK_IM_MODULE / QT_IM_MODULE / XMODIFIERS etc. to
  # "fcitx" (the correct value — "fcitx5" is not a valid IM module name).
  # fcitx5 itself is started by the Hyprland autostart hook.
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-unikey
      ];
    };
  };

  xdg.configFile."fcitx5".source = ./config;
}
