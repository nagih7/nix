# ███████╗███╗   ██╗██╗   ██╗██╗██████╗  ██████╗ ███╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
# ██╔════╝████╗  ██║██║   ██║██║██╔══██╗██╔═══██╗████╗  ██║████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
# █████╗  ██╔██╗ ██║██║   ██║██║██████╔╝██║   ██║██╔██╗ ██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║
# ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██╔══██╗██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║
# ███████╗██║ ╚████║ ╚████╔╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║ ╚═╝ ██║███████╗██║ ╚████║   ██║
# ╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝
#------------------------------------------------------------------------------------------------

{
  config,
  lib,
  pkgs,
  end-4-dots,
  ...
}:

let
  dotConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/env.conf";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        "GDK_SCALE, 1"
        "ELM_SCALE, 1"
        "QT_SCALE_FACTOR, 1"

        # === CURSOR THEME ===
        "XCURSOR_THEME, apple-cursor"
        "XCURSOR_SIZE, 24"
        "HYPRCURSOR_THEME, apple-cursor"
        "HYPRCURSOR_SIZE, 24"

        "GTK_IM_MODULE, fcitx5"
        "QT_IM_MODULE, fcitx5"
        "XMODIFIERS, @im=fcitx5"
        "INPUT_METHOD, fcitx5"
        "SDL_IM_MODULE, fcitx5"

        "XDG_DATA_DIRS, $HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"
      ];
    };
    extraConfig = dotConfig;
  };
}
