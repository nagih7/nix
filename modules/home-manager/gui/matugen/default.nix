{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Store path, so the generated config doesn't depend on where this repo
  # happens to be checked out.
  localTemplatePath = ./templates;
  shellMatugen = config.custom.desktopShell.matugen;
  # null means the active shell provider doesn't drive matugen at all (no
  # script calls `matugen image ...` on wallpaper change) — nothing in this
  # module has anything to do, so don't even install the package or write a
  # config nobody reads.
  usesMatugen = shellMatugen.finalConfig != null;
in
lib.mkIf usesMatugen {
  home.packages = with pkgs; [
    matugen
  ];

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
  '';
}
