{
  config,
  pkgs,
  end-4-dots,
}:

{
  # === HOME ACTIVATION SCRIPT ===
  # Set up directories and files needed for quickshell at activation time
  setupQuickShellEnvironment = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        # === DIRECTORY STRUCTURE ===
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/state/quickshell
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/hypr/custom/scripts
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/Pictures/Wallpapers
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen/templates/kde
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/state/quickshell/user/generated
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/illogical-impulse/translations
        
        # === TRANSLATION FILES ===
        if [ ! -f "${config.home.homeDirectory}/.config/illogical-impulse/translations/en_US.json" ]; then
          cat > ${config.home.homeDirectory}/.config/illogical-impulse/translations/en_US.json << 'TRANEOF'
    {
      "language": "English (US)",
      "translations": {}
    }
    TRANEOF
        fi
        
        # === PYTHON VIRTUAL ENVIRONMENT ===
        if [ ! -d "${config.home.homeDirectory}/.local/state/quickshell/.venv" ]; then
          $DRY_RUN_CMD ${pkgs.python3}/bin/python -m venv --system-site-packages ${config.home.homeDirectory}/.local/state/quickshell/.venv
          $DRY_RUN_CMD ${config.home.homeDirectory}/.local/state/quickshell/.venv/bin/pip install materialyoucolor
        fi
              
        # === HYPRLAND SCRIPTS ===
        # Create empty restore script for video wallpapers
        $DRY_RUN_CMD touch ${config.home.homeDirectory}/.config/hypr/custom/scripts/__restore_video_wallpaper.sh
        $DRY_RUN_CMD chmod +x ${config.home.homeDirectory}/.config/hypr/custom/scripts/__restore_video_wallpaper.sh
        
        # === SETTINGS LAUNCHER ===
        # Create wrapper script to launch settings (unsets QS_CONFIG_NAME to avoid conflict with --path)
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.local/bin
        cat > ${config.home.homeDirectory}/.local/bin/qs-settings << 'SETTINGSEOF'
    #!/usr/bin/env bash
    # Wrapper script to launch quickshell settings
    # Unsets QS_CONFIG_NAME to avoid conflict with --path flag
    env -u QS_CONFIG_NAME quickshell --path ~/.config/quickshell/ii/settings.qml "$@"
    SETTINGSEOF
        $DRY_RUN_CMD chmod +x ${config.home.homeDirectory}/.local/bin/qs-settings
        
        # === KDE INTEGRATION ===
        # Create basic KDE wrapper script for Material You colors
        $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.config/matugen/templates/kde
        cat > ${config.home.homeDirectory}/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh << 'EOF'
    #!/bin/bash
    # Basic KDE Material You colors wrapper
    echo "KDE theming not fully implemented yet"
    EOF
        $DRY_RUN_CMD chmod +x ${config.home.homeDirectory}/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh

        # === DEFAULT WALLPAPER ===
        if [ ! -f "${config.home.homeDirectory}/Pictures/Wallpapers/default.png" ]; then
          $DRY_RUN_CMD cp -f ${end-4-dots}/dots/.config/quickshell/ii/assets/images/default_wallpaper.png \
            ${config.home.homeDirectory}/Pictures/Wallpapers/default.png
        fi
  '';
}
