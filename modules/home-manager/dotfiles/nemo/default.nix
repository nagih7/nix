{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nemo-with-extensions
    ffmpegthumbnailer
    libgsf
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = "nemo.desktop";
      "application/x-gnome-saved-search" = "nemo.desktop";
    };
  };

  xdg.desktopEntries.nemo = {
    name = "Nemo";
    genericName = "File Manager";
    exec = "nemo %U";
    terminal = false;
    icon = "${config.home.homeDirectory}/.local/share/icons/custom/nemo.svg";
    categories = [
      "System"
      "FileTools"
      "FileManager"
    ];
    mimeType = [
      "inode/directory"
      "application/x-gnome-saved-search"
    ];
  };

  dconf.settings = {
    "org/nemo/preferences" = {
      show-hidden-files = false;
      show-image-thumbnails = "always";
      thumbnail-limit = 104857600; # 100 MB
      quick-renames-with-pause-in-between = true;
      confirm-trash = false;
    };

    "org/nemo/window-state" = {
      sidebar-width = 200;
      geometry = "900x600+0+0";
    };

    "org/nemo/list-view" = {
      default-visible-columns = [
        "name"
        "size"
        "type"
        "date_modified"
      ];
      default-column-order = [
        "name"
        "size"
        "type"
        "date_modified"
        "date_created"
        "owner"
        "group"
        "permissions"
      ];
    };
  };
}
