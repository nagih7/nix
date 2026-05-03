{
  config,
  lib,
  pkgs,
  hostVars,
  ...
}:

{
  # SYSTEM-LEVEL
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

  # ENVIRONMENT VARIABLES
  home.sessionVariables = {
    GTK_IM_MODULE = lib.mkForce "fcitx";
    QT_IM_MODULE = lib.mkForce "fcitx";
    XMODIFIERS = lib.mkForce "@im=fcitx";
    SDL_IM_MODULE = lib.mkForce "fcitx";
    GLFW_IM_MODULE = lib.mkForce "fcitx";
    FCITX_ENABLE_WAYLAND = lib.mkForce "1";
  };

  # CONFIGURATION
  xdg.configFile."fcitx5".source = ./config;

  # AUTOSTART
  xdg.configFile."autostart/fcitx5.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Name=Fcitx 5
      GenericName=Input Method
      Comment=Start Input Method
      Exec=fcitx5 -d
      Icon=fcitx
      Terminal=false
      Type=Application
      Categories=System;Utility;
      StartupNotify=false
      X-GNOME-Autostart-Phase=Applications
      X-GNOME-AutoRestart=false
      X-GNOME-Autostart-Notify=false
      X-KDE-autostart-after=panel
      Hidden=false
    '';
  };
}
