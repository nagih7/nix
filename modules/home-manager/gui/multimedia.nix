{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    evince # PDF viewer
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = [ "org.gnome.Evince.desktop" ];
    };
  };
}
