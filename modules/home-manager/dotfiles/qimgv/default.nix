{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [ qimgv ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = [ "qimgv.desktop" ];
      "image/png" = [ "qimgv.desktop" ];
      "image/gif" = [ "qimgv.desktop" ];
      "image/webp" = [ "qimgv.desktop" ];
      "image/tiff" = [ "qimgv.desktop" ];
      "image/bmp" = [ "qimgv.desktop" ];
      "image/svg+xml" = [ "qimgv.desktop" ];
    };
  };
}
