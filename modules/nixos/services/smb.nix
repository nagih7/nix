{
  config,
  pkgs,
  ...
}:

let
  # Prefer the agenix-managed credentials file (secrets/smb-credentials.age);
  # fall back to the hand-placed one until it exists.
  credentials =
    if config.age.secrets ? smb-credentials then
      config.age.secrets.smb-credentials.path
    else
      "/etc/samba/smb-secrets";
in
{
  environment.systemPackages = with pkgs; [ cifs-utils ];

  fileSystems."/mnt/smb/documents" = {
    device = "//smb.nagih.cloud/documents";
    fsType = "cifs";
    options = [
      # Lazy automount that doesn't block boot when the share is unreachable.
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "_netdev"
      "nofail"
      "credentials=${credentials}"
      "uid=1000"
      "gid=100"
      "file_mode=0700"
      "dir_mode=0700"
      "vers=3.0"
    ];
  };
}
