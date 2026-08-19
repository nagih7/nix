# ██╗  ██╗██╗   ██╗██████╗ ██████╗ ██╗      █████╗ ███╗   ██╗██████╗
# ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██║     ██╔══██╗████╗  ██║██╔══██╗
# ███████║ ╚████╔╝ ██████╔╝██████╔╝██║     ███████║██╔██╗ ██║██║  ██║
# ██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══██╗██║     ██╔══██║██║╚██╗██║██║  ██║
# ██║  ██║   ██║   ██║     ██║  ██║███████╗██║  ██║██║ ╚████║██████╔╝
# ╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝
# -------------------------------------------------------------------

{
  config,
  pkgs,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    configType = "lua";
  };

  imports = [
    ./modules
  ];

  xdg.configFile = {
    "hypr/hyprland/scripts".source = config.custom.desktopShell.hyprland.scriptsDir;

    # keybinds.conf (hyprlang format) is read by quickshell's get_keybinds.py
    # cheatsheet parser — provide it alongside the Lua config.
    "hypr/hyprland/keybinds.conf".source = config.custom.desktopShell.hyprland.keybindsConfFile;
  };
}
