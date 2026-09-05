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
  hostVars,
  ...
}:

let
  rawConfig = config.custom.desktopShell.hyprland.execsConf;

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

  qsConfig = config.custom.desktopShell.name;

  # All autostart commands; substitute the hyprlang $qsConfig var (no Lua vars).
  allExecs = map (lib.replaceStrings [ "$qsConfig" ] [ qsConfig ]) (
    processedEnvFiles
    ++ [
      # Start quickshell with env re-sourced so XDG_DATA_DIRS is correct, and
      # via `uwsm app` rather than a raw exec: launched directly from
      # hyprland.start (very early in the session), quickshell ends up a
      # direct child of the compositor's own systemd service instead of a
      # proper app scope. Every app it later launches inherits that same
      # unscoped placement, which xdg-desktop-portal's caller-verification
      # can't identify correctly — so any portal call those apps make (e.g.
      # "open containing folder") silently fails, even after a full
      # logout/login. Only killing and manually restarting quickshell later
      # (once the session is fully settled) puts it in a normal scope.
      "bash -c 'source /etc/set-environment 2>/dev/null; uwsm app -- qs -c ${qsConfig}'"
      "fcitx5"
    ]
  );

  # Lua mode: exec-once becomes hl.exec_cmd(...) inside a hyprland.start hook.
  execLines = lib.concatMapStringsSep "\n" (
    c: "  hl.exec_cmd(${lib.generators.toLua { } c})"
  ) allExecs;

  luaConfig = ''
    -- autostart (migrated from execs.conf exec-once)
    hl.on("hyprland.start", function()
    ${execLines}
    end)
  '';
in
{
  # null means the active shell provider has no execs.conf-equivalent to
  # migrate into an autostart hook.
  wayland.windowManager.hyprland.extraConfig = lib.mkIf (rawConfig != null) luaConfig;
}
