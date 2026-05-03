{ config, pkgs, ... }:

{
  xdg.configFile."fontconfig/conf.d/10-no-sub-pixel.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
        <match target="font">
            <edit name="rgba" mode="assign">
                <const>none</const>
            </edit>
        </match>
    </fontconfig>
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      font-antialiasing = "grayscale"; 
      font-hinting = "none";
    };
  };
}
