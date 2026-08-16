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
  end-4-dots,
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
    "hypr/hyprland/scripts".source = "${end-4-dots}/dots/.config/hypr/hyprland/scripts";

    # keybinds.conf (hyprlang format) is read by quickshell's get_keybinds.py
    # cheatsheet parser — provide it alongside the Lua config.
    "hypr/hyprland/keybinds.conf".source = "${end-4-dots}/dots/.config/hypr/hyprland/keybinds.conf";
  };
}
