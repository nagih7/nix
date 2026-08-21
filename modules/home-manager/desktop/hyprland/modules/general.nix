#  ██████╗ ███████╗███╗   ██╗███████╗██████╗  █████╗ ██╗
# ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗██║
# ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ██████╔╝███████║██║
# ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██║██║
# ╚██████╔╝███████╗██║ ╚████║███████╗██║  ██║██║  ██║███████╗
#  ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
#------------------------------------------------------------

{
  config,
  lib,
  ...
}:

{
  # null means the active shell provider has no general.lua-equivalent.
  wayland.windowManager.hyprland.extraConfig = lib.mkIf (
    config.custom.desktopShell.hyprland.generalConfig != null
  ) config.custom.desktopShell.hyprland.generalConfig;
}
