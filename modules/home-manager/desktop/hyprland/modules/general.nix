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
  pkgs,
  hostVars,
  end-4-dots,
  ...
}:

let
  dotConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/general.lua";
in
{
  wayland.windowManager.hyprland = {
    # Keyboard has physical Alt and Win keys swapped at firmware level:
    # physical Win → Mod1 (Alt), physical Alt → Mod4 (Super).
    # Swap them back so Win = Super and Alt = Alt.
    extraConfig = dotConfig + ''

      hl.config({input = {kb_options = "altwin:swap_lalt_lwin"}})
    '';
  };
}
