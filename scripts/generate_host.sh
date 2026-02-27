#!/usr/bin/env bash

# Source utils
_GEN_HOST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${_GEN_HOST_DIR}/lib/utils.sh"

mkdir -p hosts/${HOSTNAME}

writer "Generating hosts/${HOSTNAME}/default.nix..." 0.01

cat > hosts/${HOSTNAME}/default.nix <<EOL
{ hostVars, ... }:

{
  imports = [
    ./hardware-configuration.nix # Hardware configurations
    ../common
  ];
}
EOL

writer "Copying hardware-configuration.nix..." 0.01
cat /etc/nixos/hardware-configuration.nix > hosts/${HOSTNAME}/hardware-configuration.nix

writer "Generating hosts/${HOSTNAME}/variables.nix..." 0.01

cat > hosts/${HOSTNAME}/variables.nix <<EOL
{
  nixConfig = "$(pwd)";
  homeConfig = "$(pwd)/modules/home-manager";

  hostname = "${HOSTNAME}";
  cpu = "${CPU}";
  gpu = "${GPU}";
  nameservers = [ "8.8.8.8" "8.8.4.4" ];
  firewall = {
    enable = ${ENABLE_FIREWALL};
    tcp_ports = [ ${FIREWALL_PORTS//,/ } ];
    udp_ports = [ ];
    trusted_interfaces = [ "tailscale0" ];
  };
  fallback_dns = [ "1.1.1.1" "1.0.0.1" ];

  users = [
    {
      name = "${USERNAME}";
      username = "$(whoami)";
      description = "${USER_DESCRIPTION}";
      email = "${USER_EMAIL}";
      git_name = "${GIT_NAME}";
      git_email = "${GIT_EMAIL}";
    }
  ];

  tailscale = { enable = ${ENABLE_TAILSCALE}; };
  syncthing = { enable = ${ENABLE_SYNCTHING}; };
}
EOL
