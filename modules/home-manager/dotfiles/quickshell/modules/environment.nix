{ config, pkgs }:

{
  # === ENVIRONMENT VARIABLES ===
  # Qt6 Configuration
  QT_QPA_PLATFORM = "wayland;xcb";
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  QT_SCALE_FACTOR = "1";
  QT_QUICK_CONTROLS_STYLE = "Basic";
  QT_QUICK_FLICKABLE_WHEEL_DECELERATION = "10000";

  # QuickShell Configuration
  QS_CONFIG_NAME = config.custom.desktopShell.name;
  QS_NO_RELOAD_POPUP = "1";

  # QML Import Paths — explicitly point at every Qt6 module whose QML files
  # quickshell imports. Qt6's binary-baked default search only covers modules
  # bundled with qtbase; out-of-tree modules (qt5compat, qtpositioning, etc.)
  # must be listed here or `import X` fails with "module not installed".
  QML2_IMPORT_PATH =
    let
      qmlSuffix = pkgs.kdePackages.qtbase.qtQmlPrefix;
    in
    builtins.concatStringsSep ":" [
      "${pkgs.kdePackages.kirigami}/${qmlSuffix}"
      "${pkgs.kdePackages.qt5compat}/${qmlSuffix}"
      "${pkgs.kdePackages.qtpositioning}/${qmlSuffix}"
      "${pkgs.kdePackages.qtlocation}/${qmlSuffix}"
      "${pkgs.kdePackages.qtmultimedia}/${qmlSuffix}"
      "${pkgs.kdePackages.qtvirtualkeyboard}/${qmlSuffix}"
      "${pkgs.kdePackages.qtdeclarative}/${qmlSuffix}"
      "${pkgs.kdePackages.qtquicktimeline}/${qmlSuffix}"
      "${pkgs.kdePackages.qtsvg}/${qmlSuffix}"
      "${pkgs.kdePackages.syntax-highlighting}/${qmlSuffix}"
    ];

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

  # Flatpak data dirs — set via home.sessionVariables so the shell expands
  # $XDG_DATA_DIRS at login time (unlike hl.env() which sets literal strings).
  XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
}
