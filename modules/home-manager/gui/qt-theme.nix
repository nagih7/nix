{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Same Qt6 QFont::toString() field layout kdeglobals' own pre-existing
  # `fixed=` entry already uses (16 comma-separated fields) — confirmed live
  # on this machine that kwriteconfig6 writes/KDE apps read this format
  # correctly; matching it rather than the shorter legacy 10-field form.
  mkFontString =
    family: pointSize:
    "${family},${toString pointSize},-1,5,400,0,0,0,0,0,0,0,0,0,0,0";
  kwriteconfig6 = "${pkgs.kdePackages.kconfig}/bin/kwriteconfig6";
in
{
  # Qt theming chain:
  #   QT_QPA_PLATFORMTHEME=kde
  #     → loads KDEPlasmaPlatformTheme6.so (from kdePackages.plasma-integration)
  #     → reads kdeglobals on each app launch
  #         - [Colors:*]    → QPalette (written by kde-material-you-colors)
  #         - [KDE].widgetStyle=Breeze → loads breeze6.so widget style
  #     → Breeze paints widgets via QPainter using the QPalette
  #   ⇒ Material You colors propagate to kdialog / portal-kde / dolphin
  #     without app-specific patching.
  home.packages = with pkgs; [
    kdePackages.breeze # widget style (palette-driven)
    kdePackages.plasma-integration # KDEPlasmaPlatformTheme6.so
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORMTHEME = lib.mkForce "kde";
  };

  # kdeglobals is otherwise entirely unmanaged here (see
  # dotfiles/caelestia-shell — caelestia-cli's own apply_qt() writes
  # qtengine/config.json, never kdeglobals, and this provider sets
  # kde.kdeglobalsSeed = null), which is exactly why a plain xdg.configFile
  # symlink can't be used for just the font keys: it would have to own the
  # *whole* file, clobbering [Colors:*]/[Icons] that caelestia-cli/
  # kde-material-you-colors write at runtime. kwriteconfig6 edits only the
  # keys given, same tool KDE's own font-chooser dialog would use — no
  # keys existed here before this (Qt/KDE apps had no explicit font at
  # all), so this is a pure addition, not a Nix-vs-runtime-writer fight.
  home.activation.seedKdeglobalsFont = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    target="${config.home.homeDirectory}/.config/kdeglobals"
    # kwriteconfig6 creates the file (and section) if missing, so this only
    # needs to guard against overwriting-through-a-symlink, not absence.
    if [ ! -L "$target" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$target")"
      $DRY_RUN_CMD ${kwriteconfig6} --file "$target" --group General --key font \
        "${mkFontString "SF Pro Text" 11}"
      $DRY_RUN_CMD ${kwriteconfig6} --file "$target" --group General --key menuFont \
        "${mkFontString "SF Pro Text" 11}"
      $DRY_RUN_CMD ${kwriteconfig6} --file "$target" --group General --key toolBarFont \
        "${mkFontString "SF Pro Text" 10}"
      $DRY_RUN_CMD ${kwriteconfig6} --file "$target" --group General --key smallestReadableFont \
        "${mkFontString "SF Pro Text" 8}"
      # Stale from before switching to Alacritty — "open terminal here" in
      # dolphin/kdialog still launched kitty.
      $DRY_RUN_CMD ${kwriteconfig6} --file "$target" --group General --key TerminalApplication \
        "alacritty"
    fi
  '';
}
