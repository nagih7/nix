{
  config,
  lib,
  hostVars,
  ...
}:

{
  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Mocha";

    font = {
      name = "JetBrainsMono NF Bold";
      size = 14.0;
    };

    settings = {
      # Remote control for theme reloading
      allow_remote_control = true;
      listen_on = "unix:/tmp/kitty-socket";

      # Cursor settings
      cursor_shape = "beam";
      cursor_trail = 1;

      # Font settings
      bold_font = "auto";
      italic_font = "auto";
      bold_italic_font = "auto";

      # Window settings - Transparent background
      background_opacity = "0.7";
      background_blur = 5;
      background_image = "none";
      background_tint = "0.8";
      confirm_os_window_close = 0;
      window_padding_width = 4;
      window_margin_width = 4;

      # Display server
      linux_display_server = "auto";

      # Scrolling
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;

      # Audio
      enable_audio_bell = false;

      # Additional transparency settings
      dynamic_background_opacity = true;
      background_image_layout = "scaled";
    };
  };
}
