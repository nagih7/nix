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
        "tailscale"
        "wg"
      ];
      shell = pkgs.zsh; # Default shell (zsh)
    };
  };
in
{
  imports = [
    ../../modules/nixos
  ];

  # === USER ACCOUNT CONFIGURATION ===
  config = {
    system.stateVersion = systemVars.nixVersion;
    programs.zsh.enable = true;

    # === USER ACCOUNT CONFIGURATION ===
    users.users = builtins.listToAttrs (map mkUserConfig hostVars.users);

    nix.settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://mirrors.bfsu.edu.cn/nix-chan"
      ];
    };
  };
}

