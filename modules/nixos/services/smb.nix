{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    cifs-utils
  ];

  fileSystems."/mnt/smb/documents" = {
    device = "//smb.nagih.cloud/documents"; 
    fsType = "cifs";
    options = let
      # Thêm tham số quan trọng _netdev ở cuối chuỗi cấu hình
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,_netdev";
    in [
      "${automount_opts}"
      "credentials=/etc/samba/smb-secrets"
      "uid=1000"
      "gid=100"
      "file_mode=0700"
      "dir_mode=0700"
      "nofail"
      "vers=3.0"
    ];
  };
}
