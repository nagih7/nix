-- Overrides merged into caelestia-dots' hypr/variables.lua before any
-- Hyprland config is parsed — see
-- modules/home-manager/dotfiles/caelestia-shell/default.nix for the merge
-- mechanism, and ../../../caelestia/hypr/variables.lua (the vendored
-- caelestia-dots clone) for the full list of overridable keys (kb*
-- keybinds, colours, gaps, cursor, etc).
--
-- Symlinked live from this repo path (not copied into the Nix store), so
-- editing this file and running `hyprctl reload` applies immediately —
-- no `home-manager switch` needed.

return {
  -- Apps
  terminal                   = "alacritty",
  browser                    = "zen",
  editor                     = "codium",
  fileExplorer               = "thunar",
  audioSettings              = "pwvucontrol",

  -- Touchpad
  touchpadDisableTyping      = true,
  touchpadScrollFactor       = 0.3,
  gestureFingers             = 3,
  workspaceSwipeFingers      = 4,
  gestureFingersMore         = 4,

  -- Blur
  blurEnabled                = true,
  blurSpecialWs              = false,
  blurPopups                 = true,
  blurInputMethods           = true,
  blurSize                   = 8,
  blurPasses                 = 2,
  blurXray                   = false,

  -- Shadow
  shadowEnabled              = true,
  shadowRange                = 15,
  shadowRenderPower          = 4,
  -- shadowColour               = "rgba(" .. scheme.inversePrimary .. "10)",

  -- Gaps
  workspaceGaps              = 20,
  windowGapsIn               = 5,
  windowGapsOut              = 10,
  singleWindowGapsOut        = 20,

  -- Window styling
  windowOpacity              = 0.95,
  windowRounding             = 15,
  windowRoundingPower        = 2,
  windowBorderSize           = 1,
  -- activeWindowBorderColour   = "rgba(" .. scheme.primary .. "e6)",
  -- inactiveWindowBorderColour = "rgba(" .. scheme.onSurfaceVariant .. "11)",

  -- Misc
  volumeStep                 = 3,
  volumeMax                  = 120,
  cursorTheme                = "sweet-cursors",
  cursorSize                 = 24,
  sleepGestureCmd            = "systemctl suspend-then-hibernate",

  ------------------
  ---- KEYBINDS ----
  ------------------

  -- Modifier only, the actual binds will be mod + 0-9. These should be strings and not arrays.
  kbGoToWs                   = "SUPER",
  kbGoToWsGroup              = "CTRL + SUPER",
  kbMoveWinToWs              = "SUPER + SHIFT",
  kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",

  -- All the following binds can be either an array of binds to bind multiple keys, or a single string.

  -- Workspaces
  kbMoveWinToWsSpecial       = { "SUPER + ALT + S", "CTRL + SUPER + SHIFT + Up" },
  kbMoveWinFromWsSpecial     = "CTRL + SUPER + SHIFT + Down",
  kbMoveWinToWsNext          = { "SUPER + ALT + mouse_up", "SUPER + ALT + Page_Down", "CTRL + SUPER + SHIFT + Right" },
  kbMoveWinToWsPrev          = { "SUPER + ALT + mouse_down", "SUPER + ALT + Page_Up", "CTRL + SUPER + SHIFT + Left" },
  kbNextWs                   = { "SUPER + mouse_up", "CTRL + SUPER + Right", "SUPER + Page_Down", "SUPER + l" },
  kbPrevWs                   = { "SUPER + mouse_down", "CTRL + SUPER + Left", "SUPER + Page_Up", "SUPER + h" },
  kbNextWsGroup              = "CTRL + SUPER + mouse_down",
  kbPrevWsGroup              = "CTRL + SUPER + mouse_up",

  -- Window Group
  kbWindowCycleNext          = "ALT + TAB",
  kbWindowCyclePrev          = "SHIFT + ALT + TAB",
  kbWindowGroupCycleNext     = "CTRL + ALT + TAB",
  kbWindowGroupCyclePrev     = "CTRL + SHIFT + ALT + TAB",
  kbUngroup                  = "SUPER + U",
  kbToggleGroup              = "SUPER + Comma",
  kbGroupLockActive          = "SUPER + SHIFT + Comma",

  -- Window Actions
  kbWindowDecreaseWidth      = { "SUPER + Minus", "SUPER + ALT + Left" },
  kbWindowIncreaseWidth      = { "SUPER + Equal", "SUPER + ALT + Right" },
  kbWindowDecreaseHeight     = { "SUPER + SHIFT + Minus", "SUPER + ALT + Up" },
  kbWindowIncreaseHeight     = { "SUPER + SHIFT + Equal", "SUPER + ALT + Down" },

  kbMoveWindow               = "SUPER + Z",
  kbResizeWindow             = "SUPER + X",
  kbCenterWindow             = "CTRL + SUPER + Backslash",
  kbNormalizeWindow          = "CTRL + SUPER + ALT + Backslash",
  kbWindowPip                = "SUPER + ALT + Backslash",
  kbPinWindow                = "SUPER + P",
  kbWindowFullscreen         = "SUPER + F",
  kbWindowBorderedFullscreen = "SUPER + ALT + F",
  kbToggleWindowFloating     = "SUPER + ALT + Space",
  kbCloseWindow              = "SUPER + Q",

  -- Special workspaces toggles
  -- kbSpecialWs disabled here — its bind (hypr/utils/functions.lua's
  -- generic fn.toggle("specialws")) targets whatever special workspace is
  -- *currently* active, not specifically "special:special", so pressing
  -- it while e.g. communication (SUPER+D) is open closes communication
  -- instead of opening the scratchpad. See hypr-user.lua for the
  -- replacement, which always targets special:special.
  kbSpecialWs                = "",
  kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
  kbMusicWs                  = "SUPER + M",
  kbCommunicationWs          = "SUPER + D",
  kbTodoWs                   = "SUPER + R",

  -- Apps
  kbTerminal                 = "SUPER + Space",
  kbBrowser                  = "SUPER + B",
  kbEditor                   = "SUPER + C",
  kbFileExplorer             = "SUPER + E",
  kbAudioSettings            = "SUPER + CTRL + ALT + M",

  -- Utilities
  kbScreenshot               = "Print",
  kbScreenshotFreeze         = "SUPER + SHIFT + S",
  kbScreenshotRegion         = "SUPER + SHIFT + ALT + S",
  kbRecord                   = "CTRL + ALT + R",
  kbRecordSound              = "SUPER + ALT + R",
  kbRecordRegion             = "SUPER + SHIFT + ALT + R",
  kbColorPicker              = "SUPER + SHIFT + C",

  -- Media
  kbMediaToggle              = "SUPER + ALT + M",
  kbMediaNext                = "CTRL + SUPER + Equal",
  kbMediaPrev                = "CTRL + SUPER + Minus",
  kbMediaStop                = "CTRL + SUPER + Backspace",
  kbVolumeMute               = "SUPER + SHIFT + M",

  -- Misc
  -- Disabled here — kbLauncher only works via variables.lua's default
  -- comparison against "SUPER + SUPER_L" (see hypr-user.lua's custom bind,
  -- which replaces this with a real SUPER+TAB combo wired correctly).
  kbLauncher                 = "",
  kbSession                  = "CTRL + ALT + Delete",
  kbShowSidebar              = "SUPER + N",
  kbClearNotifs              = "CTRL + ALT + C",
  kbShowPanels               = "SUPER + K",
  kbLock                     = "SUPER + Backspace",
  kbRestoreLock              = "SUPER + ALT + L",
  kbSleep                    = "SUPER + SHIFT + L",

  -- Clipboard and emoji picker
  kbClipboard                = "SUPER + V",
  kbClipboardDel             = "SUPER + ALT + V",
  kbClipboardPasteLatest     = "CTRL + SHIFT + ALT + V",
  kbEmoji                    = "SUPER + Period",
}
