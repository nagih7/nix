{ config, ... }:

let
  host = config.host;
in
{
  networking = {
    hostName = host.hostname;
    nameservers = host.nameservers;

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
      allowedTCPPorts = host.firewall.tcpPorts;
      allowedUDPPorts = host.firewall.udpPorts;
      trustedInterfaces = host.firewall.trustedInterfaces;
      checkReversePath = "loose";
    };
  };

  systemd.services.NetworkManager-wait-online.enable = true;

  # Ensure DNS target is reached before NM activates autoconnect VPNs
  systemd.services."nm-dispatcher" = {
    after = [
      "network-online.target"
      "nss-lookup.target"
    ];
    wants = [ "network-online.target" ];
  };
}
