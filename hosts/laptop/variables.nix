{
  nixConfig = "/home/nagih/Workspaces/config/nixos";
  homeConfig = "/home/nagih/Workspaces/config/nixos/modules/home-manager";

  hostname = "laptop";
  cpu = "intel";
  gpu = "nvidia";
  nameservers = [
    "8.8.8.8"
    "8.8.4.4"
  ];
  firewall = {
    enable = true;
    tcp_ports = [
      80
      443
    ];
    udp_ports = [ ];
    trusted_interfaces = [ "tailscale0" "eno1" ];
  };
  fallback_dns = [
    "1.1.1.1"
    "1.0.0.1"
  ];
  tailscale = {
    enable = true;
  };

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

  git_name = "Nagih";
  git_email = "vuongmanhnghia@gmail.com";

  syncthing = {
    enable = true;

    settings = {
      gui = {
        address = "127.0.0.1:8384";
        user = "nagih";
      };

      devices = {
        "nixos-laptop" = {
          id = "Q2LOGWQ-TERICTE-TXSUI6Q-5ZRDFEG-BEBWGFE-CVKBXTF-XHBSNCN-U6PHIA3";
        };
        "syncthing-server" = {
          id = "6DLXC5P-OYUDW5M-7NYJOSU-3DHKU65-2KECRVD-MEVDAF4-CYTOJWE-7NJXFAF";
          addresses = [ "tcp://14.225.218.83:22000" ];
        };
      };

      folders = {
        "workspaces" = {
          id = "workspaces";
          path = "/home/nagih/Workspaces";
          devices = [
            "nixos-laptop"
            "syncthing-server"
          ];
        };
        "documents" = {
          id = "documents";
          path = "/home/nagih/Documents";
          devices = [
            "nixos-laptop"
            "syncthing-server"
          ];
        };
        "pictures" = {
          id = "pictures";
          path = "/home/nagih/Pictures";
          devices = [
            "nixos-laptop"
            "syncthing-server"
          ];
        };
        "hugo" = {
          id = "hugo";
          path = "/home/nagih/hugo";
          devices = [
            "nixos-laptop"
            "syncthing-server"
          ];
        };
      };
    };
  };
}
