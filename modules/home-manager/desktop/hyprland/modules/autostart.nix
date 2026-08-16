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

  # Remove the plain "qs -c $qsConfig &" from execs.conf so we can replace it
  # with a wrapper that re-sources /etc/set-environment first. This ensures
  # quickshell gets the correct XDG_DATA_DIRS (Papirus icons) even when
  # Hyprland's process env has a stale/broken value from a previous session.
  keysToRemove = [ "qs -c" ];

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

  qsConfig = "ii";

  # All autostart commands; substitute the hyprlang $qsConfig var (no Lua vars).
  allExecs = map (lib.replaceStrings [ "$qsConfig" ] [ qsConfig ]) (
    processedEnvFiles
    ++ [
      # Start quickshell with env re-sourced so XDG_DATA_DIRS is correct
      "bash -c 'source /etc/set-environment 2>/dev/null; qs -c ${qsConfig} &'"
      # Set monitors
      "${hostVars.nixConfig}/scripts/set_monitors.sh"
      "fcitx5"
    ]
  );

  # Lua mode: exec-once becomes hl.exec_cmd(...) inside a hyprland.start hook.
  execLines = lib.concatMapStringsSep "\n" (c: "  hl.exec_cmd(${lib.generators.toLua { } c})") allExecs;

  luaConfig = ''
    -- autostart (migrated from execs.conf exec-once)
    hl.on("hyprland.start", function()
    ${execLines}
    end)
  '';
in
{
  wayland.windowManager.hyprland = {
    extraConfig = luaConfig;
  };
}
