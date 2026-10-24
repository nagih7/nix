# Documentation

Everything about working *on* this config lives here. The top-level
[`README.md`](../README.md) stays the intro for someone meeting the repo for
the first time (install, aliases, screenshots).

| Doc | What it covers |
| --- | --- |
| [commands.md](commands.md) | Build, switch, verify a change without switching, and which changes need which of those |
| [architecture.md](architecture.md) | Host discovery and the constants layering, the desktop-shell provider option, the three ways config reaches disk, Hyprland Lua gotchas, secrets, conventions |
| [caelestia-patches.md](caelestia-patches.md) | The local QML patches to caelestia-shell — what each fixes, the option gating it, how to retest and regenerate after an upstream bump |
| [quickshell-module.md](quickshell-module.md) | The hand-rolled `ii` (end-4) quickshell module: structure and troubleshooting |
| [caelestia-templates.md](caelestia-templates.md) | caelestia-cli theme templates — substitution syntax and where output lands |

Start with [architecture.md](architecture.md) if you're changing how something
is wired, [commands.md](commands.md) if you just need to build and test.
