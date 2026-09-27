{ pkgs, ... }:

{
  # Hyprland is owned by the NixOS module (UWSM session, portals, PAM);
  # home-manager only renders the config (package = null there).
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  # Portals live here (not home-manager) because the systemd user services
  # are generated from the system profile. Hyprland's module adds the
  # hyprland + gtk backends; kde is added for FileChooser/OpenURI:
  #   - FileChooser=kde: the KDE dialog is the only one whose folder/mime
  #     resolution matches Dolphin's mimeapps.list entries.
  #   - OpenURI=kde: xdg-open detects DE=flatpak on this system (stray
  #     /run/user/$UID/flatpak-info) and always goes through the portal;
  #     the hyprland/gtk backends don't resolve inode/directory to Dolphin.
  xdg.portal = {
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.FileChooser" = "kde";
      "org.freedesktop.impl.portal.OpenURI" = "kde";
    };
  };

  services.gvfs.enable = true;
  programs.dconf.enable = true;

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # Session-wide helpers only; user-facing Wayland tools (grim, slurp,
  # cliphist, playerctl, …) are installed by home-manager alongside the
  # shell that uses them (dotfiles/quickshell/modules/dependencies.nix).
  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    libnotify
    glib # gsettings
    gsettings-desktop-schemas
  ];
}
