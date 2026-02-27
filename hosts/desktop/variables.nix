{
  nixConfig = "/home/nagih/Workspaces/config/nixos";
  homeConfig = "/home/nagih/Workspaces/config/nixos/modules/home-manager";

  hostname = "desktop";
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

  syncthing = {
    enable = true;

    settings = {
      gui = {
        address = "127.0.0.1:8384";
        user = "nagih";
      };

      devices = {
        "nixos-desktop" = {
          id = "CQA7ZJT-S4HOWZ5-TZLMHEC-B7XGZB4-XWVA7BM-IPR3RPL-SCTFXIA-O6GSHQQ";
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
            "nixos-desktop"
            "syncthing-server"
          ];
        };
        "documents" = {
          id = "documents";
          path = "/home/nagih/Documents";
          devices = [
            "nixos-desktop"
            "syncthing-server"
          ];
        };
        "pictures" = {
          id = "pictures";
          path = "/home/nagih/Pictures";
          devices = [
            "nixos-desktop"
            "syncthing-server"
          ];
        };
        "hugo" = {
          id = "hugo";
          path = "/home/nagih/hugo";
          devices = [
            "nixos-desktop"
            "syncthing-server"
          ];
        };
      };
    };
  };
}
