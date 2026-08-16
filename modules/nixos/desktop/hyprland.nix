{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Hyprland core configuration
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Core system services
  services.gvfs.enable = true;
  programs.dconf.enable = true;

  # Without this, /etc/pam.d/hyprlock doesn't exist and hyprlock silently
  # falls back to /etc/pam.d/su, which uses a different (and wrong) auth stack.
  security.pam.services.hyprlock = { };

  # Environment variables for Hyprland
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # Add GCC 15 lib to LD_LIBRARY_PATH for GLIBCXX_3.4.34 (required by Hyprland 0.52.1)
  environment.sessionVariables.LD_LIBRARY_PATH = pkgs.lib.mkAfter [ "${pkgs.gcc15.cc.lib}/lib" ];

  environment.systemPackages = with pkgs; [
    gcc15.cc.lib
    (pkgs.writeShellScriptBin "hyprland" ''
      export LD_LIBRARY_PATH="${pkgs.gcc15.cc.lib}/lib:$LD_LIBRARY_PATH"
      exec ${pkgs.hyprland}/bin/Hyprland "$@"
    '')

    # === HYPRLAND UTILITIES ===
    hyprpicker
    hyprcursor
    nwg-look

    # === WAYLAND UTILITIES ===
    grim # Screenshot utility
    slurp # Region selector
    hyprshot # Screenshot tool for Hyprland
    swappy # Screenshot editor
    wf-recorder # Screen recording
    wtype # Wayland type utility

    # === CLIPBOARD AND NOTIFICATIONS ===
    cliphist # Clipboard manager
    # swaynotificationcenter disabled - quickshell handles notifications

    # === VISUAL AND AUDIO ===
    brightnessctl # Brightness control
    ddcutil # DDC/CI monitor control
    pavucontrol # PulseAudio volume control
    pamixer # PulseAudio mixer
    lxqt.pavucontrol-qt # Qt-based volume control

    # === SYSTEM UTILITIES ===
    playerctl # Media player control
    networkmanagerapplet # Network manager applet
    blueman # Bluetooth manager
    wlogout # Logout menu
    wdisplays # Display configuration

    # === MULTIMEDIA ===
    cheese # Webcam utility

    # === ADDITIONAL TOOLS ===
    tesseract # OCR tool
    ffmpeg # Multimedia framework

    # === AUDIO AND NOTIFICATIONS ===
    libnotify
    glib # For gsettings
    gsettings-desktop-schemas # For gsettings schemas

    # === UTILITIES ===
    procps # Process utilities (pidof, etc.)
    util-linux # System utilities
    findutils # File finding utilities
    gnugrep # GNU grep
    gnused # GNU sed
    gawk # GNU awk
    bash # Bash shell
  ];
}
