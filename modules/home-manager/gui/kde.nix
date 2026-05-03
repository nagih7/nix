{
  config,
  lib,
  pkgs,
  end-4-dots,
  ...
}:

{
  home.packages = with pkgs; [
    kdePackages.kdialog
    kdePackages.dolphin
    python3Packages.kde-material-you-colors
  ];

  home.sessionVariables = {
    GTK_USE_PORTAL = "1";
  };

  xdg.configFile."kdeglobals".text = lib.mkForce (
    builtins.readFile "${end-4-dots}/dots/.config/kdeglobals"
    + ''
      [KDE]
      widgetStyle=kvantum
    ''
  );
}
