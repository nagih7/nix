#  █████╗ ██╗   ██╗████████╗ ██████╗ ███████╗████████╗ █████╗ ██████╗ ████████╗
# ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗╚══██╔══╝
# ███████║██║   ██║   ██║   ██║   ██║███████╗   ██║   ███████║██████╔╝   ██║
# ██╔══██║██║   ██║   ██║   ██║   ██║╚════██║   ██║   ██╔══██║██╔══██╗   ██║
# ██║  ██║╚██████╔╝   ██║   ╚██████╔╝███████║   ██║   ██║  ██║██║  ██║   ██║
# ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
#------------------------------------------------------------------------------

{
  config,
  lib,
  pkgs,
  hostVars,
  end-4-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/execs.conf";

  keysToRemove = [ ];

  processedEnvFiles =
    let
      lines = lib.splitString "\n" rawConfig;

      isNotBlacklisted = line: !(lib.any (key: lib.hasInfix key line) keysToRemove);

      processLine =
        line:
        let
          trimmed = lib.strings.trim line;
          cleanLine = lib.removePrefix "exec-once =" (lib.strings.trim trimmed);
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
in
{
  wayland.windowManager.hyprland = {
    settings = {
      exec-once = processedEnvFiles ++ [
        # Set monitors
        "${hostVars.nixConfig}/scripts/set_monitors.sh"
        
        # Setup fcitx5
        "fcitx5"
      ];
    };
  };
}
