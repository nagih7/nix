{ config, pkgs, ... }:

{
  # === MINIMAL AUDIO CONFIGURATION - NixOS 25.11 Default ===

  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    wireplumber.enable = true;

    wireplumber.configPackages = [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/99-disable-routes.conf" ''
        wireplumber.profiles = {
          main = {
            state-routes.lua = disabled
          }
        }
      '')
    ];
  };

  security.rtkit.enable = true;
  hardware.firmware = [ pkgs.sof-firmware ];

  environment.systemPackages = with pkgs; [
    pavucontrol
    alsa-utils
    sof-firmware
    libopus
    easyeffects
  ];
}
