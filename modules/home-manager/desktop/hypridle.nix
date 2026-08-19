{
  config,
  ...
}:

{
  services.hypridle.enable = true;

  xdg.configFile."hypr/hypridle.conf".text = config.custom.desktopShell.hypridle.finalConfig;
}
