# ██╗  ██╗███████╗██╗   ██╗██████╗ ██╗███╗   ██╗██████╗ ██╗███╗   ██╗ ██████╗
# ██║ ██╔╝██╔════╝╚██╗ ██╔╝██╔══██╗██║████╗  ██║██╔══██╗██║████╗  ██║██╔════╝
# █████╔╝ █████╗   ╚████╔╝ ██████╔╝██║██╔██╗ ██║██║  ██║██║██╔██╗ ██║██║  ███╗
# ██╔═██╗ ██╔══╝    ╚██╔╝  ██╔══██╗██║██║╚██╗██║██║  ██║██║██║╚██╗██║██║   ██║
# ██║  ██╗███████╗   ██║   ██████╔╝██║██║ ╚████║██████╔╝██║██║ ╚████║╚██████╔╝
# ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝
#-----------------------------------------------------------------------------

{
  config,
  lib,
  pkgs,
  hostVars,
  end-4-dots,
  ...
}:

let
  rawConfig = builtins.readFile "${end-4-dots}/dots/.config/hypr/hyprland/keybinds.conf";

  # Remove keys
  keysToRemove = [
    "catchall"
    "submap"
    "RANDOM_IMAGE"
    "bind = Super+Shift, X"
    "bind = Super+Shift, T"
    "Super, B, global, quickshell:sidebarLeftToggle"
    "Super, O, global, quickshell:sidebarLeftToggle"
    "Ctrl+Alt, T, exec, ~/.config/hypr/hyprland/scripts/launch_first_available.sh"
  ];

  # Override keys
  keysToOverride = [
    # "bindd = $mainMod, V"
    # "bind = $mainMod, Tab"
  ];

  keysToDelete = keysToRemove ++ keysToOverride;

  filterConfig =
    content:
    let
      lines = lib.splitString "\n" content;
      shouldKeep = line: !(lib.any (key: lib.strings.hasInfix key line) keysToDelete);
      filteredLines = builtins.filter shouldKeep lines;
    in
    lib.concatStringsSep "\n" filteredLines;

  finalConfig =
    builtins.replaceStrings
      [
        # === Original bindings ===
        "bindid = Super, Super_L, Toggle search"
        "bindid = Super, Super_R, Toggle search"
        "movetoworkspacesilent"

        # Screenshot
        "Ctrl,Print,"
        "$(xdg-user-dir PICTURES)"

        # Media and system
        "Super, M, Toggle media controls"
        "Super+Alt,M, Toggle mic"
        "Super, L, Lock"
        "Super+Shift, L, Suspend system"

        # Workspace
        "Super+Alt, code:"
        "Ctrl+Super, Right, workspace, r+1"
        "Ctrl+Super, Left, workspace, r-1"

        # Focus window
        "Super, Left, movefocus, l"
        "Super, Right, movefocus, r"
        "Super, Up, movefocus, u"
        "Super, Down, movefocus, d"

        # Application
        "Super, Return, exec, $terminal"
        "Super, W, exec, $browser"
        "Super, C, exec, $codeEditor"
        "Super, T, exec, $terminal"

        "Super"
      ]
      [
        # === Customized bindings ===
        "# bindd = $mainMod, Tab, Toggle search"
        "# bindd = $mainMod, Tab, Toggle search"
        "movetoworkspace"

        # Screenshot
        "$mainMod Ctrl,Backspace,"
        "/home/$(whoami)/Pictures"

        # Media and system
        "$mainMod Ctrl, M, Toggle media controls"
        "$mainMod,M, Toggle mic"
        "$mainMod Shift, L, Lock"
        "$mainMod Shift, Backspace, Suspend system"

        # Workspace
        "$mainMod+Shift, code:"
        "$mainMod, l, workspace, r+1"
        "$mainMod, h, workspace, r-1"

        # Focus window
        "$mainMod Ctrl, h, movefocus, l"
        "$mainMod Ctrl, l, movefocus, r"
        "$mainMod Ctrl, k, movefocus, u"
        "$mainMod Ctrl, j, movefocus, d"

        # Application
        "$mainMod, Space, exec, $terminal"
        "$mainMod, B, exec, $browser"
        "$mainMod, C, exec, livecaptions"
        "$mainMod, D, exec, discord"

        "$mainMod"
      ]
      (filterConfig rawConfig);
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mainMod" = "SUPER";
    };

    extraConfig = finalConfig;
  };
}
