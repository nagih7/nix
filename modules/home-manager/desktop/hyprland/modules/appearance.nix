#  █████╗ ██████╗ ██████╗ ███████╗ █████╗ ██████╗  █████╗ ███╗   ██╗ ██████╗███████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔════╝
# ███████║██████╔╝██████╔╝█████╗  ███████║██████╔╝███████║██╔██╗ ██║██║     █████╗
# ██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██╔══██║██╔══██╗██╔══██║██║╚██╗██║██║     ██╔══╝
# ██║  ██║██║     ██║     ███████╗██║  ██║██║  ██║██║  ██║██║ ╚████║╚██████╗███████╗
# ╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
#-----------------------------------------------------------------------------------

{
  config,
  lib,
  pkgs,
  ...
}:

{
  # configType = "lua" ignores hyprlang-style settings.monitor (it renders
  # each list entry through toLua as a bare string, not the {output=...}
  # table hl.monitor() expects), so the monitor layout has to be set here as
  # raw Lua calls instead. This runs after general.lua's auto-detect
  # hl.monitor({ output = "", mode = "preferred", position = "auto" }) call
  # (home-manager appends module extraConfig in import order, and this
  # module is imported after general.nix), so these calls win.
  wayland.windowManager.hyprland.extraConfig = ''
    -- appearance.lua — manual monitor layout (overrides general.lua's auto-detect)
    hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "0x0", scale = 1 })
    hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@144", position = "-1080x-240", scale = 1, transform = 3 })
  '';
}
