# ██╗    ██╗ ██████╗ ██████╗ ██╗  ██╗███████╗██████╗  █████╗  ██████╗███████╗███████╗
# ██║    ██║██╔═══██╗██╔══██╗██║ ██╔╝██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
# ██║ █╗ ██║██║   ██║██████╔╝█████╔╝ ███████╗██████╔╝███████║██║     █████╗  ███████╗
# ██║███╗██║██║   ██║██╔══██╗██╔═██╗ ╚════██║██╔═══╝ ██╔══██║██║     ██╔══╝  ╚════██║
# ╚███╔███╔╝╚██████╔╝██║  ██║██║  ██╗███████║██║     ██║  ██║╚██████╗███████╗███████║
#  ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝
#---------------------------------------------------------------------------------------
# Pins workspaces to a fixed monitor. Uses settings.workspace_rule (like
# windowrule.nix's `special:special` entry) rather than raw hyprlang text in
# extraConfig, since configType = "lua" renders plain-string settings entries
# as bare Lua strings instead of the {key=value} tables Hyprland's Lua API
# expects (see appearance.nix) — workspace_rule is a table-shaped option, so
# it renders correctly.

{ lib, ... }:

let
  mkAssignment = monitor: ws: {
    workspace = toString ws;
    inherit monitor;
  };
in
{
  # Full decades (1-10, 11-20), not 1-9/11-19: workspace_action.sh computes
  # each key's target as ((curr_workspace - 1) / 10) * 10 + n (bash integer
  # division), so it treats workspace 10 as DP-2's block and 20 as
  # HDMI-A-1's block. Leaving 10/20 unpinned let them land on the wrong
  # monitor, which then misclassified every Windows+1..9 press on that
  # monitor as belonging to DP-2's block.
  wayland.windowManager.hyprland.settings.workspace_rule =
    map (mkAssignment "DP-2") (lib.range 1 10) ++ map (mkAssignment "HDMI-A-1") (lib.range 11 20);
}
