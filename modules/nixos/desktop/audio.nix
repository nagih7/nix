{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire-pulse."92-virtual-devices" = {
      "pulse.cmd" = [
        { cmd = "load-module"; args = "module-null-sink sink_name=blackhole sink_properties=device.description=BlackHole"; }
        { cmd = "load-module"; args = "module-combine-sink sink_name=multi_output sink_properties=device.description=Multi-Output slaves=easyeffects_sink,easyeffects_source,blackhole"; }
        { cmd = "load-module"; args = "module-remap-source master=blackhole.monitor source_name=blackhole_mic source_properties=device.description=\"BlackHole Source\""; }
      ];
    };
  };

  security.rtkit.enable = true;
  hardware.firmware = [ pkgs.sof-firmware ];

  environment.systemPackages = with pkgs; [
    # pwvucontrol replaced pavucontrol — installed via home-manager
    # (dotfiles/caelestia-shell, caelestia's kbAudioSettings target)
    alsa-utils
    easyeffects
    pulseaudio
  ];
}
