{ config, pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      inter
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

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      defaultFonts = {
        sansSerif = [ "Inter" "DejaVu Sans" ]; 
        serif = [ "Noto Serif" "DejaVu Serif" ];
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
