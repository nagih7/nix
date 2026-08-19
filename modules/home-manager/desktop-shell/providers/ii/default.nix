# ██╗██╗    ██████╗ ██████╗  ██████╗ ██╗   ██╗██╗██████╗ ███████╗██████╗
# ██║██║    ██╔══██╗██╔══██╗██╔═══██╗██║   ██║██║██╔══██╗██╔════╝██╔══██╗
# ██║██║    ██████╔╝██████╔╝██║   ██║██║   ██║██║██║  ██║█████╗  ██████╔╝
# ██║██║    ██╔═══╝ ██╔══██╗██║   ██║╚██╗ ██╔╝██║██║  ██║██╔══╝  ██╔══██╗
# ██║██║    ██║     ██║  ██║╚██████╔╝ ╚████╔╝ ██║██████╔╝███████╗██║  ██║
# ╚═╝╚═╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝
# -------------------------------------------------------------------------
# Desktop shell provider for end-4/dots-hyprland's "ii" (illogical impulse)
# shell. This is the only file that reads from the end-4-dots flake input -
# every consumer module reads config.custom.desktopShell instead, so a
# different shell only needs a sibling provider with this same shape.

{ config, pkgs, end-4-dots }:

let
  # hyprlock.conf as shipped ships a broken "#!/bin/env bash" shebang for its
  # helper scripts (no /bin/env on NixOS) and assumes ~/.config paths; rewrite
  # both to point at our fixed local copies (see hyprlock/default.nix) and to
  # the derivation path for everything else.
  hyprlockRaw = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprlock.conf";
  hyprlockFinal = builtins.replaceStrings
    [
      # Longer/more specific strings must come first: replaceStrings matches
      # list entries in order at each position, so these need to win over
      # the generic XDG_CONFIG_HOME replacement below.
      "\${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock/check-capslock.sh"
      "\${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock/status.sh"
      "\${XDG_CONFIG_HOME:-$HOME/.config}"
      "color = rgba(181818FF)"
    ]
    [
      "${config.home.homeDirectory}/.config/hypr/hyprlock/check-capslock.sh"
      "${config.home.homeDirectory}/.config/hypr/hyprlock/status.sh"
      "${end-4-dots}/dots/.config"
      "path = $background_image\ncolor = rgba(181818FF)\nblur_passes = 2\nblur_size = 3\nnoise = 0.01\ncontrast = 0.8\nbrightness = 0.8\nvibrancy = 0.1\nvibrancy_darkness = 0.0"
    ]
    hyprlockRaw;

  matugenRaw = builtins.readFile "${end-4-dots}/dots/.config/matugen/config.toml";
  matugenFinal = builtins.replaceStrings
    [
      "~/.config/matugen/templates"
      "version_check = false"
      "~/.config/gtk-3.0/gtk.css"
      "~/.config/gtk-4.0/gtk.css"
    ]
    [
      "${end-4-dots}/dots/.config/matugen/templates"
      "version_check = false\nreload_config = true"
      "~/.config/gtk-3.0/matugen.css"
      "~/.config/gtk-4.0/matugen.css"
    ]
    matugenRaw;
in
{
  name = "ii";

  quickshell = {
    configSource = import ./config-builder.nix { inherit pkgs end-4-dots; };
    wallpaperSeed = "${end-4-dots}/dots/.config/quickshell/ii/assets/images/default_wallpaper.png";
  };

  hyprland = {
    generalConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/general.lua";
    envConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/env.lua";
    execsConf = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/execs.conf";
    keybindsConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/keybinds.lua";
    scriptsDir = "${end-4-dots}/dots/.config/hypr/hyprland/scripts";
    keybindsConfFile = "${end-4-dots}/dots/.config/hypr/hyprland/keybinds.conf";
  };

  hyprlock.finalConfig = hyprlockFinal;

  matugen = {
    finalConfig = matugenFinal;
    kdeWrapperScript = "${end-4-dots}/dots/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh";
  };

  kde.kdeglobalsSeed = builtins.readFile "${end-4-dots}/dots/.config/kdeglobals";

  dolphin.rcPath = "${end-4-dots}/dots/.config/dolphinrc";

  hypridle.finalConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hypridle.conf";
}
