{
  config,
  userName,
  ...
}:

{
  services.tailscale = {
    enable = config.host.tailscale.enable;
    useRoutingFeatures = "client";
    openFirewall = true;
    # Consumed by tailscaled-autoconnect once authKeyFile is set (secrets.nix).
    extraUpFlags = [
      "--operator=${userName}"
      "--accept-dns=false"
      "--no-tpm"
    ];
  };
}
