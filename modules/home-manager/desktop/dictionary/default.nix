# macOS-style dictionary "Look Up": select a word anywhere, press
# SUPER + CTRL + D, and a definition popup opens at the mouse.
#
# Pieces, deliberately separable so each can be exercised on its own:
#
#   dict-lookup WORD        plain text on stdout. No Wayland, no window — the
#                           piece to run in a terminal when a definition looks
#                           wrong. `--list` shows what is actually loaded.
#   dict-lookup --html      the same lookup rendered as HTML, for the popup.
#   dict-popup              reads the selection and shows the result, through
#                           whichever `popup.backend` is selected.
#   dict-import-macos       converts macOS .dictionary bundles to StarDict.
#   SUPER + CTRL + D        bound in home/nagih/caelestia/hypr-user.lua, not
#                           here, so the shortcut can change with a
#                           `hyprctl reload` instead of a switch.
#
# The lookup engine and both renderers are Python (lookup.py, render.py,
# cli.py): the HTML renderer has to parse each backend's own text format into
# structure to get the macOS typography, which is real parsing rather than
# something sed should be doing. Keeping the text renderer there too means one
# implementation of the lookups instead of two that drift.
#
# Everything is offline and user-level — no dictd daemon, no system service,
# no sudo. A dictd database is just a sorted `.index` of
# "headword<TAB>offset<TAB>length" (base-64, dictd's own alphabet) beside a
# `.dict`/`.dict.dz`, and `dictzip -S/-E` takes those fields verbatim and
# prints that byte range, so the daemon the `dict` client would need is not.
{
  config,
  lib,
  pkgs,
  hostVars,
  ...
}:

let
  cfg = config.custom.dictionary;

  # Unused while stardict.packages is empty — kept in scope because that is
  # the one line to change to put FVDP's Anh-Việt or Việt-Anh back, and a
  # lazily-unevaluated binding costs nothing. See stardict.packages.
  stardictDictionaries = import ./stardict-dictionaries.nix { inherit lib pkgs; };

  # lxml is needed by render.py to prune Apple's HTML; the elements being
  # removed have to take their subtrees with them, which regex cannot do.
  python = pkgs.python3.withPackages (ps: [ ps.lxml ]);

  stardictRoots = map (d: "${d}/share/stardict/dic") cfg.stardict.packages ++ [
    cfg.stardict.dataDir
  ];

  # Layer 1 of the appearance: everything the popup draws. Overridden by the
  # `theme` option (layer 2) and then by ~/.config/dict-popup/theme.json at
  # run time (layer 3) — see that option's description.
  themeDefaults = {
    width = 640;
    height = 760;
    radius = 18;
    padding = 18;
    borderWidth = 1;

    background = "#1C1A1Fd0";
    border = "#FFFFFF1A";

    foreground = "#ECECECFF";
    muted = "#A8A8A8FF";
    faint = "#8A8A8AFF";
    rule = "#4A4A4AFF";
    accent = "#4DA3FFFF";
    section = "#BFBFBFFF";

    fontPx = 17;
    sectionFontPx = 21;
    # Apple's own: `*.entry { line-height: 140% }`, and 150% in the bilingual
    # stylesheet for the Vietnamese script.
    lineHeightPct = 140;
    # Lines shown per dictionary before a "more" link appears; 0 shows
    # everything. Dictionary.app does the same thing, and does it
    # geometrically — it cuts mid-token ("... | [with  more"), which is why
    # there is no priority metadata in the dictionary data to key a semantic
    # truncation off. Qt's maximumLineCount/truncated are the same mechanism.
    maxLines = 9;
    fontFamily = "Noto Serif";
    labelFontFamily = "SF Pro Text";

    shadowEnabled = true;
    shadowColor = "#000000A0";
    shadowBlur = 40;
    shadowSpread = 0;
    shadowOffsetY = 8;
    shadowOpacity = 1.0;
    # Room left around the card for the shadow to fall into. A layer surface
    # is clipped to its own size, so without this the shadow has nowhere to
    # go and simply does not appear.
    shadowPad = 32;

    offsetY = 24;
    margin = 48;
  };

  theme = themeDefaults // cfg.theme;

  # Written to the store so dict-popup can merge the live file over it with
  # jq, rather than the two layers being spliced together in Nix where the
  # live one is not visible.
  themeFile = pkgs.writeText "dict-popup-theme.json" (builtins.toJSON theme);

  # Qt parses an 8-digit hex colour as #AARRGGBB — alpha first — while CSS and
  # everything else in this config writes #RRGGBBAA. The options take the
  # familiar order and it is rotated here, because getting this wrong is
  # silent: "#1C1A1Fd0" read as Qt intends is 11% opaque and blue, so the
  # popup renders as a barely visible tint rather than an obvious error.
  toQtColor =
    c:
    if builtins.stringLength c == 9 then
      "#" + builtins.substring 7 2 c + builtins.substring 1 6 c
    else
      c;

  lookupConfig = pkgs.writeText "dict-lookup.json" (
    builtins.toJSON {
      inherit (cfg) order;
      dict_order = cfg.dictionaryOrder;
      dict_labels = cfg.sectionLabels;
      dictd_roots = map (db: "${db}/share/dictd") cfg.dictdDatabases;
      stardict_roots = stardictRoots;
      wordnet = cfg.wordnet.enable;
      stardict = cfg.stardict.enable;
      max_senses = cfg.wordnet.maxSenses;
      max_entries = cfg.maxEntriesPerDatabase;
    }
  );

  # cli.py adds its own directory to sys.path so that it can import its
  # siblings under `python3 -I`; they therefore have to sit together.
  pySources = pkgs.runCommandLocal "dict-lookup-python" { } ''
    mkdir -p "$out"
    cp ${./lookup.py} "$out/lookup.py"
    cp ${./render.py} "$out/render.py"
    cp ${./cli.py} "$out/cli.py"
  '';

  dict-lookup = pkgs.writeShellApplication {
    name = "dict-lookup";

    # The Python calls these by name, so they have to be on PATH rather than
    # merely in the closure.
    runtimeInputs = [
      pkgs.coreutils
      pkgs.dict # dictzip
    ]
    ++ lib.optional cfg.wordnet.enable pkgs.wordnet
    ++ lib.optional cfg.stardict.enable pkgs.sdcv;

    text = ''
      # -I isolates the interpreter: no site-packages games, and no importing
      # a stray lookup.py out of whatever directory the popup was launched
      # from. "$@" comes last so a caller can override any of these.
      exec ${python.interpreter} -I ${pySources}/cli.py \
        --config ${lookupConfig} \
        --theme ${themeFile} \
        --font-px ${toString theme.fontPx} \
        --pronunciation ${cfg.pronunciation} \
        "$@"
    '';
  };

  # Runs inside the terminal backend's window. Deliberately does not delete
  # the file it is given: there is only ever one popup, so dict-popup renders
  # to one fixed path and overwrites it. Deleting here would be a race — the
  # outgoing pager's cleanup can land after the incoming one has written the
  # next definition, blanking it.
  pager = pkgs.writeShellScript "dict-popup-pager" ''
    # The "s" in front of the prompt text is required, not decoration: less
    # reads the first character of --prompt as which prompt is being set
    # (s = short, m = medium, ...), so without it the word's own first letter
    # is swallowed as that selector and "serendipity" renders as "erendipity".
    exec ${lib.getExe' pkgs.less "less"} \
      --RAW-CONTROL-CHARS \
      --ignore-case \
      --mouse \
      --prompt="s$2 — press q to close" \
      -- "$1"
  '';

  dict-popup = pkgs.writeShellApplication {
    name = "dict-popup";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.wl-clipboard
      pkgs.jq
      # hyprctl is deliberately absent: it has to be the running compositor's
      # own, and the NixOS module owns that package (home-manager's
      # hyprland.package is null), so this script guards on `command -v`
      # instead and degrades to a top-left popup rather than pinning a
      # possibly-different Hyprland build.
      dict-lookup
    ]
    ++ lib.optional cfg.selection.synthesizeCopy pkgs.wtype
    ++ lib.optional (cfg.popup.backend == "quickshell") pkgs.quickshell;

    text = ''
      class=${lib.escapeShellArg cfg.popup.class}

      # Whitespace-only test via grep rather than ''${word//[[:space:]]/},
      # whose cost is quadratic in the string length — measured at 2.5s on a
      # 38 KB clipboard, and the selection can be a whole paragraph.
      has_content() { printf '%s' "$1" | grep -q '[^[:space:]]'; }

      state=''${XDG_RUNTIME_DIR:-/tmp}/dict-popup
      mkdir -p "$state"
      pidfile=$state/pid
      rendered=$state/definition
      saved_clipboard=$state/clipboard.saved
      logfile=$state/last-run.log
      copy_attempts=${toString cfg.selection.copyAttempts}

      # One lookup at a time, covering the window between here and the
      # pidfile write further down. close_previous keys off that pidfile, so
      # two presses inside dict-lookup's ~0.2s meant the second found no
      # pidfile, killed nothing, and both popups opened — both also writing
      # the same payload and truncating the same log, so one `qs` could read a
      # half-written file. The loser exits silently and *before* the log is
      # truncated, so the winner's diagnostics survive.
      #
      # A directory and not `flock`, which was tried and broke the shortcut
      # after exactly one use. A descriptor is inherited by every child, and
      # wl-copy *daemonises* to serve the clipboard selection, so the wl-copy
      # left behind by the clipboard restore held the lock for as long as it
      # owned the selection — indefinitely:
      #
      #   pid 142027  wl-copy --type image/png   fd 9 -> .../dict-popup/lock
      #
      # Closing the descriptor in this process before exec does not help: the
      # fork already has its own copy. `mkdir` is atomic, belongs to no
      # descriptor, and nothing can inherit it.
      starting=$state/starting
      if ! mkdir "$starting" 2>/dev/null; then
        # Whoever holds it records its pid, so the usual reason for a
        # leftover marker — killed between here and the handoff — is
        # recognised at once rather than waited out. Bash defers a trap until
        # the running foreground command returns, and SIGKILL runs no trap at
        # all, so "the owner is gone" has to be detectable from outside.
        other=$(cat "$starting/pid" 2>/dev/null || true)
        now=$(date +%s)
        made=$(stat -c %Y "$starting" 2>/dev/null || echo 0)
        # Refuse only for a start that is both still running and still
        # plausible. The age check is the backstop for a reused pid and for a
        # lookup wedged in a way that never returns; either way the shortcut
        # heals itself instead of staying dead, which is what the lock got
        # wrong.
        if [ -n "$other" ] && [ -d "/proc/$other" ] && [ "$((now - made))" -lt 60 ]; then
          exit 0
        fi
      fi
      printf '%s\n' "$$" >"$starting/pid" 2>/dev/null || true

      # One run's worth of diagnostics, overwritten each time. Which of the
      # three sources answered is invisible from the popup, and the
      # interesting failures — nothing published, a chord still held, a
      # skipped class — all look identical from outside. Lengths, not
      # contents: this is the clipboard.
      : >"$logfile"
      log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >>"$logfile"; }

      # Every read is pinned to text/plain. Given no type, wl-paste returns
      # whatever the owner offers first, and an image or rich text copied from
      # a browser offers text/html and image/png but no text/plain — so a bare
      # `wl-paste` hands back "<meta http-equiv=..." and that gets looked up
      # as a word. wl-clipboard synthesises text/plain for owners advertising
      # only text/plain;charset=utf-8 or UTF8_STRING, so pinning it stays
      # correct for XWayland apps while still rejecting images and HTML.
      read_primary() { wl-paste --primary --type text/plain --no-newline 2>/dev/null || true; }
      read_clipboard() { wl-paste --type text/plain --no-newline 2>/dev/null || true; }

      # The sentinel must never outlive this script. Nothing inside
      # synthesize_copy can trip errexit — everything fragile there has
      # `|| true` — but an external kill can: Ctrl+C, a pkill, logging out.
      # That used to leave "dict-popup-1234-…" sitting in the clipboard with
      # the real contents only in $saved_clipboard, which the next run
      # overwrites. So the restore is a trap, and the normal path just calls
      # the same function. Idempotent via clipboard_pending, since both do.
      clipboard_pending=""
      restore_clipboard() {
        [ -n "$clipboard_pending" ] || return 0
        clipboard_pending=""
        if [ -n "''${saved_type:-}" ] && [ -s "$saved_clipboard" ]; then
          wl-copy --type "$saved_type" <"$saved_clipboard" >/dev/null 2>&1 || true
        else
          wl-copy --clear >/dev/null 2>&1 || true
        fi
        rm -f "$saved_clipboard"
      }
      # Both halves of the tidy-up in one place, and idempotent, because it
      # is also called explicitly at the handoff — `exec` does not run EXIT
      # traps, and the start marker has to be gone before the popup replaces
      # this process or the next lookup would wait out the staleness window.
      cleanup() {
        restore_clipboard
        # :? so this can never become `rm -rf /` if the variable is somehow
        # empty. The directory holds one file this script wrote.
        rm -rf "''${starting:?}" 2>/dev/null || true
      }
      trap cleanup EXIT
      # Signals exit rather than cleaning up inline, so the EXIT trap stays
      # the single place that does the work.
      trap 'exit 130' INT
      trap 'exit 143' TERM
      trap 'exit 129' HUP

      # Ask the focused window to copy its selection, then put the clipboard
      # back. PRIMARY — the "just select it" buffer — is not universal:
      # Electron apps never publish it, and neither does GTK for a keyboard
      # selection (measured: Ctrl+A in a zenity entry leaves it empty). Without
      # this, "select a word and press the shortcut" works only in some apps.
      synthesize_copy() {
        # saved_type is deliberately not local: restore_clipboard reads it
        # from the trap, which can fire after this function has returned.
        local focused sentinel current attempt

        command -v hyprctl >/dev/null 2>&1 || { log "synthesize: no hyprctl"; return 1; }
        command -v wtype >/dev/null 2>&1 || { log "synthesize: no wtype"; return 1; }

        focused=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')
        [ -n "$focused" ] || { log "synthesize: no focused window"; return 1; }
        case $focused in
          ${lib.concatStringsSep " | " cfg.selection.skipClasses})
            log "synthesize: skipped, $focused is in skipClasses"
            return 1
            ;;
        esac

        # text/plain is preferred over whatever --list-types happens to list
        # first. That order is not a preference order: text copied out of a
        # browser advertises text/html ahead of text/plain, so taking the
        # first type turned a plain-text clipboard into "<meta http-equiv=..."
        # on restore.
        saved_type=$(wl-paste --list-types 2>/dev/null | grep -m1 -Fx 'text/plain' || true)
        if [ -z "$saved_type" ]; then
          saved_type=$(wl-paste --list-types 2>/dev/null | head -n 1)
        fi
        if [ -n "$saved_type" ]; then
          wl-paste --type "$saved_type" >"$saved_clipboard" 2>/dev/null || : >"$saved_clipboard"
        else
          : >"$saved_clipboard"
        fi

        # With no selection the copy keystroke is a no-op and the clipboard
        # simply does not change — indistinguishable from a successful copy of
        # whatever was already there. Parking a random string first makes
        # "nothing happened" detectable, so a stale clipboard is never shown
        # as if it were a selection.
        sentinel="dict-popup-$$-$RANDOM-$RANDOM"
        clipboard_pending=1
        wl-copy -- "$sentinel" >/dev/null 2>&1

        # Retried, because the shortcut is a chord: when this runs SUPER and
        # CTRL are usually still held, so the app receives Super+Ctrl+C and
        # copies nothing. Retrying beats adding a fixed delay to every lookup.
        word=""
        attempt=0
        while [ "$attempt" -lt "$copy_attempts" ]; do
          attempt=$((attempt + 1))
          wtype -M ctrl -k c -m ctrl >/dev/null 2>&1 || true
          for _ in 1 2 3 4 5 6; do
            sleep 0.03
            current=$(read_clipboard)
            if [ "$current" != "$sentinel" ]; then
              word=$current
              break 2
            fi
          done
        done
        log "synthesize: focused=$focused attempts=$attempt got=''${#word}chars"

        restore_clipboard

        has_content "$word"
      }

      # Closed FIRST, before the selection is read — not last, as a tidy-up.
      # The popup holds exclusive keyboard focus, so while one is still open:
      #   - a synthesized Ctrl+C lands on the popup rather than on the window
      #     holding the selection, and copies nothing; and
      #   - hyprctl reports the window that had focus *before* the popup as
      #     active, so the skipClasses check tests the wrong window — which is
      #     how looking a word up in a browser got skipped for "Alacritty".
      # Symptom was precise: the first lookup worked and every one after it
      # showed a stale clipboard.
      close_previous() {
        local old
        [ -f "$pidfile" ] || return 0
        old=$(cat "$pidfile" 2>/dev/null || true)
        [ -n "$old" ] || return 0
        [ -r "/proc/$old/environ" ] || return 0
        # Identified by an environment marker, not by its command line.
        # Guards against PID reuse ($XDG_RUNTIME_DIR outlives any one popup)
        # while working for both backends: alacritty carries "--class
        # dict-popup" in argv, but the Quickshell one is `qs -p
        # /nix/store/<hash>-popup.qml` and contains the class nowhere — so a
        # cmdline match silently never fired and popups stacked up.
        tr '\0' '\n' <"/proc/$old/environ" | grep -qxF "DICT_POPUP_MARKER=$class" || return 0

        kill "$old" 2>/dev/null || true
        # Waited for, because focus only comes back once it is really gone.
        for _ in $(seq 1 50); do
          [ -d "/proc/$old" ] || break
          sleep 0.02
        done
        # And then a beat for the compositor to hand keyboard focus back.
        sleep 0.05
        log "closed previous popup $old"
      }

      close_previous

      # Where the word comes from, best first:
      #   1. PRIMARY          the selection, free and with no side effects
      #   2. synthesized copy the selection, for apps that do not publish it
      #   3. clipboard        nothing selected anywhere, so show what was
      #                       copied — labelled, because it is the one case
      #                       where the popup can show an unrelated word
      source=selection
      word=$(read_primary)
      log "primary: ''${#word}chars"
      if ! has_content "$word"; then
        ${lib.optionalString cfg.selection.synthesizeCopy "synthesize_copy || true"}
        if ! has_content "$word"; then
          source=clipboard
          word=$(read_clipboard)
          log "fell back to clipboard: ''${#word}chars"
        fi
      fi
      log "source=$source word=''${#word}chars"

      note=""
      if [ "$source" = clipboard ] && has_content "$word"; then
        note="From the clipboard — nothing was selected."
      fi

      # One popup at a time is handled by close_previous above, via a pidfile
      # rather than the compositor: `hyprctl dispatch closewindow class:...`
      # is a pre-0.55 spelling that fails under a Lua config, where hyprctl
      # wraps whatever it is given in hl.dispatch(...) and cannot then parse
      # it as Lua. A pidfile needs no compositor API at all.
    ''
    + lib.optionalString (cfg.popup.backend == "quickshell") ''

      # Declared here rather than beside the other state paths because only
      # this backend writes them, and shellcheck fails the build over a
      # variable the terminal backend would never read.
      payload=$state/popup.json
      themeMerged=$state/theme.json

      # Appearance, layered: the module's defaults and the repo's `theme`
      # option are already folded together in themeFile; the hand-edited live
      # file is merged over them here, every run, so a colour or a radius can
      # be changed without a rebuild. jq's `*` is a recursive merge, so the
      # live file only has to carry the keys it wants to change.
      #
      # Invalid JSON there falls back to the defaults with a note in the log,
      # rather than leaving the popup unstyled or not opening at all.
      theme=$(cat ${themeFile})
      live=''${XDG_CONFIG_HOME:-$HOME/.config}/dict-popup/theme.json
      if [ -r "$live" ]; then
        if merged=$(jq -s '.[0] * .[1]' ${themeFile} "$live" 2>/dev/null) && [ -n "$merged" ]; then
          theme=$merged
        else
          log "theme: $live is not valid JSON, using defaults"
        fi
      fi
      printf '%s' "$theme" >"$themeMerged"

      IFS=$'\t' read -r width height offset_y shadow_pad < <(
        printf '%s' "$theme" | jq -r '[.width, .height, .offsetY, (.shadowPad // 0)] | @tsv'
      )
      : "''${width:=520}" "''${height:=620}" "''${offset_y:=24}" "''${shadow_pad:=0}"

      # Geometry is computed here rather than in QML because a layer surface
      # is placed by anchoring it to an edge and pushing it in with margins,
      # and those margins are measured from the *usable* area — inside
      # whatever the bar reserved. Logical sizes, hence the division by scale:
      # hyprctl reports width/height in physical pixels but positions
      # everything in logical ones.
      #
      # `|| :` on both, because `read` returns non-zero at EOF and errexit
      # would then abort the script here — *after* close_previous has already
      # killed the old popup, so the shortcut would close the popup and open
      # nothing. That also made the defaults below unreachable, which is the
      # misleading part: they read as a safety net but could never run. The
      # reads fail for real reasons — hyprctl missing from a TTY, no
      # HYPRLAND_INSTANCE_SIGNATURE under a systemd unit, a hotplug mid-query.
      IFS=$'\t' read -r mon_name mon_x mon_y usable_w usable_h res_l res_t < <(
        hyprctl monitors -j 2>/dev/null | jq -r '
          .[] | select(.focused) | [
            .name, .x, .y,
            ((.width / .scale) | floor) - .reserved[0] - .reserved[2],
            ((.height / .scale) | floor) - .reserved[1] - .reserved[3],
            .reserved[0], .reserved[1]
          ] | @tsv'
      ) || :
      IFS=' ' read -r cx cy < <(hyprctl cursorpos 2>/dev/null | tr -d ',') || :
      [ -n "$mon_name" ] || log "geometry: no monitor from hyprctl, placing at top-left"

      : "''${mon_name:=}" "''${cx:=0}" "''${cy:=0}"
      : "''${usable_w:=$width}" "''${usable_h:=$height}"
      : "''${mon_x:=0}" "''${mon_y:=0}" "''${res_l:=0}" "''${res_t:=0}"

      # The surface is the card plus shadowPad on every side: a layer surface
      # clips to its own bounds, so a shadow drawn at the card's edge has
      # nowhere to fall unless that room exists. The card is inset by the same
      # amount inside QML, which is why the margins below subtract it — the
      # *card*, not the surface, is what should sit under the cursor.
      surface_w=$(( width + shadow_pad * 2 ))
      surface_h=$(( height + shadow_pad * 2 ))

      # Centred on the cursor horizontally, below it vertically, then clamped
      # so a word selected at an edge still gets a fully visible popup.
      ml=$(( cx - mon_x - res_l - width / 2 - shadow_pad ))
      mt=$(( cy - mon_y - res_t + offset_y - shadow_pad ))
      max_ml=$(( usable_w - surface_w ))
      max_mt=$(( usable_h - surface_h ))
      [ "$max_ml" -lt 0 ] && max_ml=0
      [ "$max_mt" -lt 0 ] && max_mt=0
      [ "$ml" -lt 0 ] && ml=0
      [ "$mt" -lt 0 ] && mt=0
      [ "$ml" -gt "$max_ml" ] && ml=$max_ml
      [ "$mt" -gt "$max_mt" ] && mt=$max_mt
      log "popup: screen=$mon_name cursor=$cx,$cy margins=$ml,$mt card=''${width}x''${height}"

      # --sections, not --html: the popup wants one fragment per dictionary so
      # each can be held to a line budget and expanded on its own, which is
      # what macOS does. A single document cannot be truncated per dictionary.
      if has_content "$word"; then
        dict-lookup --sections --theme "$themeMerged" --note "$note" -- "$word" >"$rendered" 2>/dev/null || true
      else
        dict-lookup --sections --theme "$themeMerged" --note "Nothing to look up. Select a word and press the shortcut again." -- "" >"$rendered" 2>/dev/null || true
      fi
      # An empty or unparseable render would otherwise take the popup down
      # with it; an empty section list at least opens and says nothing found.
      if ! jq -e . "$rendered" >/dev/null 2>&1; then
        log "render produced no valid JSON; showing an empty popup"
        printf '%s' '{"sections":[],"style":"","note":"lookup failed"}' >"$rendered"
      fi

      # --slurpfile rather than --arg so a 30-40 KB document never goes near
      # argv. Colours are rotated from the #RRGGBBAA written in the theme to
      # the #AARRGGBB Qt actually parses; doing it here rather than in Nix is
      # what lets the live file carry colours too.
      printf '%s' "$theme" | jq \
        --slurpfile doc "$rendered" \
        --arg screen "$mon_name" \
        --arg namespace "$class" \
        --argjson marginLeft "$ml" \
        --argjson marginTop "$mt" \
        --argjson surfaceWidth "$surface_w" \
        --argjson surfaceHeight "$surface_h" \
        '
        def qt:
          if type == "string" and test("^#[0-9a-fA-F]{8}$")
          then "#" + .[7:9] + .[1:7]
          else . end;
        ($doc[0] // {}) as $d
        | {
          sections: ($d.sections // []),
          style: ($d.style // ""),
          note: ($d.note // ""),
          rule: ($d.rule // "#4A4A4A"),
          accent: ($d.accent // "#4DA3FF"),
          section: .section,
          sectionPx: ($d.sectionPx // 18),
          labelFont: ($d.labelFont // ""),
          maxLines: (.maxLines // 0),
          # QML needs these two to turn maxLines into the pixel budget it can
          # actually clip to.
          fontPx: .fontPx,
          lineHeightPct: (.lineHeightPct // 140),
          screen: $screen,
          namespace: $namespace,
          marginLeft: $marginLeft,
          marginTop: $marginTop,
          surfaceWidth: $surfaceWidth,
          surfaceHeight: $surfaceHeight,
          width: .width,
          height: .height,
          radius: .radius,
          padding: .padding,
          borderWidth: .borderWidth,
          shadowPad: (.shadowPad // 0),
          background: (.background | qt),
          border: (.border | qt),
          foreground: (.foreground | qt),
          fontFamily: .fontFamily,
          shadowEnabled: (.shadowEnabled // false),
          shadowColor: (.shadowColor | qt),
          shadowBlur: (.shadowBlur // 0),
          shadowOffsetY: (.shadowOffsetY // 0),
          shadowSpread: (.shadowSpread // 0),
          shadowOpacity: (.shadowOpacity // 1)
        }' >"$payload"

      printf '%s\n' "$$" >"$pidfile"
      # The guard has done its job once the pidfile exists: from here on
      # close_previous can find this popup, so the next lookup must be free to
      # replace it rather than be turned away.
      cleanup
      DICT_POPUP_MARKER="$class" DICT_POPUP_FILE="$payload" exec qs -p ${./popup.qml}
    ''
    + lib.optionalString (cfg.popup.backend == "terminal") ''

      if has_content "$word"; then
        lookup=$(dict-lookup --note "$note" -- "$word" 2>&1 || true)
      else
        lookup=$(printf 'Nothing to look up.\n\nSelect a word and press the shortcut again.\n')
      fi

      # % and ? are metacharacters in a less prompt string, and the title goes
      # straight into one. Taken from the lookup so it shows the spelling that
      # actually matched — "Discoveries," is titled "discovery".
      title=$(printf '%s\n' "$lookup" | grep -v '^From the clipboard' | head -n 1 | tr -d '%?')
      printf '%s\n' "$lookup" >"$rendered"

      args=(
        --class "$class"
        --title "Look Up: $title"
        -o "font.size=${toString theme.fontPx}"
        -o 'window.padding.x=14'
        -o 'window.padding.y=10'
      )
      ${lib.optionalString cfg.popup.closeOnEscape ''
        # Escape closes the popup, by having the terminal send the "q" the
        # pager already quits on. Deliberately not a lesskey binding for ESC:
        # in less a bare ESC binding competes with the escape sequences the
        # arrow keys arrive as, so it would cost scrolling to buy closing.
        args+=(-o 'keyboard.bindings=[{key="Escape",chars="q"}]')
      ''}

      printf '%s\n' "$$" >"$pidfile"
      # See the quickshell branch: the guard is cleared at the handoff, not
      # held for the popup's lifetime.
      cleanup
      DICT_POPUP_MARKER="$class" exec ${cfg.popup.terminal} "''${args[@]}" -e ${pager} "$rendered" "$title"
    '';
  };

  # Converts macOS .dictionary bundles to StarDict. The procedure is declared
  # here; the result is not, and cannot be — Nix cannot fetch a bundle that
  # only exists on a licensed Mac, so the output lands in stardict.dataDir and
  # a reinstall needs the Mac again.
  dict-import-macos = pkgs.writeShellApplication {
    name = "dict-import-macos";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.openssh
      pkgs.gnutar
      pkgs.dict # dictzip
    ];

    text = ''
      host=''${1:-}
      target=''${2:-${cfg.stardict.dataDir}}

      if [ -z "$host" ]; then
        cat >&2 <<'EOF'
      usage: dict-import-macos user@host [target-dir]

      Copies the macOS dictionaries over ssh and converts them to StarDict.
      Needs Remote Login enabled on the Mac and key-based ssh (no prompts).

      Default target is the dictionary module's stardict.dataDir.
      EOF
        exit 2
      fi

      stage=$(mktemp -d)
      # shellcheck disable=SC2064
      trap "rm -rf '$stage'" EXIT

      ssh_opts=(-o BatchMode=yes -o ConnectTimeout=12)

      # Checked once, up front: without this every dictionary is reported as
      # missing when in fact the Mac has simply dropped off the network, which
      # sends you looking in the wrong place.
      if ! ssh "''${ssh_opts[@]}" "$host" true 2>/dev/null; then
        echo "cannot reach $host over ssh — is the Mac awake, on the network, and is Remote Login on?" >&2
        exit 1
      fi
      echo "connected to $host (macOS $(ssh "''${ssh_opts[@]}" "$host" sw_vers -productVersion 2>/dev/null))"

      import_one() {
        local name=$1 slug=$2 path bundle
        echo "=== $name -> $slug ==="

        # Found by name, not path: the bundles live under
        # /System/Library/AssetsV2/com_apple_MobileAsset_DictionaryServices_*/<hash>.asset/
        # and that hash changes with every macOS update.
        #
        # $name expands here so the Mac receives a literal dictionary name;
        # the globs are meant for the remote shell. SC2029 cannot tell those
        # apart from an accident.
        # shellcheck disable=SC2029
        path=$(ssh "''${ssh_opts[@]}" "$host" \
          "ls -d /System/Library/AssetsV2/com_apple_MobileAsset_DictionaryServices_dictionary*/*/AssetData/'$name'.dictionary 2>/dev/null | head -1")
        if [ -z "$path" ]; then
          echo "  not present on this Mac (it is reachable, so this one really is absent)"
          return 0
        fi

        # Localisations are UI strings only; excluding them halves the copy.
        rm -rf "''${stage:?}/''${slug:?}"
        mkdir -p "$stage/$slug" "$stage/out-$slug"
        # $path and $name are meant to expand here, locally, while $(dirname)
        # has to run on the Mac — which is exactly the mix SC2029 warns about
        # when it is accidental.
        # shellcheck disable=SC2029
        ssh "''${ssh_opts[@]}" "$host" \
          "cd \"\$(dirname '$path')\" && tar cf - --exclude='*.lproj' '$name.dictionary'" \
          | tar xf - -C "$stage/$slug"
        bundle="$stage/$slug/$name.dictionary"
        echo "  copied $(du -sh "$bundle" | cut -f1)"

        # biplist is what pyglossary's Apple reader needs to parse the binary
        # Info.plist. It is in nixpkgs but not among pyglossary's own
        # dependencies, so it is added to the path here rather than by
        # overriding the package.
        if ! PYTHONPATH=${pkgs.python3Packages.biplist}/${pkgs.python3.sitePackages} \
            ${pkgs.pyglossary}/bin/pyglossary --ui=cmd \
            --read-format=AppleDictBin --write-format=Stardict \
            "$bundle" "$stage/out-$slug/$slug.ifo" >"$stage/$slug.log" 2>&1; then
          echo "  convert failed; tail of log:"
          tail -5 "$stage/$slug.log" | sed 's/^/    /'
          return 1
        fi
        echo "  converted $(du -sh "$stage/out-$slug" | cut -f1) of HTML"

        # dictzip: the HTML bodies decompress to hundreds of megabytes (NOAD
        # alone is 221 MB) and sdcv reads .dict.dz transparently.
        [ -f "$stage/out-$slug/$slug.dict" ] && dictzip "$stage/out-$slug/$slug.dict"

        # Each dictionary in its own directory: they all ship a res/style.css
        # and would otherwise collide. sdcv searches subdirectories.
        # :? so a mistyped target can never make this an `rm -rf /`.
        rm -rf "''${target:?}/''${slug:?}"
        mkdir -p "$target/$slug"
        mv "$stage/out-$slug"/* "$target/$slug"/
        echo "  installed $(du -sh "$target/$slug" | cut -f1) -> $target/$slug"
      }

      mkdir -p "$target"
      ${lib.concatMapStringsSep "\n      " (
        d: "import_one ${lib.escapeShellArg d.name} ${lib.escapeShellArg d.slug}"
      ) cfg.macosDictionaries}

      echo
      echo "=== installed ==="
      du -sh "$target"/*/ 2>/dev/null || true
      echo
      echo 'Check with: dict-lookup --list'
    '';
  };
in
{
  options.custom.dictionary = {
    enable = lib.mkEnableOption "the dictionary Look Up popup" // {
      default = true;
    };

    order = lib.mkOption {
      type = lib.types.listOf (
        lib.types.enum [
          "stardict"
          "wordnet"
          "dictd"
        ]
      );
      default = [
        "stardict"
        "wordnet"
        "dictd"
      ];
      description = ''
        Which backends to query. Omitting one skips it entirely. Within a
        backend the appearance order comes from `dictionaryOrder`.
      '';
    };

    dictionaryOrder = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "New Oxford American"
        "Thesaurus"
        "Từ Điển Tiếng Việt"
        "Lạc Việt"
        "Anh Việt"
        "WordNet"
        "wiktionary"
      ];
      description = ''
        Substrings matched against each dictionary's own name, in the order
        they should appear — the equivalent of Dictionary.app's "Drag
        reference sources into the order you prefer".

        `order` alone cannot express this: the converted macOS dictionaries and
        the Vietnamese ones are all the same backend (stardict) and still want
        a defined order. Anything unmatched sorts last, keeping its relative
        order. The default mirrors Dictionary.app's own list.
      '';
    };

    sectionLabels = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {
        "New Oxford American" = "English";
        "Thesaurus" = "English Thesaurus";
        "Lạc Việt" = "Vietnamese - English";
        "Từ Điển Tiếng Việt" = "Vietnamese";
        "Anh Việt" = "English - Vietnamese";
        "wiktionary" = "Wiktionary";
      };
      description = ''
        Substring of a dictionary's own name → the heading to show for it.
        Longest match wins, so a specific pattern can sit beside a general
        one; anything unmatched keeps its real name (WordNet, by default).

        Dictionary.app does not head a section with the dictionary's title —
        it shows the language or the role: "English", "English Thesaurus",
        "Vietnamese - English". This was printing "New Oxford American
        Dictionary (en-en)", which is the most obvious difference from the
        real thing once the layout matches.

        Applied after `dictionaryOrder`, so ordering still keys off the real
        names.
      '';
    };

    pronunciation = lib.mkOption {
      type = lib.types.enum [
        "respell"
        "ipa"
      ];
      default = "respell";
      description = ''
        Which pronunciation to keep from the macOS dictionaries, which ship
        both: `respell` is the US diacritical form (ˌapləˈkāSHən) and `ipa` the
        IPA (ˌæpləˈkeɪʃən). Dictionary.app shows one, per its own
        "Pronunciation" setting; showing both renders them concatenated.
      '';
    };

    maxEntriesPerDatabase = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2;
      description = ''
        How many entries to show per dictionary for one word. Dictionaries
        carry homographs as separate entries, and more than a couple buries
        the common sense.
      '';
    };

    dictdDatabases = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ pkgs.dictdDBs.wiktionary ];
      defaultText = lib.literalExpression "[ pkgs.dictdDBs.wiktionary ]";
      example = lib.literalExpression "with pkgs.dictdDBs; [ wiktionary eng2fra ]";
      description = ''
        Packages providing dictd-format dictionaries, each as
        `share/dictd/<name>.index` beside a `<name>.dict` or `<name>.dict.dz`.
        Read directly, with no dictd daemon.

        Set to `[ ]` to drop them: `dictdDBs.wiktionary` alone is 497 MB.

        `dictdDBs.wordnet` is deliberately not here. If you want WordNet,
        `wordnet.enable` is the way to get it — `wn` does morphology and
        `wordnet.index` has no entry for "ran" or "discoveries". Both are
        off by default; see `wordnet.enable` for why.
      '';
    };

    macosDictionaries = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Bundle name on the Mac, without `.dictionary`.";
            };
            slug = lib.mkOption {
              type = lib.types.str;
              description = "Directory name to install it under.";
            };
          };
        }
      );
      default = [
        {
          name = "New Oxford American Dictionary";
          slug = "oxford-american";
        }
        {
          name = "Oxford American Writer's Thesaurus";
          slug = "oxford-thesaurus";
        }
        {
          name = "Vietnamese - English";
          slug = "lacviet-vi-en";
        }
        {
          name = "Vietnamese";
          slug = "tu-dien-tieng-viet";
        }
      ];
      description = ''
        Which macOS dictionaries `dict-import-macos` converts. Absent ones are
        skipped with a note rather than treated as an error.

        "Apple Dictionary" is omitted on purpose: it documents Apple's own
        terminology and is 42 MB of little use for looking up English.
      '';
    };

    wordnet = {
      # Off, and the reason it was ever on no longer holds. WordNet was never
      # here for its definitions — it is the only backend that does
      # morphology, and its lemmas were reused to rescue the exact-match
      # backends ("discoveries" -> "discovery"). That mattered while FVDP
      # Anh-Việt, a bare StarDict dictionary with no `.syn`, was the only
      # Vietnamese source. The macOS dictionaries index their own inflections
      # in `.syn` (`mice`, `children`, `teeth`, `women`, `swum` are all
      # there), so dropping FVDP quietly made the rescue redundant: with the
      # section off, output is byte-identical with and without `wn` across 16
      # inflected words, every irregular included.
      #
      # What is left is a synset dump under NOAD's typography, English-only,
      # duplicating a better source, for 108 MiB of closure. Set this true to
      # get it back — it is also the only English dictionary this repo can
      # build unaided, since the macOS four need the Mac again after a
      # reinstall.
      enable = lib.mkEnableOption "WordNet lookups through its own `wn` binary";

      maxSenses = lib.mkOption {
        type = lib.types.ints.positive;
        default = 6;
        description = ''
          Senses to show per part of speech. WordNet lists 41 for "run".
        '';
      };
    };

    stardict = {
      enable = lib.mkEnableOption "StarDict lookups through sdcv" // {
        default = true;
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ''
          Packages providing StarDict dictionaries under
          `share/stardict/dic` — see ./stardict-dictionaries.nix, which
          defines `anh-viet` (English → Vietnamese, 5.4 MB) and `viet-anh`
          (1.0 MB).

          Empty, though `anh-viet` was the default at first: nixpkgs has no
          Vietnamese dictionary of any kind, so FVDP fetched by hash was the
          only option until the macOS ones could be converted. Từ điển Lạc
          Việt then superseded it on every axis — 280,474 headwords against
          103,872, answering English *and* Vietnamese headwords rather than
          only English, and without FVDP's missing diacritics ("quâng" for
          "quãng") — leaving it a redundant section on every English lookup.

          It is still the only Vietnamese dictionary this repo can build
          unaided, since the converted four need the Mac again after a
          reinstall. To bring it back, put `stardictDictionaries.anh-viet`
          here as the default again; `dictionaryOrder` and `sectionLabels`
          still carry its entries, which are inert while it is absent.
        '';
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "${config.xdg.dataHome}/stardict/dic";
        defaultText = lib.literalExpression ''"''${config.xdg.dataHome}/stardict/dic"'';
        description = ''
          Directory holding StarDict dictionaries not managed by Nix, one
          subdirectory each. Skipped silently while it does not exist.

          This is where `dict-import-macos` installs the converted macOS
          dictionaries. Nothing in the repo manages its contents, and that is
          unavoidable: Nix cannot fetch a bundle that only exists on a
          licensed Mac, so a reinstall needs the Mac again.
        '';
      };
    };

    selection = {
      synthesizeCopy =
        lib.mkEnableOption "asking the focused window to copy its selection when PRIMARY is empty"
        // {
          default = true;
        };

      copyAttempts = lib.mkOption {
        type = lib.types.ints.positive;
        default = 4;
        description = ''
          How many times to send the copy keystroke before giving up, ~200ms
          apart. More than one is needed because the shortcut is a chord:
          SUPER and CTRL are still held when the script runs, so the app sees
          Super+Ctrl+C and copies nothing.
        '';
      };

      skipClasses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          # Terminals: Ctrl+C is SIGINT.
          "Alacritty"
          "foot"
          "kitty"
          "konsole"
          "org.wezfurlong.wezterm"
          "com.mitchellh.ghostty"
          "xterm"
          "st"
          # Remote desktops: the keystroke is forwarded to another machine.
          "Horizon-client"
          "org.remmina.Remmina"
          "*freerdp"
          "vncviewer"
          "TigerVNC*"
        ];
        description = ''
          Window classes never sent the synthetic copy keystroke, matched as
          shell glob patterns against the focused window's class.

          Two kinds are listed, for two different reasons.

          **Terminals**, because Ctrl+C there is SIGINT: synthesizing it would
          kill whatever is running instead of copying. Nothing is lost, since
          terminals publish PRIMARY reliably and so are caught by the first
          method anyway.

          **Remote desktop clients**, because the keystroke is forwarded to
          the remote machine, where what it does is anyone's guess — and the
          selection lives over there too, so the copy could not come back
          regardless. Learnt from a test that sent Ctrl+C into a live Horizon
          session.
        '';
      };
    };

    popup = {
      backend = lib.mkOption {
        type = lib.types.enum [
          "quickshell"
          "terminal"
        ];
        default = "quickshell";
        description = ''
          How the definition is shown.

          `quickshell` is the macOS-style popup: a layer-shell surface with
          proportional type, blur and rounded corners, rendering the HTML that
          render.py produces. Apple's own markup survives the conversion from
          `.dictionary`, class names and all, which is what lets it look like
          the real thing. Costs ~175ms to appear, measured.

          `terminal` shows the plain-text rendering in a floating terminal
          with `less`. Kept because it needs nothing but a terminal, so it
          still works if the popup breaks.
        '';
      };

      class = lib.mkOption {
        type = lib.types.str;
        default = "dict-popup";
        description = ''
          Layer-shell namespace (quickshell backend) and window class
          (terminal backend). The window and layer rules match on it, so it
          must stay unique.
        '';
      };

      terminal = lib.mkOption {
        type = lib.types.str;
        default = lib.getExe pkgs.alacritty;
        defaultText = lib.literalExpression "lib.getExe pkgs.alacritty";
        description = ''
          Terminal for the `terminal` backend. Must accept alacritty's
          `--class`, `--title`, `-o` and `-e` flags.
        '';
      };

      closeOnEscape = lib.mkEnableOption "closing the popup with Escape as well as q" // {
        default = true;
      };

      blurIgnoreAlpha = lib.mkOption {
        type = lib.types.numbers.between 0.0 1.0;
        default = 0.7;
        description = ''
          Alpha below which Hyprland does **not** blur the backdrop behind
          the popup. It has to sit between the shadow's alpha and the card's,
          and getting it wrong is the "two layers" effect:

          Too low (it was 0.1) and Hyprland blurs the whole surface — the
          shadow pad included. The blurred backdrop there is lighter and
          flatter than the wallpaper around it, so a second rounded rectangle
          appears about `shadowPad` outside the card. It looks like a frame
          and is really just blur bleeding past the card.

          Too high and the card itself stops being blurred.

          So: above `theme.shadowColor`'s alpha, at or below
          `theme.background`'s. The defaults are 0xA0 (0.63) and 0xd0 (0.82),
          and 0.7 sits between them.

          A `layer_rule`, so unlike the rest of the appearance this one needs
          `hms` **and** `hyprctl reload`. If you lower `background`'s alpha in
          theme.json below this value, lower this too or the blur stops.
        '';
      };
    };

    theme = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = lib.literalExpression ''
        {
          radius = 12;
          borderWidth = 2;
          shadowBlur = 48;
          accent = "#7AA2F7FF";
        }
      '';
      description = ''
        Appearance, as a set of overrides on `themeDefaults` in this module —
        only the keys given are replaced, so setting one does not reset the
        rest.

        Three layers, each overriding the one before:

        1. `themeDefaults` in this module.
        2. This option, for anything that should be declared in the repo.
        3. `~/.config/dict-popup/theme.json`, an out-of-store symlink to
           `home/nagih/dictionary/theme.json` — hand-edited and read on every
           lookup, so tweaking a colour or a radius takes effect on the next
           popup with **no rebuild**. Same idea as `hypr-vars.lua`.

        Layer 3 exists because appearance is the one thing worth iterating on
        quickly, and `hms` is far too slow a loop for "is that border too
        bright".

        Keys, all optional:

        | Key | Meaning |
        | --- | --- |
        | `width`, `height` | card size in logical pixels |
        | `radius`, `padding`, `borderWidth` | card geometry |
        | `background`, `border` | card fill and border, `#RRGGBBAA` |
        | `foreground`, `muted`, `faint`, `rule`, `accent`, `section` | text palette |
        | `fontPx`, `sectionFontPx`, `lineHeightPct`, `fontFamily`, `labelFontFamily` | type |
        | `shadowEnabled`, `shadowColor`, `shadowBlur`, `shadowOffsetY`, `shadowOpacity` | drop shadow |
        | `shadowPad` | transparent room left around the card for the shadow to fall into |
        | `offsetY` | gap between the mouse and the card |
        | `margin` | smallest gap from the edge of the screen |

        Colours are `#RRGGBBAA` throughout — CSS order. Qt parses an 8-digit
        hex as `#AARRGGBB`, alpha *first*, so they are rotated on the way out;
        writing them the Qt way here would be a trap, since getting it wrong
        is silent (an 11%-opaque blue tint rather than an error).

        Not here, because neither is the popup's to draw: the background blur
        is a Hyprland `layer_rule` and so needs `hms` and a `hyprctl reload`,
        and `popup.backend = "terminal"` ignores all of this except the
        geometry.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      dict-lookup
      dict-popup
      dict-import-macos
    ];

    # Out-of-store symlink, so the live file *is* the repo file: edit it and
    # the next popup picks the change up, with no switch. Valid here for the
    # reason architecture.md gives for hypr-vars.lua — it is pure user input
    # and nothing ever writes back to it.
    xdg.configFile."dict-popup/theme.json" = lib.mkIf (cfg.popup.backend == "quickshell") {
      source = config.lib.file.mkOutOfStoreSymlink "${hostVars.nixConfig}/home/nagih/dictionary/theme.json";
    };

    # The quickshell popup is a layer surface, not a window, so its blur comes
    # from a layer_rule. Without this the translucent background is not
    # blurred but simply see-through, and the text of whatever is behind reads
    # straight through the definition — verified by screenshotting it both
    # ways.
    wayland.windowManager.hyprland.settings.layer_rule =
      lib.optionals (cfg.popup.backend == "quickshell")
        [
          {
            match.namespace = "^(${cfg.popup.class})$";
            blur = true;
          }
          {
            match.namespace = "^(${cfg.popup.class})$";
            ignore_alpha = cfg.popup.blurIgnoreAlpha;
          }
        ];

    # Only the terminal backend produces a window to place. Floating is a
    # precondition, not a preference: the position expression is read only by
    # the floating layout, and only on a window's first map.
    #
    # Hyprland 0.55 geometry: `size` and `move` are muParser expressions, not
    # keywords. Three traps, all verified against the 0.55.2 source:
    #  1. parseExpressionVec2 splits x from y on the FIRST whitespace, so
    #     neither half may contain a space — "cursor_x-260", and min(a,b) with
    #     nothing after the comma.
    #  2. window_w/window_h do NOT reflect the `size` rule.
    #     DefaultFloatingAlgorithm.cpp computes `size` first and comments
    #     "update for pos to work with size", then writes the result into
    #     m_realPosition rather than m_realSize — so at `move` time those
    #     variables still hold the client's requested size. Hence literals.
    #  3. `move onscreen cursor -50% -50%` is gone: "onscreen" appears nowhere
    #     in 0.55.2. Staying on screen is the config's job, which is what the
    #     min/max clamp does.
    wayland.windowManager.hyprland.settings.window_rule =
      lib.optionals (cfg.popup.backend == "terminal")
        (
          let
            inherit (theme)
              width
              height
              margin
              offsetY
              ;
            x = "min(max(cursor_x-${toString (width / 2)},${toString margin}),monitor_w-${toString (width + margin)})";
            y = "min(max(cursor_y+${toString offsetY},${toString margin}),monitor_h-${toString (height + margin)})";
          in
          [
            {
              match.class = "^(${cfg.popup.class})$";
              float = true;
            }
            {
              match.class = "^(${cfg.popup.class})$";
              size = "${toString width} ${toString height}";
            }
            {
              match.class = "^(${cfg.popup.class})$";
              move = "${x} ${y}";
            }
          ]
        );
  };
}
