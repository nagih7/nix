{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      sf-pro # overlays/default.nix — Apple's own font, see there for licensing note
      inter # kept as fallback (open-licensed, in case sf-pro is ever dropped)
      noto-fonts
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      noto-fonts-color-emoji
      material-symbols
    ];

    fontconfig = {
      enable = true;
      antialias = true;

      hinting = {
        enable = false;
        style = "none";
      };

      # Grayscale antialiasing everywhere (matches the GNOME/GTK dconf setting
      # in home-manager gui/fontconfig.nix).
      subpixel = {
        rgba = "none";
        lcdfilter = "none";
      };

      defaultFonts = {
        sansSerif = [
          "SF Pro Text"
          "Inter"
          "DejaVu Sans"
        ];
        serif = [
          "Noto Serif"
          "DejaVu Serif"
        ];
        monospace = [ "JetBrainsMono Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };

      localConf = ''
        <alias>
          <family>monospace</family>
          <prefer>
            <family>JetBrainsMono Nerd Font</family>
            <family>Noto Color Emoji</family>
          </prefer>
        </alias>
      '';
    };
  };
}
