{
  config,
  pkgs,
  systemVars,
  hostVars,
  ...
}:

let
  mkUserConfig = user: {
    name = user.username;
    value = {
      isNormalUser = true;
      description = user.description;
      home = "/home/${user.username}";
      extraGroups = [
        "wheel" # Enable sudo
        "networkmanager" # Manage network connections
        "audio" # Access audio devices
        "realtime" # Real-time scheduling
        "video" # Access video devices
        "input" # Access input devices
        "storage" # Access storage devices
        "optical" # Access optical drives
        "scanner" # Access scanners
        "systemd-journal" # Read system logs
        "disk" # Disk management access
        "adbusers" # D-Bus access
        "plugdev" # Hotplug devices
        "gaming" # Gaming optimizations
        "libvirtd" # Libvirt virtualization
        "kvm" # Kernel-based Virtual Machine
        "docker" # Docker container management
        "lp"
        "bluetooth"
      ];
      shell = pkgs.zsh; # Default shell (zsh)
    };
  };
in
{
  imports = [
    # === HARDWARE CONFIGURATION ===
    ../../modules/nixos/hardware/boot # Bootloader and kernel configuration
    ../../modules/nixos/hardware/firmware # Firmware configuration
    ../../modules/nixos/hardware/bluetooth # Bluetooth configuration

    # === SERVICES CONFIGURATION ===
    ../../modules/nixos/services/security # Security hardening (SSH, sudo, etc.)
    ../../modules/nixos/services/resolved
    ../../modules/nixos/services/gaming
    ../../modules/nixos/services/git 
    ../../modules/nixos/services/multimedia # Multimedia services (audio, video, etc.)
    ../../modules/nixos/services/warp 
    ../../modules/nixos/services/tailscale # Tailscale configuration for secure VPN access
    ../../modules/nixos/services/cloudflared # Cloudflared configuration for secure tunneling

    # === DESKTOP CONFIGURATION ===
    ../../modules/nixos/desktop/hyprland
    ../../modules/nixos/desktop/graphics
    ../../modules/nixos/desktop/audio
    ../../modules/nixos/desktop/display
    ../../modules/nixos/desktop/fonts

    # === CORE CONFIGURATION ===
    ../../modules/nixos/core/networking # Networking configuration
    ../../modules/nixos/core/virtualization # Visual enhancements (themes, icons, etc.)

    # === FEATURE CONFIGURATION ===
    ../../modules/nixos/features/cli # CLI tools and utilities
    ../../modules/nixos/features/locale # Locale and language settings
    ../../modules/nixos/features/nix-ld # Nix LDA configuration
  ];

  # === USER ACCOUNT CONFIGURATION ===
  config = {
    system.stateVersion = systemVars.nixVersion;
    programs.zsh.enable = true;

    # === USER ACCOUNT CONFIGURATION ===
    users.users = builtins.listToAttrs (map mkUserConfig hostVars.users);
  };
}
