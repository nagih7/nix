{ config, pkgs }:

{
  # === ENVIRONMENT VARIABLES ===
  # Qt6 Configuration
  QT_QPA_PLATFORM = "wayland";
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  QT_SCALE_FACTOR = "1";
  QT_QUICK_CONTROLS_STYLE = "Basic";
  QT_QUICK_FLICKABLE_WHEEL_DECELERATION = "10000";

  # QuickShell Configuration
  QS_CONFIG_NAME = "ii";
  QS_NO_RELOAD_POPUP = "1";

  # QML Import Paths (for KDE modules)
  QML2_IMPORT_PATH = "${pkgs.kdePackages.kirigami}/${pkgs.kdePackages.qtbase.qtQmlPrefix}";

  # Python Configuration
  # Dynamically use the correct Python version from nixpkgs
  PYTHONPATH = builtins.concatStringsSep ":" [
    "${pkgs.python3Packages.pywayland}/${pkgs.python3.sitePackages}"
    "${pkgs.python3Packages.setproctitle}/${pkgs.python3.sitePackages}"
    "${pkgs.python3Packages.pillow}/${pkgs.python3.sitePackages}"
    "${pkgs.python3Packages.numpy}/${pkgs.python3.sitePackages}"
    "${pkgs.python3Packages.requests}/${pkgs.python3.sitePackages}"
  ];

  # Virtual Environment Path
  ILLOGICAL_IMPULSE_VIRTUAL_ENV = "${config.home.homeDirectory}/.local/state/quickshell/.venv";
}
