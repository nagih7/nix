{ config, pkgs, ... }:

{
  programs.mpv = {
    enable = true;

    config = {
      keep-open = "yes";

      # Hardware acceleration (adjust based on your GPU)
      hwdec = "auto-safe";
      vo = "gpu";

      # Audio settings
      audio-device = "auto";
      volume-max = 100;

      # Subtitle settings
      sub-auto = "fuzzy";
      sub-font-size = 45;

      # Screenshot settings
      screenshot-format = "png";
      screenshot-png-compression = 8;
      screenshot-template = "~/Pictures/Screenshots/mpv-%F-%P";

      # Performance
      cache = "yes";
      demuxer-max-bytes = "50M";
      demuxer-max-back-bytes = "25M";
    };
  };
}
