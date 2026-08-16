{
  config,
  pkgs,
  lib,
  nagih7-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${nagih7-dots}/wezterm/wezterm.lua";

  # Patches applied to the upstream wezterm.lua:
  #   - shrink font from 14 → 12 (host-specific)
  #   - swap the hardcoded "Catppuccin Mocha" scheme for the matugen-managed
  #     "MaterialYou" scheme written to ~/.config/wezterm/colors/MaterialYou.toml
  #     on every wallpaper change, so new terminals match the current wallpaper.
  # NOTE: wezterm-colors.toml template uses .dark.hex variants exclusively, so
  # the scheme stays dark even when the system switches to light mode. No mode
  # detection needed in wezterm.lua — the brightness=0.05 dim-wallpaper-bg
  # assumption that the upstream config makes always holds.
  finalConfig =
    builtins.replaceStrings
      [
        "font_size = 14"
        "\"Catppuccin Mocha\""
        "local config = wezterm.config_builder()"
      ]
      [
        "font_size = 12"
        "\"MaterialYou\""
        ''
          local config = wezterm.config_builder()

          -- Reload when matugen rewrites the MaterialYou color scheme (wallpaper change
          -- or /light /dark switch). Re-applies the dark-only scheme, overriding any
          -- OSC sequences applycolor.sh sent to /dev/pts/*.
          wezterm.add_to_config_reload_watch_list(
              os.getenv("HOME") .. "/.config/wezterm/colors/MaterialYou.toml"
          )
          -- Also reload when switchwall.sh updates the wallpaper path. matugen writes
          -- path.txt (wallpaper template) before MaterialYou.toml (wezterm template),
          -- so both files are ready before the reload fires.
          wezterm.add_to_config_reload_watch_list(
              os.getenv("HOME") .. "/.local/state/quickshell/user/generated/wallpaper/path.txt"
          )''
      ]
      rawConfig;
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

  # Seed a placeholder MaterialYou.toml if matugen hasn't generated one yet.
  # Without this, wezterm errors at launch because color_scheme="MaterialYou"
  # references a missing scheme. Matugen overwrites this on the next wallpaper
  # change with the real palette.
  home.activation.seedWeztermMaterialYou =
    config.lib.dag.entryAfter [ "writeBoundary" ] ''
      target="${config.home.homeDirectory}/.config/wezterm/colors/MaterialYou.toml"
      if [ ! -e "$target" ]; then
        $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
        $DRY_RUN_CMD install -m 0644 \
          ${pkgs.writeText "wezterm-materialyou-seed" ''
            # Placeholder until matugen generates the real palette on next
            # wallpaper change. Neutral dark scheme, not Catppuccin.
            [colors]
            foreground = "#e6e1e5"
            background = "#1c1b1f"
            cursor_bg  = "#d0bcff"
            cursor_fg  = "#381e72"
            cursor_border = "#d0bcff"
            selection_bg = "#4f378b"
            selection_fg = "#eaddff"
            ansi    = ["#1c1b1f","#f2b8b5","#a6c8a4","#e8c184","#9ecaff","#d0bcff","#a3d4d4","#cac4d0"]
            brights = ["#938f99","#f2b8b5","#a6c8a4","#e8c184","#9ecaff","#d0bcff","#a3d4d4","#e6e1e5"]
            [metadata]
            name = "MaterialYou"
            author = "seed"
          ''} "$target"
      fi
    '';

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
