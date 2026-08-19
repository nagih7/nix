{
  config,
  lib,
  pkgs,
  quickshell,
  userObj,
  ...
}:

let
  # Environment variables
  sessionVariables = import ./modules/environment.nix { inherit config pkgs; };

  # Activation scripts
  activationScripts = import ./modules/activation.nix { inherit config lib pkgs userObj; };
in

{
  imports = [
    ./modules/dependencies.nix
    ./modules/services.nix
  ];

  # === QUICKSHELL CONFIGURATION ===
  xdg.configFile."quickshell".source = config.custom.desktopShell.quickshell.configSource;

  # === ENVIRONMENT VARIABLES ===
  home.sessionVariables = sessionVariables;

  # === HOME ACTIVATION ===
  home.activation = activationScripts;

  # === PROGRAMS ===
  programs = {
    command-not-found.enable = true;
  };
}
