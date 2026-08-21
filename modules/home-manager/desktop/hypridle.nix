{
  config,
  lib,
  ...
}:

{
  services.hypridle.enable = true;

  # null means the active shell provider has no hypridle opinion; hypridle
  # stays enabled with its home-manager defaults.
  xdg.configFile."hypr/hypridle.conf" = lib.mkIf (config.custom.desktopShell.hypridle.finalConfig != null) {
    text = config.custom.desktopShell.hypridle.finalConfig;
  };
}
