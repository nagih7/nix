{
  config,
  lib,
  pkgs,
  ...
}:

let
  home = config.home.homeDirectory;
  shell = config.custom.desktopShell;
in
{
  # Mutable state the ii shell expects to exist before first launch.
  home.activation.setupQuickShellEnvironment = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # === DIRECTORY STRUCTURE ===
    $DRY_RUN_CMD mkdir -p \
      ${home}/.local/state/quickshell/user/generated \
      ${home}/.config/hypr/custom/scripts \
      ${home}/.config/illogical-impulse/translations \
      ${home}/Pictures/Wallpapers \
      ${home}/Pictures/Screenshots \
      ${home}/.local/bin

    # === TRANSLATION FILES ===
    if [ ! -f "${home}/.config/illogical-impulse/translations/en_US.json" ]; then
      $DRY_RUN_CMD install -m 0644 ${pkgs.writeText "ii-en_US.json" ''
        {
          "language": "English (US)",
          "translations": {}
        }
      ''} "${home}/.config/illogical-impulse/translations/en_US.json"
    fi

    # === HYPRLAND SCRIPTS ===
    # Empty restore script for video wallpapers (ii execs it on start).
    $DRY_RUN_CMD touch ${home}/.config/hypr/custom/scripts/__restore_video_wallpaper.sh
    $DRY_RUN_CMD chmod +x ${home}/.config/hypr/custom/scripts/__restore_video_wallpaper.sh

    # === SETTINGS LAUNCHER ===
    # `quickshell --path` and QS_CONFIG_NAME conflict; unset the latter.
    $DRY_RUN_CMD install -m 0755 ${pkgs.writeShellScript "qs-settings" ''
      exec env -u QS_CONFIG_NAME quickshell --path ~/.config/quickshell/${shell.name}/settings.qml "$@"
    ''} "${home}/.local/bin/qs-settings"

    # === DEFAULT WALLPAPER ===
    ${lib.optionalString (shell.quickshell.wallpaperSeed != null) ''
      if [ ! -f "${home}/Pictures/Wallpapers/default.png" ]; then
        $DRY_RUN_CMD cp -f ${shell.quickshell.wallpaperSeed} ${home}/Pictures/Wallpapers/default.png
      fi
    ''}
  '';
}
