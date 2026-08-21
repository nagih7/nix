# ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗
# ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
# ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
# ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
# ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
# ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
# -------------------------------------------------------------------

{
  config,
  lib,
  pkgs,
  ...
}:

let
  shellHyprland = config.custom.desktopShell.hyprland;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    configType = "lua";
  };

  imports = [
    ./modules
  ];

  # Each source is independently optional: null means the active shell
  # provider doesn't ship that particular file.
  xdg.configFile = {
    "hypr/hyprland/scripts" = lib.mkIf (shellHyprland.scriptsDir != null) {
      source = shellHyprland.scriptsDir;
    };

    # keybinds.conf (hyprlang format) is read by quickshell's get_keybinds.py
    # cheatsheet parser — provide it alongside the Lua config.
    "hypr/hyprland/keybinds.conf" = lib.mkIf (shellHyprland.keybindsConfFile != null) {
      source = shellHyprland.keybindsConfFile;
    };
  };
}
