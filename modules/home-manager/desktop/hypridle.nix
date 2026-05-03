{
  config,
  lib,
  pkgs,
  end-4-dots,
  ...
}:

{
  services.hypridle.enable = true;

  xdg.configFile."hypr/hypridle.conf".text =
    builtins.readFile "${end-4-dots}/dots/.config/hypr/hypridle.conf";
}
