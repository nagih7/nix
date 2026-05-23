{
  config,
  pkgs,
  lib,
  hostVars,
  end-4-dots,
  ...
}:

let
  localTemplatePath = "${hostVars.nixConfig}/modules/home-manager/gui/matugen/templates";

  rawConfig = builtins.readFile "${end-4-dots}/dots/.config/matugen/config.toml";

  finalConfig =
    builtins.replaceStrings
      [
        "~/.config/matugen/templates"
        "version_check = false"
        "~/.config/gtk-3.0/gtk.css"
        "~/.config/gtk-4.0/gtk.css"
      ]
      [
        "${end-4-dots}/dots/.config/matugen/templates"
        "version_check = false\nreload_config = true"
        "~/.config/gtk-3.0/matugen.css"
        "~/.config/gtk-4.0/matugen.css"
      ]
      rawConfig;
in
{
  home.packages = with pkgs; [
    matugen
  ];

  xdg.configFile."matugen/config.toml".text = ''
    ${finalConfig}

    [templates.cava]
    input_path = '${localTemplatePath}/cava.config'
    output_path = '~/.config/cava/config'
    post_hook = "pkill -SIGUSR2 cava 2>/dev/null || true"

    # [templates.kitty]
    # input_path = '${localTemplatePath}/kitty.conf'
    # output_path = '~/.config/kitty/kitty.conf'
    # post_hook = """
    #   {
    #     if pgrep -x kitty > /dev/null; then
    #       kill -SIGUSR1 $(pidof kitty) && echo "Kitty reloaded"
    #     else
    #       echo "Kitty not running"
    #     fi
    #   } 2>/dev/null
    # """
  '';
}
