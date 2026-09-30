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
