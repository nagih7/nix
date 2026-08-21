{
  config,
  lib,
  pkgs,
  hostVars,
  ...
}:

let
  localTemplatePath = "${hostVars.nixConfig}/modules/home-manager/gui/matugen/templates";
  shellMatugen = config.custom.desktopShell.matugen;
in
{
  home.packages = with pkgs; [
    matugen
  ];

  # null means the active shell provider has no matugen base config to layer
  # our local templates onto.
  xdg.configFile."matugen/templates/kde/kde-material-you-colors-wrapper.sh" = lib.mkIf (
    shellMatugen.kdeWrapperScript != null
  ) { source = shellMatugen.kdeWrapperScript; };

  xdg.configFile."matugen/config.toml".text = ''
    ${lib.optionalString (shellMatugen.finalConfig != null) shellMatugen.finalConfig}

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
    # Touch the file after writing to guarantee an inotify IN_MODIFY event even
    # when matugen uses an atomic rename (which fires IN_MOVED_TO, missed by some
    # file watchers). WezTerm's add_to_config_reload_watch_list then picks it up.
    post_hook = "touch ~/.config/wezterm/colors/MaterialYou.toml 2>/dev/null || true"

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
