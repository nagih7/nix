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
        "video" # Access video devices
        "input" # Access input devices
        "systemd-journal" # Read system logs
        "disk" # Disk management access
        "libvirtd" # Libvirt virtualization
        "kvm" # Kernel-based Virtual Machine
        "docker" # Docker container management
        "lp"
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
        "https://mirrors.bfsu.edu.cn/nix-channels/store"
      ];
    };
  };
}
