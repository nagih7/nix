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
  # The NixOS module (modules/nixos/desktop/hyprland.nix) owns the Hyprland
  # package, UWSM session and portals; home-manager only renders the config.
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
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

    # Shared Lua modules `require()`d by name from inside generalConfig /
    # envConfig / keybindsConfig (caelestia's hypr/ tree); must sit at their
    # native ~/.config/hypr/ path for Hyprland's Lua `require` to find them.
    "hypr/utils" = lib.mkIf (shellHyprland.utilsDir != null) {
      source = shellHyprland.utilsDir;
    };
    "hypr/variables.lua" = lib.mkIf (shellHyprland.variablesFile != null) {
      source = shellHyprland.variablesFile;
    };
  };
}
