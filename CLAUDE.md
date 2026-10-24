# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

All guidance lives in [`docs/`](docs/) so humans and agents read the same
thing. Read these before changing anything non-trivial:

- [`docs/commands.md`](docs/commands.md) — how to build and verify a change
  without a full switch, and which kinds of change need a switch, a
  `hyprctl reload`, or a service restart.
- [`docs/architecture.md`](docs/architecture.md) — the constants layering
  (`variables.nix` → `hosts/*/variables.nix` → `home/*`), the
  `custom.desktopShell` provider option every consumer reads, and the three
  ways config reaches disk (Nix-managed vs out-of-store symlink vs seed-once
  activation). That last section is the one most likely to be got wrong.
- [`docs/caelestia-patches.md`](docs/caelestia-patches.md) — before touching
  the local QML patches or bumping the caelestia flake inputs.

[`docs/README.md`](docs/README.md) indexes the rest.

Two things worth knowing before the first tool call:

- New files must be `git add`ed before building; flakes only see git-tracked
  files.
- `nix fmt` is tree-wide. Don't run it when unrelated work is uncommitted.
