{
  config,
  pkgs,
  lib,
  end-4-dots,
  ...
}:

{
  home.packages = with pkgs; [
    libsForQt5.qtstyleplugin-kvantum
    qt6Packages.qtstyleplugin-kvantum

  ];

  home.sessionVariables = {
    QT_STYLE_OVERRIDE = lib.mkForce "kvantum";
    QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct";
  };

  xdg.configFile."Kvantum/kvantum.kvconfig" = {
    text = lib.mkForce ''
      [General]
      theme=MaterialAdw

      [Applications]
      Dolphin=MaterialAdw
    '';
  };
  xdg.configFile."Kvantum/MaterialAdw" = {
    source = "${end-4-dots}/dots/.config/Kvantum/MaterialAdw";
    force = true;
  };
  xdg.configFile."Kvantum/Colloid" = {
    source = "${end-4-dots}/dots/.config/Kvantum/Colloid";
    force = true;
  };
}
