{
  config,
  pkgs,
  ...
}:

{
  # === STEAM GAMING PLATFORM ===
  programs.steam = {
    enable = true; # Enable Steam gaming platform
    package = pkgs.unstable.steam;
    remotePlay.openFirewall = true; # Allow Steam Remote Play through firewall
    dedicatedServer.openFirewall = true;
    gamescopeSession.enable = true; # Enable Gamescope compositor session for Steam Deck-like experience
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true; # mDNS discovery cho Quest
    openFirewall = true;
  };

  # programs.envision.enable = true;

  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = true;
    package = pkgs.unstable.wivrn.override { cudaSupport = true; };
  };

  # === GAMING PERFORMANCE OPTIMIZATION ===
  programs.gamemode.enable = true; # Enable GameMode for automatic CPU/GPU optimization during gaming

  # === GAMING SOFTWARE PACKAGES ===
  environment.systemPackages = with pkgs; [
    pkgs.unstable.protonup-qt # GUI tool for managing Proton versions (Steam's Wine fork)
    pkgs.unstable.steam-run # Utility for running non-Steam applications with Steam's runtime
    winetricks # Script to install Windows components in Wine prefixes
    wineWow64Packages.waylandFull # Wine version with Wayland support
  ];

  # === GAMING CONTROLLER SUPPORT ===
  # uaccess grants the active seat's user an ACL on the device, which is the
  # standard way to expose input devices instead of chmod'ing to a group.
  services.udev.extraRules = ''
    # PlayStation 4/5 Controllers - DualShock 4 and DualSense support
    SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", TAG+="uaccess"

    # Xbox Controllers - Xbox One and Series X/S controller support
    SUBSYSTEM=="usb", ATTRS{idVendor}=="045e", TAG+="uaccess"

    # Nintendo Switch Pro Controller support
    SUBSYSTEM=="usb", ATTRS{idVendor}=="057e", ATTRS{idProduct}=="2009", TAG+="uaccess"
  '';
}
