{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  fileSystems."/mnt/smb" = {
    device = "//smb.nagih.cloud/";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
    in [
      "${automount_opts}"
      "credentials=/etc/nixos/smb-secrets"
      "uid=1000"
      "gid=100"
      "file_mode=0700"
      "dir_mode=0700"
      "nofail"
    ];
  };
}
