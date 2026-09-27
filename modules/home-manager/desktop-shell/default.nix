# Selects the active desktop shell bundle (quickshell + hyprlock + matugen +
# hyprland lua + KDE color seed) and exposes it as config.custom.desktopShell.
# Every consumer module reads from that option instead of importing a
# dotfiles flake input directly, so trying a different shell is: add a
# provider under ./providers/<name>, then point desktopShell at it.
#
# The option is a typed submodule: every leaf defaults to null, which every
# consumer treats as "this provider has no opinion here", and a provider that
# returns an unknown key or the wrong type fails at eval instead of at runtime.

{
  config,
  lib,
  pkgs,
  end-4-dots,
  systemVars,
  ...
}:

let
  inherit (lib) mkOption types;

  opt =
    type:
    mkOption {
      type = types.nullOr type;
      default = null;
    };

  providerType = types.submodule {
    options = {
      name = mkOption { type = types.str; };

      quickshell = {
        configSource = opt types.package;
        wallpaperSeed = opt types.path;
      };

      hyprland = {
        generalConfig = opt types.lines;
        envConfig = opt types.lines;
        execsConf = opt types.lines;
        keybindsConfig = opt types.lines;
        scriptsDir = opt types.path;
        keybindsConfFile = opt types.path;
      };

      hyprlock.finalConfig = opt types.lines;

      matugen = {
        finalConfig = opt types.lines;
        kdeWrapperScript = opt types.path;
      };

      kde.kdeglobalsSeed = opt types.lines;
      dolphin.rcPath = opt types.path;
      hypridle.finalConfig = opt types.lines;
    };
  };

  providers = {
    ii = import ./providers/ii { inherit config pkgs end-4-dots; };
  };
in
{
  options.custom.desktopShell = mkOption {
    type = providerType;
    description = "Active desktop shell provider bundle.";
  };

  config.custom.desktopShell = providers.${systemVars.desktopShell};
}
