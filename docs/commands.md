# Commands

The flake is pure — no `--impure`. `programs.nh` exports `NH_FLAKE`, so none of
these take a path argument.

```bash
nixs              # nh os switch — rebuild + switch (needs a TTY for sudo)
nixt              # nh os test — activate without a boot entry
hms               # nh home switch -b bak — Home Manager only
nixu              # nix flake update
nixc              # nh clean all --keep 3
nix fmt           # nixfmt, tree-wide
nix develop       # nixfmt-tree, nixd, nh, agenix, home-manager
```

## Verifying a change without switching

`nix flake check` builds **every** host and home configuration — slow but
complete. To check only what you touched:

```bash
nix build --no-link '.#homeConfigurations.nagih@desktop.activationPackage'
nix build --no-link '.#nixosConfigurations.desktop.config.system.build.toplevel'
nix eval '.#homeConfigurations."nagih@desktop".config.<option path>'
```

Prefer these over a full switch. `sudo nixos-rebuild` needs a TTY, so a system
switch can't run unattended.

**New files must be `git add`ed before building** — flakes only see git-tracked
files, and an untracked file fails eval with "Path ... is not tracked by Git".

`nix fmt` is `nixfmt-tree` and formats the **whole** repo, so running it with
other work in progress mixes formatting churn into unrelated files. Format only
what you touched, or skip it — nothing in the build requires it.

## What needs a switch, and what doesn't

Not every change here needs `hms`. See
[architecture.md](architecture.md#three-ways-config-reaches-disk) for why:

| Change | To apply |
| --- | --- |
| Nix modules, options, packages | `hms` / `nixs` |
| `hypr-vars.lua`, `hypr-user.lua`, `monitor-profiles/`, `cli.json`, `templates/` | `hyprctl reload` |
| Upstream QML patches ([caelestia-patches.md](caelestia-patches.md)) | `hms` **and** `systemctl --user restart caelestia.service` |
| `shell.json` (seeded defaults) | edit live file or the shell's settings UI |

Restarting `caelestia.service` closes apps launched from the shell's launcher —
they run in the service's cgroup.
