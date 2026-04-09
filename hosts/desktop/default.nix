{ config, hostVars, ... }:

{
  imports = [
    ./hardware-configuration.nix # Hardware configurations
    ../common
  ];

  systemd.services.nvidia-control = {
    enable = true;
    description = "Nvidia Control - Persistence Mode & Clock Lock";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.kernelPackages.nvidia_x11.bin}/bin/nvidia-smi -pm 1";
      ExecStartPost = "${config.boot.kernelPackages.nvidia_x11.bin}/bin/nvidia-smi -lgc 1000,3105";
    };
  };

  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [
    "b9a18a606fa2bc19"
  ];
}
