{
  config,
  lib,
  pkgs,
  hostVars,
  end-4-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprlock.conf";

  finalConfig =
    builtins.replaceStrings
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
        # end-4-dots' check-capslock.sh/status.sh ship a broken "#!/bin/env bash"
        # shebang (no /bin/env on NixOS) - use our fixed local copies instead.
        "${config.home.homeDirectory}/.config/hypr/hyprlock/check-capslock.sh"
        "${config.home.homeDirectory}/.config/hypr/hyprlock/status.sh"
        "${end-4-dots}/dots/.config"
        "path = $background_image\ncolor = rgba(181818FF)\nblur_passes = 2\nblur_size = 3\nnoise = 0.01\ncontrast = 0.8\nbrightness = 0.8\nvibrancy = 0.1\nvibrancy_darkness = 0.0"
      ]
      rawConfig;
in
{
  programs.hyprlock = {
    enable = true;

    extraConfig = ''
      ${finalConfig}
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
