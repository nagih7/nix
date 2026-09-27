{
  config,
  pkgs,
  systemVars,
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
        "wheel" # sudo
        "networkmanager"
        "audio"
        "video"
        "input"
        "systemd-journal" # read system logs
        "disk"
        "libvirtd"
        "kvm"
        "docker"
        "lp"
      ];
      shell = pkgs.zsh;
    };
  };
in
{
  system.stateVersion = systemVars.nixVersion;
  programs.zsh.enable = true;

  users.users = builtins.listToAttrs (map mkUserConfig config.host.users);

  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://mirrors.bfsu.edu.cn/nix-channels/store"
  ];
}
