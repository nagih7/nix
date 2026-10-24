# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

The flake is pure — no `--impure`. `programs.nh` exports `NH_FLAKE`, so none of
these take a path argument.

```bash
nixs              # nh os switch — rebuild + switch (needs a TTY for sudo; ask the user to run it)
nixt              # nh os test — activate without a boot entry
hms               # nh home switch -b bak — Home Manager only
nixu              # nix flake update
nixc              # nh clean all --keep 3
nix fmt           # nixfmt, tree-wide
nix develop       # nixfmt-tree, nixd, nh, agenix, home-manager
```

### Verifying a change without switching

`nix flake check` builds **every** host and home configuration — slow but
complete. To check only what you touched:

```bash
nix build --no-link '.#homeConfigurations.nagih@desktop.activationPackage'
nix build --no-link '.#nixosConfigurations.desktop.config.system.build.toplevel'
nix eval '.#homeConfigurations."nagih@desktop".config.<option path>'
```

Prefer these over asking for a switch. `sudo nixos-rebuild` needs a TTY this
tool doesn't have, so a system switch is always the user's to run.

**New files must be `git add`ed before building** — flakes only see
git-tracked files, and an untracked file fails eval with "Path ... is not
tracked by Git".

## Architecture

### Host discovery and the two configurations

`flake.nix` reads `./hosts/*` (minus `common/`) and builds, per host, both a
`nixosConfigurations.<host>` and a `homeConfigurations.nagih@<host>`. Both get
the **same** `pkgs` instance so they can never drift. Adding a host means
adding `hosts/<name>/{default,variables,hardware-configuration}.nix` — no
`flake.nix` edit.

Three layers of constants, in widening scope:

| File | Holds | Read as |
| --- | --- | --- |
| `variables.nix` | state versions, arch, active desktop shell | `systemVars` |
| `hosts/<name>/variables.nix` | hostname, repo path, cpu/gpu, users | `hostVars`, and typed as `config.host.*` |
| `home/<user>/` | that user's packages, aliases, ssh | — |

`hosts/<name>/variables.nix` stays a plain attrset (flake.nix reads it as
data) but is also assigned to `config.host` by `modules/nixos/host-options.nix`,
which type-checks it and rejects unknown keys. **NixOS modules read
`config.host.*`, not raw `hostVars`.** Home Manager modules do use `hostVars`
directly — notably `hostVars.nixConfig`, the absolute repo path, for
out-of-store symlinks.

### Desktop shell providers

`systemVars.desktopShell` picks one of `modules/home-manager/desktop-shell/providers/`
(`ii` = end-4/dots-hyprland, `caelestia` = caelestia-dots; currently
`caelestia`). The provider is exposed as the typed submodule
`config.custom.desktopShell`, and **every consumer reads that option instead of
importing a dotfiles flake input directly**. Every leaf defaults to `null`,
which consumers treat as "this provider has no opinion here"; a provider
returning an unknown key or wrong type fails at eval.

Consequences when editing:

- Shell-specific config belongs behind `lib.mkIf (config.custom.desktopShell.name == "...")`.
  See `modules/home-manager/desktop/hyprland/modules/appearance.nix` for the
  pattern (its monitor layout is ii-only; caelestia uses monitor profiles).
- `./desktop-shell` must be imported **before** anything reading
  `config.custom.desktopShell` — `modules/home-manager/default.nix` relies on
  import order here.
- Both providers must keep building. After touching shared code, build the
  home configuration with `systemVars.desktopShell` flipped to `ii` too.

### Three ways config reaches disk

This is the distinction that matters most in this repo. Pick by **who writes
the file at runtime**:

1. **Nix-managed** (`xdg.configFile."x".text`, `home.file`) — read-only store
   symlink. For anything nothing writes back.
2. **Out-of-store symlink** (`config.lib.file.mkOutOfStoreSymlink
   "${hostVars.nixConfig}/..."`) — the live file *is* the repo file. Edit and
   reload with no `home-manager switch`. Only valid for pure user input that
   nothing writes back; verify that by reading the consuming source, not by
   assuming. Used for `caelestia/hypr-vars.lua`, `hypr-user.lua`, `cli.json`,
   `templates/`, `monitor-profiles/`.
3. **Seed-once activation script** (`home.activation.*` with
   `config.lib.dag.entryAfter [ "writeBoundary" ]`) — for files an application
   rewrites itself. A repo symlink here would dirty the git tree on every
   settings tweak or wallpaper change.

`~/.config/caelestia/shell.json` is case 3 and **must never** be symlinked or
set via `programs.caelestia.settings`: caelestia's C++ plugin
(`RootNode::saveToFile` + `QFileSystemWatcher` live reload) rewrites the whole
file on any property change, including from its own settings UI. Declare
defaults through `custom.caelestiaShell.shellJsonDefaults`, which deep-merges
`defaults * live` in jq — **live always wins**, so it only fills genuinely
missing keys, once. Flipping an already-seeded key needs editing the live file.

### Centralized user config

`home/nagih/caelestia/` is the single place for caelestia settings, mixing both
kinds deliberately:

- `default.nix` — Nix-level declarations (needs a switch). Also defines the
  `monitors` helper script.
- `hypr-vars.lua`, `hypr-user.lua`, `cli.json`, `templates/`,
  `monitor-profiles/` — live symlinks, `hyprctl reload` is enough.

When adding a user-facing toggle, declare the option in the module under
`modules/home-manager/dotfiles/caelestia-shell/` and set its value here, rather
than hardcoding it in the module.

Note: a module declaring a top-level `options` **cannot** also use flat config
keys in the same returned set ("unsupported attribute" eval error) — everything
must move under an explicit `config.`. `caelestia-shell/default.nix` does this.

### Hyprland Lua config

Hyprland 0.55 with `configType = "lua"` — `hl.bind`, `hl.monitor({...})`,
`hl.window_rule({...})`, `hl.dsp.*`. Two gotchas:

- hyprlang-style `settings.monitor` is ignored (rendered as a bare string, not
  the table `hl.monitor()` wants) — monitor layout must be raw Lua.
- `lib.mkBefore`/`mkAfter` order matters for `extraConfig`. Lua's `require`
  caches by first call, so `hypr-vars.lua`'s overrides must be merged into the
  `variables` module textually *before* anything reads it, and `hypr-user.lua`
  required last. Without this `hypr-vars.lua` is silently inert.

Multiple binds on the same key combo all fire. To replace an upstream bind,
disable it (set the `kb*` var to `""` in `hypr-vars.lua`) and add the
replacement in `hypr-user.lua` — don't just add a second one.

### Upstream QML patches

`modules/home-manager/dotfiles/caelestia-shell/patches/` holds local fixes to
the caelestia shell applied via `overrideAttrs`, each gated by a
`custom.caelestiaShell.*` option. **Read `patches/README.md` before touching
them or bumping the shell** — it covers what each patch fixes, how to retest
it, and how to regenerate one without leaving the clone dirty.

Key point: the `caelestia-shell` and `caelestia-dots` flake inputs are
`git+file://` **local clones** outside this repo, not GitHub. Updating the
shell means pulling in the clone, then `nix flake update caelestia-shell`.
A patch that no longer applies fails the build rather than being dropped.

### Secrets

agenix, opt-in per file: the config builds without them and picks each one up
as soon as its `.age` file exists in `secrets/`. Recipients live in
`secrets/secrets.nix`. Edit with `cd secrets && agenix -e <name>.age`.

## Conventions

- Custom options live under the `custom.*` namespace, declared in the module
  that consumes them.
- Comments in this repo explain **why**, often citing the upstream source that
  forced the decision. Match that when adding non-obvious code — and verify
  claims against real source rather than restating an assumption.
- `modules/nixos/default.nix` and `modules/home-manager/default.nix` are
  explicit import lists grouped by section; add new modules there.
