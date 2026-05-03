{
  config,
  pkgs,
  quickshell,
  hostVars,
  end-4-dots,
  ...
}:

let
  # Build customized quickshell configuration
  quickshellConfig = import ./modules/config-builder.nix { inherit pkgs end-4-dots; };

  # Environment variables
  sessionVariables = import ./modules/environment.nix { inherit config pkgs; };

  # Activation scripts
  activationScripts = import ./modules/activation.nix { inherit config pkgs end-4-dots; };
in

{
  imports = [
    ./modules/dependencies.nix
    ./modules/services.nix
  ];

  # === QUICKSHELL CONFIGURATION ===
  xdg.configFile."quickshell".source = quickshellConfig;

  # === ENVIRONMENT VARIABLES ===
  home.sessionVariables = sessionVariables;

  # === HOME ACTIVATION ===
  home.activation = activationScripts;

  # === PROGRAMS ===
  programs = {
    command-not-found.enable = true;
  };
}
