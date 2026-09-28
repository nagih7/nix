{
  config,
  lib,
  ...
}:

{
  # null means the active shell provider has no opinion; stay enabled with
  # home-manager's defaults (matches every provider before caelestia).
  services.hypridle.enable =
    let
      enable = config.custom.desktopShell.hypridle.enable;
    in
    if enable == null then true else enable;

  # null means the active shell provider has no hypridle opinion; hypridle
  # stays enabled with its home-manager defaults.
  xdg.configFile."hypr/hypridle.conf" =
    lib.mkIf (config.custom.desktopShell.hypridle.finalConfig != null)
      {
        text = config.custom.desktopShell.hypridle.finalConfig;
      };
}
