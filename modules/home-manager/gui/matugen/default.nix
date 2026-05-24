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

  xdg.configFile."matugen/templates/kde/kde-material-you-colors-wrapper.sh" = {
    source = "${end-4-dots}/dots/.config/matugen/templates/kde/kde-material-you-colors-wrapper.sh";
  };

  xdg.configFile."matugen/config.toml".text = ''
    ${finalConfig}

    [templates.cava]
    input_path = '${localTemplatePath}/cava.config'
    output_path = '~/.config/cava/config'
    post_hook = "pkill -SIGUSR2 cava 2>/dev/null || true"

    [templates.tmux]
    input_path = '${localTemplatePath}/tmux-colors.conf'
    output_path = '~/.config/tmux/material-colors.conf'
    # Re-source the file in every running tmux server so live sessions pick up
    # the new palette without restart. Catches both legacy ~/.tmux/sockets and
    # the systemd-managed default; ignores failure when no server is running.
    post_hook = "tmux source-file ~/.config/tmux/material-colors.conf 2>/dev/null && tmux refresh-client -S 2>/dev/null || true"

    [templates.wezterm]
    input_path = '${localTemplatePath}/wezterm-colors.toml'
    output_path = '~/.config/wezterm/colors/MaterialYou.toml'
    # No live-reload hook: wezterm picks up the new scheme on next launch.
    # Existing windows are already updated by the OSC sequences applycolor.sh
    # emits to every PTS, so we don't need to disturb running terminals.

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
