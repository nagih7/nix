# Nix-level declarations for the caelestia desktop shell, alongside the
# live-symlinked hypr-vars.lua/hypr-user.lua/cli.json/templates/ in this
# same directory (see modules/home-manager/dotfiles/caelestia-shell for how
# those get wired in). Unlike those, this file only takes effect through
# `home-manager switch` — it's not a live-reloaded runtime file, just a
# convenient single place to keep every caelestia-related setting instead
# of splitting them between here and home/nagih/default.nix.
{
  config,
  lib,
  pkgs,
  hostVars,
  ...
}:

let
  active = config.custom.desktopShell.name == "caelestia";

  # Monitor profiles: ./monitor-profiles/<name>.lua, each a plain chunk of
  # hl.monitor({...}) calls. Workflow: arrange outputs in wdisplays (applies
  # live, not persisted), then `monitors save <name>` captures the live
  # state into a profile. `monitors apply <name>` re-applies it with
  # `hyprctl eval` (no reload, no home-manager switch) and remembers it as
  # the active profile, which hypr-user.lua loads on every start/reload.
  # The active-profile pointer lives in ~/.local/state (written on every
  # apply), not in the repo, so switching profiles never dirties git.
  monitors = pkgs.writeShellApplication {
    name = "monitors";
    runtimeInputs = [
      pkgs.jq
      pkgs.coreutils
    ];
    text = ''
      dir="$HOME/.config/caelestia/monitor-profiles"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/monitor-profiles/active"

      active() { cat "$state" 2>/dev/null || echo default; }

      set_active() {
        mkdir -p "$(dirname "$state")"
        echo "$1" > "$state"
      }

      usage() {
        cat <<'EOF'
      usage: monitors list
             monitors apply <name>
             monitors save <name>   capture the live layout (e.g. after wdisplays)
      EOF
        exit 1
      }

      case "''${1:-}" in
        list)
          cur=$(active)
          for f in "$dir"/*.lua; do
            [ -e "$f" ] || continue
            n=$(basename "$f" .lua)
            if [ "$n" = "$cur" ]; then echo "* $n"; else echo "  $n"; fi
          done
          ;;
        apply)
          [ -n "''${2:-}" ] || usage
          f="$dir/$2.lua"
          [ -f "$f" ] || { echo "no such profile: $2" >&2; exit 1; }
          # Wrapped in do..end: hyprctl treats an argument starting with "--"
          # as a flag, and a profile's first line is a "-- ..." comment.
          code="do
      $(cat "$f")
      end"
          if ! out=$(hyprctl eval "$code" 2>&1) || [ "$out" != ok ]; then
            echo "$out" >&2
            exit 1
          fi
          set_active "$2"
          echo "applied: $2"
          ;;
        save)
          [ -n "''${2:-}" ] || usage
          case "$2" in
            *[!A-Za-z0-9_-]*) echo "profile names: letters, digits, - and _ only" >&2; exit 1 ;;
          esac
          f="$dir/$2.lua"
          {
            echo '-- Saved by "monitors save". Hand-editable; see home/nagih/caelestia/default.nix.'
            hyprctl -j monitors all | jq -r '.[] |
              if .disabled then
                "hl.monitor({ output = \"\(.name)\", disabled = true })"
              else
                "hl.monitor({ output = \"\(.name)\", disabled = false, mode = \"\(.width)x\(.height)@\((.refreshRate * 100 | round) / 100)\", position = \"\(.x)x\(.y)\", scale = \((.scale * 100 | round) / 100), transform = \(.transform) })"
              end'
          } > "$f.tmp"
          mv "$f.tmp" "$f"
          set_active "$2"
          echo "saved: $f"
          ;;
        *) usage ;;
      esac
    '';
  };
in
{
  # See modules/home-manager/dotfiles/caelestia-shell for how/when these
  # get applied to ~/.config/caelestia/shell.json (short version: seeded
  # once each, only if genuinely missing — never overwrites a value you or
  # the shell itself later changes).
  custom.caelestiaShell.shellJsonDefaults = {
    osd = {
      enableMicrophone = true;
      enableBrightness = false;
    };
  };

  home.packages = lib.mkIf active [ monitors ];

  # Live symlink into the repo, same idea as hypr-vars.lua/hypr-user.lua:
  # `monitors save` writes straight into git-tracked ./monitor-profiles/.
  xdg.configFile."caelestia/monitor-profiles" = lib.mkIf active {
    source = config.lib.file.mkOutOfStoreSymlink "${hostVars.nixConfig}/home/nagih/caelestia/monitor-profiles";
  };
}
