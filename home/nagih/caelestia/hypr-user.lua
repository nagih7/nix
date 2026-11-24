-- Raw Hyprland Lua, loaded last (after every hypr/hyprland/*.lua file) —
-- see modules/home-manager/dotfiles/caelestia-shell/default.nix. -- Mic mute.

hl.bind("SUPER + CTRL + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Launcher on SUPER + TAB. Replaces kbLauncher (disabled, set to "" in
-- hypr-vars.lua).
hl.bind(
  "SUPER + TAB",
  hl.dsp.exec_cmd(
    'qs ipc --pid "$(systemctl --user show -p MainPID --value caelestia.service)" call drawers toggle launcher'
  )
)

-- Close any active special workspace (kbMusicWs/kbCommunicationWs/
-- kbTodoWs — SUPER+M/D/R) when switching to a numbered workspace
-- (SUPER+1..0). +D then SUPER+M).
local vars = require("variables")

local function closeActiveSpecial()
  local active = hl.get_active_special_workspace()
  if active then
    hl.dispatch(hl.dsp.workspace.toggle_special((active.name:gsub("^special:", ""))))
  end
end

for i = 1, 10 do
  local key = i % 10
  hl.bind(vars.kbGoToWs .. " + " .. key, closeActiveSpecial)
end

-- SUPER + S: always activate special:special (the scratchpad), never
-- deactivate whatever else is open.
hl.bind("SUPER + S", function()
  local active = hl.get_active_special_workspace()
  if active and active.name == "special:special" then
    hl.dispatch(hl.dsp.workspace.toggle_special("special"))
  else
    hl.dispatch(hl.dsp.focus({ workspace = "special:special" }))
  end
end)

-- Monitor layout: the active `monitors` profile (see
-- home/nagih/caelestia/default.nix; `monitors list|apply|save`). Loaded
-- here, last, so it overrides general.lua's auto-detect hl.monitor call,
-- and re-applied on every hyprctl reload. The pointer is in ~/.local/state,
-- not the repo. A broken profile falls back to `default` instead of
-- aborting the rest of this file.
do
  local home = os.getenv("HOME")
  local pointer = (os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")) .. "/monitor-profiles/active"
  local f = io.open(pointer)
  local name = f and f:read("*l") or "default"
  if f then f:close() end

  local function load(profile)
    return pcall(dofile, home .. "/.config/caelestia/monitor-profiles/" .. profile .. ".lua")
  end

  if not load(name) and name ~= "default" then
    load("default")
  end
end

-- Apps that open fullscreen by default (window class, see
-- `hyprctl clients | grep class`). Add/remove entries here, then
-- `hyprctl reload` — no home-manager switch needed. Only affects windows
-- opened after the reload.
local fullscreenApps = {
  "zen",
  "com.anthropic.Claude",
  "code"
}

if #fullscreenApps > 0 then
  hl.window_rule({
    match = { class = "^(" .. table.concat(fullscreenApps, "|") .. ")$" },
    fullscreen = true,
  })
end

-- Dictionary "Look Up": select a word anywhere, press SUPER + CTRL + D, get a
-- definition popup at the mouse. The shortcut lives here rather than in
-- modules/home-manager/desktop/dictionary so it can be changed with
-- `hyprctl reload`; the popup's size and placement are window rules in that
-- module, because they have to agree with each other numerically.
hl.bind("SUPER + CTRL + D", hl.dsp.exec_cmd("dict-popup"))

-- Region screenshot straight to the clipboard (freeze mode), replacing the
-- upstream kbScreenshotFreeze bind (disabled in hypr-vars.lua) which opens
-- the region in swappy instead. Caelestia ships the clipboard-only variant
-- as its own global shortcut — see modules/areapicker/AreaPicker.qml.
hl.bind("SUPER + SHIFT + S", hl.dsp.global("caelestia:screenshotFreezeClip"))
