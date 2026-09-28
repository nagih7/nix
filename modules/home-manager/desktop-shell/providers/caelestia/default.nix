# ██████╗ █████╗ ███████╗██╗     ███████╗███████╗████████╗██╗ █████╗
# ██╔════╝██╔══██╗██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔══██╗
# ██║     ███████║█████╗  ██║     █████╗  ███████╗   ██║   ██║███████║
# ██║     ██╔══██║██╔══╝  ██║     ██╔══╝  ╚════██║   ██║   ██║██╔══██║
# ╚██████╗██║  ██║███████╗███████╗███████╗███████║   ██║   ██║██║  ██║
#  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═╝
# -------------------------------------------------------------------------
# Desktop shell provider for caelestia-dots
# (https://github.com/caelestia-dots/{shell,caelestia}). This is the only
# file that reads from the caelestia-dots flake input - every consumer
# module reads config.custom.desktopShell instead.
#
# Unlike ii, caelestia-shell is a compiled package with its own official
# Home Manager module (programs.caelestia, wired in
# ../../../dotfiles/caelestia-shell) that owns the quickshell package,
# startup (systemd unit) and theming (caelestia-cli). It also draws its own
# lock screen directly on the Wayland session-lock protocol instead of
# hyprlock. So this provider only has an opinion on the Hyprland side;
# every other field (quickshell.*, hyprlock, matugen, kde, dolphin) is left
# null - see dotfiles/caelestia-shell for what fills in for them.

{ pkgs, lib, caelestia-dots }:

let
  hyprDir = "${caelestia-dots}/hypr";
  hyprlandDir = "${hyprDir}/hyprland";

  # execs.lua as shipped assumes an Arch install in three ways that don't
  # hold on NixOS:
  #  1. It starts the shell itself (`hl.exec_cmd("caelestia shell -d")`),
  #     which races the same UWSM cgroup-scoping problem end-4's execs.conf
  #     has (see ../../../desktop/hyprland/modules/autostart.nix): launched
  #     as a bare exec-once, quickshell lands in Hyprland's own scope rather
  #     than a proper session app scope, breaking portal caller verification
  #     for every app it spawns. dotfiles/caelestia-shell starts the shell
  #     instead via the official module's systemd service (properly scoped
  #     under session.slice), so this line is dropped.
  #  2. The polkit agent path is FHS (`/usr/lib/polkit-gnome/...`), which
  #     doesn't exist on NixOS; point it at the store path instead.
  #  3. The geoclue demo agent path is also FHS, and nixpkgs' geoclue2
  #     doesn't even build that demo binary; drop the line. Location-based
  #     features (gammastep's auto day/night, if wanted) need
  #     `services.geoclue2.enable` at the NixOS level instead.
  execsPatched = builtins.replaceStrings
    [
      ''hl.exec_cmd("caelestia shell -d")''
      "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
      ''hl.exec_cmd("/usr/lib/geoclue-2.0/demos/agent")''
    ]
    [
      "-- (shell started via systemd unit instead, see dotfiles/caelestia-shell)"
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "-- (dropped: no NixOS equivalent binary; use services.geoclue2.enable if needed)"
    ]
    (builtins.readFile "${hyprlandDir}/execs.lua");

  # hyprland.lua (the vendor's own entry point) requires each of these in
  # this order; concatenating their bodies into one extraConfig blob rather
  # than symlinking the whole tree and relying on Lua `require` mirrors the
  # same pattern the ii provider already uses for general.lua/env.lua. Each
  # file re-imports its own `variables`/`scheme.current`/`utils.functions`
  # locals via `require`, so concatenation order is safe here (repeated
  # `local` declarations shadow, they don't collide) as long as
  # variables.lua/utils/ actually exist on disk at ~/.config/hypr/ for those
  # `require()` calls to resolve - see hyprland.{utilsDir,variablesFile}
  # below and desktop/hyprland/default.nix's xdg.configFile entries.
  generalFiles = [
    "${hyprlandDir}/general.lua"
    "${hyprlandDir}/input.lua"
    "${hyprlandDir}/misc.lua"
    "${hyprlandDir}/animations.lua"
    "${hyprlandDir}/decoration.lua"
    "${hyprlandDir}/group.lua"
    "${hyprlandDir}/rules.lua"
    "${hyprlandDir}/gestures.lua"
  ];

  combinedGeneralConfig =
    lib.concatMapStringsSep "\n\n" builtins.readFile generalFiles
    + "\n\n"
    + execsPatched;
in
{
  name = "caelestia";

  hyprland = {
    generalConfig = combinedGeneralConfig;
    envConfig = builtins.readFile "${hyprlandDir}/env.lua";
    keybindsConfig = builtins.readFile "${hyprlandDir}/keybinds.lua";

    # variables.lua and utils/ are `require()`d by name (not readFile'd) from
    # within the blobs above, so they need to exist as real files under
    # ~/.config/hypr/ rather than being inlined.
    utilsDir = "${hyprDir}/utils";
    variablesFile = "${hyprDir}/variables.lua";

    # No execs.conf-equivalent to migrate (execs.lua is plain Lua, already
    # folded into generalConfig above) and no ii-style keybinds.conf
    # cheatsheet parser to feed.
    execsConf = null;
    scriptsDir = null;
    keybindsConfFile = null;
  };

  # caelestia-shell manages its own idle/lock/sleep pipeline (see
  # modules/IdleMonitors.qml + modules/lock/Lock.qml, both driven by
  # ~/.config/caelestia/shell.json's general.idle.* options), which would
  # otherwise fight hypridle over the same DPMS/suspend/lock transitions.
  hypridle.enable = false;
}
