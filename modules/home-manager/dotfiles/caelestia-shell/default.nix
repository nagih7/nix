# ██████╗ █████╗ ███████╗██╗     ███████╗███████╗████████╗██╗ █████╗
# ██╔════╝██╔══██╗██╔════╝██║     ██╔════╝██╔════╝╚══██╔══╝██║██╔══██╗
# ██║     ███████║█████╗  ██║     █████╗  ███████╗   ██║   ██║███████║
# ██║     ██╔══██║██╔══╝  ██║     ██╔══╝  ╚════██║   ██║   ██║██╔══██║
# ╚██████╗██║  ██║███████╗███████╗███████╗███████║   ██║   ██║██║  ██║
#  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═╝
# -------------------------------------------------------------------------
# HM wiring for the caelestia-shell provider. Unlike ii's dotfiles/quickshell
# (a hand-rolled venv/wrapper because end-4-dots ships raw QML + Python
# scripts), caelestia-shell ships an official Home Manager module
# (programs.caelestia) that already owns the package, wrapping and a
# systemd service — so this module is mostly just enabling that, plus
# seeding the handful of files caelestia-dots' Hyprland config expects to
# exist and be writable at runtime (it does plain file I/O on them, not
# managed by Home Manager).

{
  config,
  lib,
  pkgs,
  caelestia-shell,
  caelestia-dots,
  hostVars,
  ...
}:

let
  shell = config.custom.desktopShell;
  active = shell.name == "caelestia";
  home = config.home.homeDirectory;
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  imports = [ caelestia-shell.homeManagerModules.default ];

  programs.caelestia = lib.mkIf active {
    enable = true;
    cli.enable = true;
    # Never set cli.settings/cli.extraConfig (or settings/extraConfig for
    # the shell): the official module writes caelestia/cli.json (and
    # shell.json) itself as soon as either is non-empty, which would
    # collide with the out-of-store symlink to the same path below.
    # Runs as a systemd user service instead of the vendored execs.lua's own
    # `caelestia shell -d` exec-once — see providers/caelestia's comment on
    # why (UWSM app-scope/portal verification).
    systemd.enable = true;
  };

  # A systemd --user unit doesn't go through a login shell, which is the
  # only place home.sessionVariables.XDG_DATA_DIRS (below) actually gets
  # sourced (it's written to ~/.profile-style files, not environment.d) —
  # so caelestia.service starts with no icon-theme/app-data search paths at
  # all, and Quickshell.iconPath() (see caelestia-dots/utils/Icons.qml's
  # getAppIcon) has nowhere to find real application icons. This is the
  # same class of bug the ii provider works around by re-sourcing
  # /etc/set-environment before its own exec-once (see
  # ../../desktop/hyprland/modules/autostart.nix) — but that trick is
  # shell-script-only (relies on `$XDG_DATA_DIRS` expansion), which doesn't
  # work in a unit file's literal `Environment=`. systemd.user.sessionVariables
  # (environment.d) is what actually reaches every systemd --user unit.
  systemd.user.sessionVariables = lib.mkIf active {
    XDG_DATA_DIRS = lib.concatStringsSep ":" [
      "${home}/.local/share/flatpak/exports/share"
      "/var/lib/flatpak/exports/share"
      "/run/current-system/sw/share"
      "${config.home.profileDirectory}/share"
    ];
  };

  # caelestia-dots' own hyprland.lua does two things this migration's
  # generalConfig/envConfig/keybindsConfig split (readFile+concatenate each
  # hypr/hyprland/*.lua file, see providers/caelestia) doesn't replicate on
  # its own: merging ~/.config/caelestia/hypr-vars.lua's overrides into the
  # `variables` module *before* anything reads it, and require()ing
  # hypr-user.lua at the very end. Lua's `require` caches modules by
  # reference (first call wins), so it doesn't matter which nix option
  # contributes this text — only that it's the textual first/last thing in
  # the fully-assembled extraConfig. lib.mkBefore/mkAfter guarantee that
  # regardless of module import order, where general.nix/environment.nix/
  # keybinding.nix's own contributions land relative to each other. Without
  # this, hypr-vars.lua is silently inert — confirmed empirically (it never
  # appears in `nix eval ...extraConfig`'s output before this fix).
  wayland.windowManager.hyprland.extraConfig = lib.mkIf active (
    lib.mkMerge [
      (lib.mkBefore ''
        package.path = package.path .. ";${home}/.config/caelestia/?.lua"

        local overrides = require("hypr-vars")
        if type(overrides) == "table" then
          local vars = require("variables")
          for k, v in pairs(overrides) do
            vars[k] = v
          end
        end
      '')
      (lib.mkAfter ''
        require("hypr-user")
      '')
    ]
  );

  home.packages = lib.mkIf active (
    with pkgs;
    [
      # Referenced directly by hypr/variables.lua / execs.lua / keybinds.lua.
      # (kbEditor's default "codium" is overridden to "code" below — home/nagih
      # already installs pkgs.unstable.vscode, and vscodium collides with it
      # on shared /lib/vscode/* paths in home.packages.)
      foot # kbTerminal
      thunar # kbFileExplorer
      pwvucontrol # kbAudioSettings
      gammastep # night light (execs.lua)
      polkit_gnome # auth agent (execs.lua, path already patched)
      bluez # mpris-proxy (bluetooth media key forwarding, execs.lua)
    ]
  );

  # hypr-vars.lua / hypr-user.lua / cli.json / templates/ are all pure user
  # input — read once at parse/apply time and never written back by
  # anything, confirmed by reading the actual source: Hyprland's Lua loader
  # for the first two, and caelestia-cli's utils/paths.py get_config()
  # (json.loads only, no atomic_write) + utils/theme.py apply_user_templates
  # (reads templates/, writes its *output* to ~/.local/state/caelestia/theme/,
  # never touches the template source) for the latter two. Safe to symlink
  # out-of-store straight into this repo (edit + reload, no
  # `home-manager switch` needed), same as hypr-vars/hypr-user.
  #
  # shell.json / shell-tokens.json / monitors/*/shell.json do NOT get this
  # treatment: caelestia-shell's C++ plugin (RootNode::saveToFile, bound to
  # its ChangeBatcher::dirtied signal — see plugin/src/Caelestia/Settings/
  # rootnode.cpp in caelestia-shell) writes them back on *any* property
  # change, including from the shell's own in-app settings UI. Symlinking
  # those into this repo would dirty the git tree on every settings tweak,
  # the same problem hypr/scheme/current.lua has below. Leave them fully
  # unmanaged (or seed once, like scheme/current.lua) if you want them at
  # all — never a live repo symlink.
  xdg.configFile = lib.mkIf active {
    "caelestia/hypr-vars.lua".source = outOfStore "${hostVars.nixConfig}/home/nagih/caelestia/hypr-vars.lua";
    "caelestia/hypr-user.lua".source = outOfStore "${hostVars.nixConfig}/home/nagih/caelestia/hypr-user.lua";
    "caelestia/cli.json".source = outOfStore "${hostVars.nixConfig}/home/nagih/caelestia/cli.json";
    "caelestia/templates".source = outOfStore "${hostVars.nixConfig}/home/nagih/caelestia/templates";
  };

  # scheme/current.lua is different: caelestia-cli's apply_hypr() rewrites
  # it (atomic_write) on every scheme/wallpaper change, so unlike
  # hypr-vars/hypr-user it must NOT be a repo symlink (that would dirty the
  # git tree on every wallpaper change) — seed it once from caelestia-dots'
  # own default.lua and leave it alone after that, same as caelestia's own
  # non-Nix install does.
  home.activation.setupCaelestiaHypr = lib.mkIf active (
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "${home}/.config/hypr/scheme" "${home}/Pictures/Wallpapers"

      if [ ! -f "${home}/.config/hypr/scheme/current.lua" ]; then
        $DRY_RUN_CMD install -m 0644 "${caelestia-dots}/hypr/scheme/default.lua" "${home}/.config/hypr/scheme/current.lua"
      fi
    ''
  );
}
