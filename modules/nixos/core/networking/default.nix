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
      unmanaged = [ "eno1" ];
    };

    firewall = {
      enable = true;
      allowedTCPPorts = hostVars.firewall.tcp_ports;
      allowedUDPPorts = hostVars.firewall.udp_ports;
      trustedInterfaces = hostVars.firewall.trusted_interfaces;
    };

    # ICS
    nat = {
      enable = true;
      externalInterface = "wlp0s20f3";
      internalInterfaces = [ "eno1" ];
    };

    interfaces.eno1.ipv4.addresses = [ {
      address = "192.168.137.1";
      prefixLength = 24;
    } ];
  };

  # Disable NSCD (Name Service Cache Daemon) to avoid conflicts
  services.nscd.enable = false;

  # Force empty NSS modules (often done to fix specific glibc/flake issues)
  system.nssModules = lib.mkForce [ ];
}
