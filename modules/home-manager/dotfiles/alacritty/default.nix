{ config, lib, pkgs, ... }:

let
  home = config.home.homeDirectory;
  themeOutput = "${home}/.local/state/caelestia/theme/alacritty-colors.toml";
in
{
  # === ALACRITTY TERMINAL CONFIGURATION (default terminal) ===
  programs.alacritty = {
    enable = true;

    settings = {
      general.import = [ themeOutput ];

      font = {
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Medium";
        };
        bold.family = "JetBrainsMono Nerd Font";
        italic.family = "JetBrainsMono Nerd Font";
        size = 12;
      };

      window = {
        padding = {
          x = 8;
          y = 8;
        };
        opacity = 0.92;
      };

      cursor.style.shape = "Beam";

      terminal.shell.program = "zsh";

      keyboard.bindings = [
        {
          key = "Backspace";
          mods = "Control";
          chars = builtins.fromJSON ''"\u0017"'';
        }
      ];
    };
  };

  # === ENVIRONMENT AND DEFAULT TERMINAL SETUP ===
  home.sessionVariables = {
    TERMINAL = "alacritty";
    TERM = "alacritty";
  };

  # === FILE ASSOCIATIONS ===
  xdg.mimeApps.defaultApplications = {
    "application/x-terminal" = "Alacritty.desktop";
    "x-scheme-handler/terminal" = "Alacritty.desktop";
  };

  home.activation.seedAlacrittyColors = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "${themeOutput}" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "${themeOutput}")"
      $DRY_RUN_CMD install -m 0644 ${pkgs.writeText "alacritty-colors-seed.toml" ''
        [colors.primary]
        background = "#191212"
        foreground = "#eedfdf"

        [colors.cursor]
        text = "#191212"
        cursor = "#ffb2b6"

        [colors.selection]
        text = "#eedfdf"
        background = "#643f41"

        [colors.normal]
        black = "#353434"
        red = "#ff5262"
        green = "#ffbcaa"
        yellow = "#ffdfd9"
        blue = "#b3a2d5"
        magenta = "#ef8f9c"
        cyan = "#ffba93"
        white = "#efd2cd"

        [colors.bright]
        black = "#b49e9a"
        red = "#ff8488"
        green = "#ffd4c8"
        yellow = "#fff1ef"
        blue = "#dcbc93"
        magenta = "#fea7b0"
        cyan = "#ffd1c0"
        white = "#ffffff"
      ''} "${themeOutput}"
    fi
  '';
}
