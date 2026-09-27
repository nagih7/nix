{
  config,
  lib,
  pkgs,
  quickshell,
  ...
}:

let
  shell = config.custom.desktopShell;
  system = pkgs.stdenv.hostPlatform.system;

  # Python environment for the ii helper scripts (colour generation, wallpaper
  # analysis, keybind cheatsheet, thumbnails…). Mirrors upstream
  # sdata/uv/requirements.txt.
  iiPython = pkgs.python3.withPackages (
    ps: with ps; [
      materialyoucolor
      numpy
      opencv4
      pillow
      pygobject3
      pycairo
      google-auth
      tqdm
      loguru
      click
      requests
      pywayland
      setproctitle
      psutil
      libsass
    ]
  );

  # Store-backed stand-in for the virtualenv upstream expects at
  # $ILLOGICAL_IMPULSE_VIRTUAL_ENV: every script does
  # `source "$ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/activate"` and then calls
  # python3, so all we need is a bin/activate that puts iiPython first on
  # PATH. No pip, no network access at activation time.
  iiVenv = pkgs.symlinkJoin {
    name = "illogical-impulse-venv";
    paths = [
      iiPython
      (pkgs.writeTextDir "bin/activate" ''
        _II_OLD_PATH="$PATH"
        export PATH="${iiPython}/bin:$PATH"
        export VIRTUAL_ENV="${iiPython}"
        deactivate() {
          export PATH="$_II_OLD_PATH"
          unset VIRTUAL_ENV _II_OLD_PATH
          unset -f deactivate
        }
      '')
    ];
  };

  # Qt6 only searches the QML modules bundled with qtbase by default;
  # out-of-tree modules quickshell/ii import have to be listed explicitly.
  qmlImportPath = lib.concatStringsSep ":" (
    map (p: "${p}/${pkgs.kdePackages.qtbase.qtQmlPrefix}") (
      with pkgs.kdePackages;
      [
        kirigami
        qt5compat
        qtpositioning
        qtlocation
        qtmultimedia
        qtvirtualkeyboard
        qtdeclarative
        qtquicktimeline
        qtsvg
        syntax-highlighting
      ]
    )
  );

  # qs/quickshell wrapped with the environment they need, so none of it has
  # to be exported from the login shell (where a global QML2_IMPORT_PATH /
  # PYTHONPATH would leak into every Qt app and every Python project).
  quickshellWrapped = pkgs.symlinkJoin {
    name = "quickshell-wrapped";
    paths = [ quickshell.packages.${system}.default ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in "$out"/bin/qs "$out"/bin/quickshell; do
        wrapProgram "$bin" \
          --prefix QML2_IMPORT_PATH : "${qmlImportPath}" \
          --set-default QT_QUICK_CONTROLS_STYLE Basic \
          --set-default QT_QUICK_FLICKABLE_WHEEL_DECELERATION 10000 \
          --set-default QS_NO_RELOAD_POPUP 1
      done
    '';
  };

  venvLink = "${config.home.homeDirectory}/.local/state/quickshell/.venv";
in
{
  imports = [
    ./modules/dependencies.nix
    ./modules/services.nix
    ./modules/activation.nix
  ];

  home.packages = [ quickshellWrapped ];

  xdg.configFile."quickshell".source = shell.quickshell.configSource;

  home.sessionVariables = {
    # Session-wide Qt behaviour (not quickshell-specific).
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";

    # The shell provider's env.lua also points Hyprland-spawned processes at
    # this path, so keep the two in sync via the symlink below.
    ILLOGICAL_IMPULSE_VIRTUAL_ENV = venvLink;

    # Flatpak exports; set here (not hl.env) so $XDG_DATA_DIRS expands.
    XDG_DATA_DIRS = "$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:$XDG_DATA_DIRS";
  };

  # Point the venv path the ii scripts expect at the store-backed one,
  # replacing any pip-managed venv from earlier generations.
  home.activation.linkQuickshellVenv = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$(dirname "${venvLink}")"
    if [ -e "${venvLink}" ] && [ ! -L "${venvLink}" ]; then
      $DRY_RUN_CMD rm -rf "${venvLink}"
    fi
    $DRY_RUN_CMD ln -sfn "${iiVenv}" "${venvLink}"
  '';
}
