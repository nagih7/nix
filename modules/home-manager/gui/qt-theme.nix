{
  pkgs,
  lib,
  ...
}:

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
}
