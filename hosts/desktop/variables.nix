# Schema: modules/nixos/host-options.nix
{
  hostname = "desktop";
  nixConfig = "/home/nagih/Workspaces/config/nixos";

  cpu = "intel";
  gpu = "nvidia";

  nameservers = [
    "8.8.8.8"
    "8.8.4.4"
  ];
  fallbackDns = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  firewall = {
    tcpPorts = [
      80
      443
      9757
    ];
    udpPorts = [
      5353
      9757
    ];
    # NOTE: a trusted interface bypasses the firewall entirely. eno1 is the
    # LAN NIC, so every port (incl. sshd) is reachable from the local network.
    trustedInterfaces = [
      "tailscale0"
      "eno1"
    ];
  };

  tailscale.enable = true;

  users = [
    {
      name = "Nagih";
      username = "nagih";
      description = "Vuong Manh Nghia";
      email = "vuongmanhnghia@gmail.com";
      git_name = "Nagih";
      git_email = "vuongmanhnghia@gmail.com";
    }
  ];
}
