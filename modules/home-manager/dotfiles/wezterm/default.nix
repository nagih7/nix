{
  config,
  pkgs,
  lib,
  nagih7-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${nagih7-dots}/wezterm/wezterm.lua";

  finalConfig = builtins.replaceStrings [ "font_size = 14" ] [ "font_size = 12" ] rawConfig;
in
{
  # === WEZTERM TERMINAL CONFIGURATION ===
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    extraConfig = finalConfig;
  };

  # === ENVIRONMENT AND DEFAULT TERMINAL SETUP ===
  home.sessionVariables = {
    TERMINAL = "wezterm";
    TERM = "wezterm";
  };

  # === FILE ASSOCIATIONS ===
  xdg.mimeApps.defaultApplications = {
    "application/x-terminal" = "org.wezfurlong.wezterm.desktop";
    "x-scheme-handler/terminal" = "org.wezfurlong.wezterm.desktop";
  };

  # === FONTS FOR WEZTERM (minimal to avoid conflicts) ===
  home.packages = with pkgs; [
    nerd-fonts.inconsolata
  ];

  # === DESKTOP INTEGRATION ===
  xdg.desktopEntries."wezterm-here" = {
    name = "WezTerm Here";
    comment = "Open WezTerm in current directory";
    exec = "wezterm start --cwd %f";
    icon = "org.wezfurlong.wezterm";
    type = "Application";
    categories = [
      "System"
      "TerminalEmulator"
    ];
  };
}
