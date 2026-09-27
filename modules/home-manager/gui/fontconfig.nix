{ ... }:

{
  # Subpixel/hinting policy is set system-wide in modules/nixos/desktop/fonts.nix
  # (rgba=none, hinting off); this mirrors it for GTK apps that read dconf.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-antialiasing = "grayscale";
      font-hinting = "none";
    };
  };
}
