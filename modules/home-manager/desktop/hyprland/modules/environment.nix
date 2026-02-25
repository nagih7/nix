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
  rawConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/env.conf";

  keysToRemove = [
    "XDG_DATA_DIRS"
  ];

  processedConfig =
    let
      lines = lib.splitString "\n" rawConfig;

      isNotBlacklisted = line: !(lib.any (key: lib.hasInfix key line) keysToRemove);

      processLine =
        line:
        let
          trimmed = lib.strings.trim line;
          cleanLine = lib.removePrefix "env =" (lib.strings.trim trimmed);
        in
        lib.strings.trim cleanLine;

      isValidLine =
        line:
        let
          trimmed = lib.strings.trim line;
        in
        trimmed != "" && !(lib.hasPrefix "#" trimmed) && (isNotBlacklisted trimmed);

    in
    map processLine (builtins.filter isValidLine lines);

    finalConfig = map (line:
      builtins.replaceStrings
        ["QT_QPA_PLATFORMTHEME, kde"]
        ["QT_QPA_PLATFORMTHEME, qt6ct"]
        line
      ) processedConfig;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        "GTK_THEME, catppuccin-mocha-blue-compact"
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
      ]
      ++ finalConfig;
    };
  };
}
