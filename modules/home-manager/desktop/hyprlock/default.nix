{
  config,
  lib,
  ...
}:

{
  programs.hyprlock = {
    enable = true;

    # null means the active shell provider has no hyprlock opinion.
    extraConfig = lib.mkIf (config.custom.desktopShell.hyprlock.finalConfig != null) ''
      ${config.custom.desktopShell.hyprlock.finalConfig}
    '';

    settings = {
      background = [
        {
          path = "$background_image";
        }
      ];
    };
  };

  xdg.configFile = {
    "hypr/hyprlock/check-capslock.sh" = {
      source = ./scripts/check-capslock.sh;
      executable = true;
    };
    "hypr/hyprlock/status.sh" = {
      source = ./scripts/status.sh;
      executable = true;
    };
  };
}
