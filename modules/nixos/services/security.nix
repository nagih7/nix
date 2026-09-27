{
  config,
  pkgs,
  lib,
  ...
}:

{
  # === BASIC SECURITY CONFIGURATION ===
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    chromiumSuidSandbox.enable = true;
  };

  # === GNOME KEYRING (org.freedesktop.secrets) ===
  # The keyring is unlocked by PAM on the services that actually authenticate
  # the graphical session: SDDM at login and hyprlock on unlock. Everything
  # else (VS Code, Chrome, secret-tool, git-credential-libsecret) then talks
  # to the daemon over D-Bus without a second password prompt.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services = {
    sddm.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
    # Without this /etc/pam.d/hyprlock doesn't exist and hyprlock silently
    # falls back to /etc/pam.d/su, which uses a different (and wrong) stack.
    hyprlock.enableGnomeKeyring = true;
  };

  boot.kernel.sysctl = {
    "user.max_user_namespaces" = 15000;
    "kernel.unprivileged_userns_clone" = 1;
  };

  # === SSH SECURITY HARDENING ===
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false; # key-only authentication
      PermitRootLogin = "no";
    };
  };

  # Local Caddy CA for *.nagih.cloud services on the LAN.
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
