-- Raw Hyprland Lua, loaded last (after every hypr/hyprland/*.lua file) —
-- see modules/home-manager/dotfiles/caelestia-shell/default.nix. Escape
-- hatch for anything hypr-vars.lua's variable overrides can't express
-- (new binds, monitor layout, extra window/layer rules).
--
-- Symlinked live from this repo path (not copied into the Nix store), so
-- editing this file and running `hyprctl reload` applies immediately —
-- no `home-manager switch` needed.

-- Mic mute. hypr/hyprland/keybinds.lua:187 already binds the hardware key
-- (XF86AudioMicMute) to this same command, hardcoded (not a kb* variable,
-- so it can't be overridden via hypr-vars.lua) — this just adds a second,
-- ordinary keybind for it. `locked = true` matches the existing mic/volume
-- binds so it still works while the session is locked.
hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
