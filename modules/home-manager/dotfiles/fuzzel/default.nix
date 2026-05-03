{
  config,
  pkgs,
  hostVars,
  ...
}:

{
  home.packages = with pkgs; [
    fuzzel
  ];

  xdg.configFile."fuzzel/fuzzel.ini".text = ''
    include="~/.config/fuzzel/fuzzel_theme.ini"
    font=Gabarito
    terminal=kitty -1
    prompt=">>  "
    layer=overlay

    [border]
    radius=17
    width=1

    [dmenu]
    exit-immediately-if-empty=yes
  '';
}
