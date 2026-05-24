{ config, pkgs, ... }:

{
  # Display manager
  services.xserver = {
    enable = true;
  };

  services.displayManager = {
    gdm = {
      enable = false;
    };
    sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  # Hyprland is configured in hyprland.nix
  services.desktopManager = {
    plasma6 = {
      enable = false;
    };
    gnome = {
      enable = false;
    };
  };

  # Raise the nofile soft limit system-wide. SDDM starts with the default
  # PAM soft limit (1024), and Hyprland's exec-once children (quickshell,
  # wl-paste, seafile-applet, ...) inherit it before Hyprland bumps its own
  # limit. End-4's quickshell (Qt + DBus SNI + hyprctl polling + file
  # watchers) leaks past 1024 FDs after a few hours and crashes with
  # "QProcess: Cannot create pipe (Too many open files)".
  security.pam.loginLimits = [
    { domain = "*"; type = "soft"; item = "nofile"; value = "524288"; }
    { domain = "*"; type = "hard"; item = "nofile"; value = "524288"; }
  ];
  systemd.settings.Manager.DefaultLimitNOFILE = "524288:524288";
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=524288:524288
  '';
}
