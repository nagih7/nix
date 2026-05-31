{ config, pkgs, ... }:

{
  imports = [
    ./general.nix
    ./autostart.nix
    # colors.nix / programs.nix dropped for Lua: hyprlang "$variables" do not
    # exist in Lua. Colours were unused by the injected configs (general.lua
    # uses literal rgba), and the app/$qsConfig locals now live in keybinds.lua.
    ./environment.nix
    ./keybinding.nix
    ./windowrule.nix
  ];
}
