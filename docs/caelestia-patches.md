# caelestia-shell patches

Local fixes applied to the upstream shell via `overrideAttrs { patches = ... }`
in [`caelestia-shell/default.nix`](../modules/home-manager/dotfiles/caelestia-shell/default.nix). Each one exists because the behaviour is
hardcoded in QML with no `shell.json` key to change it.

## Why a patch and not config

`~/.config/caelestia/shell.json` is owned by the shell's own C++ plugin
(`RootNode::saveToFile` + a `QFileSystemWatcher` live reload), so it can only
carry keys upstream actually declares. Everything below is either a hardcoded
literal or a guard clause, so the only lever is the source.

Patches apply at build time: changing one needs a `home-manager switch` **and**
`systemctl --user restart caelestia.service`. That restart closes apps launched
from the shell's launcher (they live in the service's cgroup).

## The patches

| Patch | Gated by | Touches |
| --- | --- | --- |
| `launcher-no-displaced-transition.patch` | always on | `modules/launcher/AppList.qml` |
| `picker-no-dim-in-clipboard-mode.patch` | `custom.caelestiaShell.dimOutsideSelection = false` | `modules/areapicker/Picker.qml` |
| `drawers-over-fullscreen.patch` | `custom.caelestiaShell.drawersOverFullscreen = true` | `modules/Shortcuts.qml`, `modules/drawers/ContentWindow.qml` |
| `vpn-autodiscover-networkmanager.patch` | `custom.caelestiaShell.vpnAutodiscover = true` | `services/VPN.qml`, `modules/nexus/pages/NetworkPage.qml` |

Options are declared in [`caelestia-shell/default.nix`](../modules/home-manager/dotfiles/caelestia-shell/default.nix) and set centrally in
`home/nagih/caelestia/default.nix`.

### `launcher-no-displaced-transition.patch`

Drops the `displaced: Transition` block from the launcher's `ListView`. With it,
typing fast (e.g. `di`, keystrokes under ~400ms apart) segfaults quickshell in
`QQmlDelegateModel::itemsMoved` after `ScriptModel` reorders rows. Reproducible
on the stock shell; gone without it. Related upstream issues (#885, #1150,
#1164) describe a different code path (raw JS arrays), so don't assume a fix
there covers this.

**If upstream reworks the launcher list:** retest the crash before dropping the
patch — open the launcher and type `di` quickly a few times. Keep it only if it
still reproduces.

### `picker-no-dim-in-clipboard-mode.patch`

The region screenshot picker tints everything outside the selection
(`opacity: 0.3` on the `overlay` rect). This makes the tint conditional on
`loader.clipboardOnly`, so the clipboard-only modes
(`caelestia:screenshotClip` / `screenshotFreezeClip`) stay untinted while the
swappy-bound modes keep dimming. The selection border still marks the capture
area, and the tint never reached the saved image either way.

### `drawers-over-fullscreen.patch`

Makes the launcher/session/dashboard usable while a fullscreen window is
focused. Upstream blocks this in **three** independent places — all three have
to go, so a partial revert silently does nothing:

1. `modules/Shortcuts.qml` — the `drawers` IPC `toggle` returns early for
   those three drawers when `hasFullscreen`.
2. `modules/drawers/ContentWindow.qml` — `WlrLayershell.layer` stays
   `WlrLayer.Top` (below the fullscreen window) unless
   `Config.general.showOverFullscreen` is set. The patch drops that config
   check so the Nix option is the single switch and `shell.json` stays out of
   it (`shellJsonDefaults` only seeds missing keys once, so it couldn't flip
   this reliably later).
3. `modules/drawers/ContentWindow.qml` — `mask` is set to `emptyRegion` while
   fullscreen, emptying the input region. The patch adds a `hasOpenDrawer`
   property and keeps `regions` whenever a drawer is open.

Left alone on purpose: `onHasFullscreenChanged` still closes open drawers when
you *enter* fullscreen. Only reopening while already fullscreen was broken.

Note the upstream guards test `fullscreen > 1`, i.e. real fullscreen only —
Hyprland's maximize (state 1) was never blocked.

### `vpn-autodiscover-networkmanager.patch`

The VPN panel only ever lists what `shell.json`'s `utilities.vpn.provider`
declares, so an NM-managed tunnel has to be described twice — once in
NetworkManager (keys, peers, endpoint) and again in the shell (name,
interface, `nmcli` commands), kept in sync by hand. This polls `nmcli` for
`wireguard`/`vpn` connections and folds them into the provider list.

The invasive part is **index semantics**, and that is what to check after any
upstream change here. `providers` was exactly the config list, and the editing
UI addresses entries by their index into it (`updateProvider(index)`,
`deleteProvider(index)`, `setActiveProvider(index)`, `AddVpnPage.qml`'s
`VPN.providers[editIndex]`). The patch appends auto entries *after* the
configured ones so those indices still line up, switches `providerIdAt` to
index the combined list, and makes `updateProvider`/`deleteProvider` refuse
entries flagged `auto: true` — they are plain objects with no config node
behind them, so calling `resetOption()` on one would throw.

`NetworkPage.qml`'s edit button stays visible for auto entries but changes
target: the sub-page has nothing to edit, so it launches
`nm-connection-editor --edit=<uuid>` instead — the real settings (keys, peers,
endpoint) were always NetworkManager's, never the shell's. Auto entries carry
the raw `uuid` for this. `nm-connection-editor` comes from
`networkmanagerapplet` in `modules/nixos/desktop/hyprland.nix` and resolves
through `/run/current-system/sw/bin`, which is on the shell service's PATH.

Details worth keeping:

- Auto entries are keyed `nm:<uuid>`, not by name, so renaming the connection
  in NM doesn't orphan the selection.
- An auto entry is dropped when a configured entry already has the same
  `interface`, so a hand-written override wins instead of appearing twice.
- Discovery iterates UUIDs rather than parsing `nmcli -t` list output:
  `nmcli -t` escapes `:` in names, and list mode has no interface-name field
  (`DEVICE` is only populated while the connection is up), so the interface is
  queried per connection with `-g connection.interface-name`.
- Only `wireguard` and `vpn` connection types are listed — Tailscale shows up
  as type `tun` and is managed outside the shell here.

## Updating caelestia

The flake input is the local clone, not GitHub:

```nix
caelestia-shell.url = "git+file:///home/nagih/Workspaces/config/caelestia-dots";
```

So an update is:

```bash
git -C ~/Workspaces/config/caelestia-dots pull
cd ~/Workspaces/config/nixos
nix flake update caelestia-shell
nix build --no-link '.#homeConfigurations.nagih@desktop.activationPackage'
```

**A patch that no longer applies fails the build** — `patchPhase` errors out
with `malformed patch` or `Hunk #1 FAILED`, naming the file. That is the safety
net: a stale patch is never silently dropped. Only the final shell derivation
rebuilds (cmake install of QML); the C++ plugin and extras are separate
derivations and stay cached.

### Regenerating a patch

Edit the clone, diff, then restore it — never leave the clone dirty, since it
*is* the flake input:

```bash
cd ~/Workspaces/config/caelestia-dots
$EDITOR modules/drawers/ContentWindow.qml
git --no-pager diff --no-color -U3 -- modules/drawers/ContentWindow.qml \
  > ~/Workspaces/config/nixos/modules/home-manager/dotfiles/caelestia-shell/patches/<name>.patch
git checkout -- modules/drawers/ContentWindow.qml
git status --porcelain   # must be empty
```

Write patches with real `git diff`, not by hand — hand-counted hunk headers
(`@@ -235,7 +235,9 @@`) are how `malformed patch` happens.

New patch files must be `git add`ed before building: flakes only see
git-tracked files, so an untracked patch fails eval with "Path ... is not
tracked by Git".
