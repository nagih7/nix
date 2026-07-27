{ lib, hostVars, ... }:

{
  networking = {
    hostName = hostVars.hostname;
    nameservers = hostVars.nameservers;

    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      connectionConfig = {
        "ipv4.ignore-auto-dns" = "yes";
        "ipv6.ignore-auto-dns" = "yes";
      };
    };

    firewall = {
      enable = true;
      allowedTCPPorts = hostVars.firewall.tcp_ports;
      allowedUDPPorts = hostVars.firewall.udp_ports;
      allowedTCPPortRanges = [
        {
          from = 9757;
          to = 9757;
        }
      ];
      trustedInterfaces = hostVars.firewall.trusted_interfaces;
      checkReversePath = "loose";
    };
  };

  # Disable NSCD (Name Service Cache Daemon) to avoid conflicts
  services.nscd.enable = false;

  # Force empty NSS modules (often done to fix specific glibc/flake issues)
  system.nssModules = lib.mkForce [ ];

  systemd.services.NetworkManager-wait-online = {
    enable = true;
  };
  
  # Ensure DNS target is reached before NM activates autoconnect VPNs
  systemd.services."nm-dispatcher" = {
    after = [ "network-online.target" "nss-lookup.target" ];
    wants = [ "network-online.target" ];
  };
}
