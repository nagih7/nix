# Selects the active desktop shell bundle (quickshell + hyprlock + matugen +
# hyprland lua + KDE color seed) and exposes it as config.custom.desktopShell.
# Every consumer module reads from that option instead of importing a
# dotfiles flake input directly, so trying a different shell is: add a
# provider under ./providers/<name>, then point desktopShell at it.

{
  config,
  lib,
  pkgs,
  end-4-dots,
  systemVars,
  ...
}:

let
  shellName = systemVars.desktopShell;

  providers = {
    ii = import ./providers/ii { inherit config pkgs end-4-dots; };
  };
in
{
  options.custom.desktopShell = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    internal = true;
    description = "Active desktop shell provider bundle.";
  };

  config.custom.desktopShell = providers.${shellName};
}
