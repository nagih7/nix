{ config, pkgs, ... }:

{
  # === BASIC SECURITY CONFIGURATION ===
  security = {
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    allowUserNamespaces = true;
  };

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
}
