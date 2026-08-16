{ config, pkgs, ... }:

{
  # === BASIC SECURITY CONFIGURATION ===
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    allowUserNamespaces = true;
  };

  services.gnome.gnome-keyring.enable = true;

  security.chromiumSuidSandbox.enable = true;

  boot.kernel.sysctl = {
    "user.max_user_namespaces" = 15000;
    "kernel.unprivileged_userns_clone" = 1;
  };

  # === SSH SECURITY HARDENING ===
  services.openssh = {
    enable = true; # Enable SSH daemon for remote access
    settings = {
      PasswordAuthentication = false; # Disable password login (key-only authentication)
      PermitRootLogin = "no"; # Disable direct root login for security
    };
  };

  environment.systemPackages = with pkgs; [
    agenix-cli # Secure secret management tool
  ];

  security.pki.certificates = [
    ''
      -----BEGIN CERTIFICATE-----
      MIIBojCCAUmgAwIBAgIQTSTn7GGUCTKLge/PgTYRKjAKBggqhkjOPQQDAjAwMS4w
      LAYDVQQDEyVDYWRkeSBMb2NhbCBBdXRob3JpdHkgLSAyMDI2IEVDQyBSb290MB4X
      DTI2MDYyNDEzMTM1NVoXDTM2MDUwMjEzMTM1NVowMDEuMCwGA1UEAxMlQ2FkZHkg
      TG9jYWwgQXV0aG9yaXR5IC0gMjAyNiBFQ0MgUm9vdDBZMBMGByqGSM49AgEGCCqG
      SM49AwEHA0IABPDojpjjO+RGIUG09+Jab9pFps0wpPkXiHerJmAq5Ui/McHRV0Cy
      YByb3EhUVxrc4WtXuDYjUVcxSEYDRdnLe8mjRTBDMA4GA1UdDwEB/wQEAwIBBjAS
      BgNVHRMBAf8ECDAGAQH/AgEBMB0GA1UdDgQWBBTPtl2EQAQpI7CFwd4U8CuKUPxJ
      +DAKBggqhkjOPQQDAgNHADBEAiAdGvlJkzWQnx9tU69sMun8dycWC7H81xEwJtud
      RJo7fQIgf/4f5rlxSl8TXUbWe6y2BISoW5RRwmnTZs/k4gvsy18=
      -----END CERTIFICATE-----
    ''
  ];
}

