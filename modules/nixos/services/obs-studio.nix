{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
  boot.kernelModules = [ "v4l2loopback" ];

  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=9 card_label="OBS Virtual Camera" exclusive_caps=1
  ''; 

  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
  };

  security.polkit.enable = true;
  services.flatpak.enable = true;
  environment.systemPackages = with pkgs; [ v4l-utils ];
}

