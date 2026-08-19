# ███████╗███╗   ██╗██╗   ██╗██╗██████╗  ██████╗ ███╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗
# ██╔════╝████╗  ██║██║   ██║██║██╔══██╗██╔═══██╗████╗  ██║████╗ ████║██╔════╝████╗  ██║╚══██╔══╝
# █████╗  ██╔██╗ ██║██║   ██║██║██████╔╝██║   ██║██╔██╗ ██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║
# ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██║██╔══██╗██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║
# ███████╗██║ ╚████║ ╚████╔╝ ██║██║  ██║╚██████╔╝██║ ╚████║██║ ╚═╝ ██║███████╗██║ ╚████║   ██║
# ╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝
#------------------------------------------------------------------------------------------------

{
  config,
  ...
}:

let
  # Lua mode: each env var is a two-argument hl.env(KEY, VALUE) call.
  mkEnv = key: value: { _args = [ key value ]; };
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        (mkEnv "GDK_SCALE" "1")
        (mkEnv "ELM_SCALE" "1")
        (mkEnv "QT_SCALE_FACTOR" "1")

        # === CURSOR THEME ===
        (mkEnv "XCURSOR_THEME" "apple-cursor")
        (mkEnv "XCURSOR_SIZE" "24")
        (mkEnv "HYPRCURSOR_THEME" "apple-cursor")
        (mkEnv "HYPRCURSOR_SIZE" "24")

        (mkEnv "GTK_IM_MODULE" "fcitx5")
        (mkEnv "QT_IM_MODULE" "fcitx5")
        (mkEnv "XMODIFIERS" "@im=fcitx5")
        (mkEnv "INPUT_METHOD" "fcitx5")
        (mkEnv "SDL_IM_MODULE" "fcitx5")
        # XDG_DATA_DIRS intentionally omitted: hl.env() sets literal strings,
        # so $HOME/$XDG_DATA_DIRS would not expand, overriding the NixOS
        # session value and hiding Papirus icons. Use home.sessionVariables.
      ];
    };
    extraConfig = config.custom.desktopShell.hyprland.envConfig;
  };
}
