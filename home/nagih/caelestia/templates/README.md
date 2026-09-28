# Custom caelestia-cli theme templates

Symlinked live (out-of-store) at `~/.config/caelestia/templates/` — see
../../../modules/home-manager/dotfiles/caelestia-shell/default.nix.

Any file placed here gets template-substituted on every scheme/wallpaper
change and written to `~/.local/state/caelestia/theme/<same-filename>`
(you symlink that output to wherever the target app actually reads its
config — caelestia-cli does not do this last step for you).

Syntax: `{{ <color>.<format> }}`, e.g. `{{ primary.hex }}`,
`{{ background.rgb }}`. Color role names are the Material You roles
(primary, secondary, background, surface, ...); formats are `hex`, `rgb`,
`hsl`, or a single channel (`red`, `green`, `blue`, `hue`, `saturation`,
`lightness`).

Only read by caelestia-cli (`apply_user_templates` in
utils/theme.py) — never rewritten by it, so safe to edit freely and keep
under version control, unlike shell.json/shell-tokens.json (those are
read/write from the shell's own settings UI — see the caelestia-shell
provider's README notes on why those aren't symlinked here the same way).
