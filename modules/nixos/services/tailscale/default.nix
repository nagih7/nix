{ config, hostVars, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    openFirewall = true;
    extraUpFlags = [
      "--operator=${hostVars.user.name}"
      "--accept-dns=false"
      "--no-tpm"
    ];
  };
}
