"""Command line for the dictionary: the same lookup, two renderers.

    dict-lookup WORD           plain text on stdout, for a terminal
    dict-lookup --html WORD    an HTML document, for the Quickshell popup
    dict-lookup --list         which dictionaries are actually loaded

Having one entry point for both means the popup can never disagree with what
`dict-lookup` prints when a definition looks wrong, which is the whole reason
the text renderer is worth keeping.
"""

from __future__ import annotations

import argparse
import json
import os
import sys

# Run under `python3 -I`, which isolates the interpreter — including dropping
# this script's own directory from sys.path, so the sibling modules have to be
# found explicitly. Worth keeping: -I is also what stops a stray lookup.py in
# whatever directory the popup happened to be launched from being imported
# instead of this one.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import lookup  # noqa: E402
import render  # noqa: E402


def list_dictionaries(cfg: lookup.Config) -> int:
    if cfg.wordnet:
        wn = lookup.run(["sh", "-c", "command -v wn"]).strip()
        print(f"wordnet   {wn or 'not on PATH'}")

    for root in cfg.dictd_roots:
        if not os.path.isdir(root):
            print(f"dictd     {root} (absent)")
            continue
        for name in sorted(os.listdir(root)):
            if name.endswith(".index"):
                print(f"dictd     {os.path.join(root, name)}")

    if cfg.stardict:
        for root in cfg.stardict_roots:
            if not os.path.isdir(root):
                print(f"stardict  {root} (absent — drop dictionaries there)")
                continue
            out = lookup.run(
                ["sdcv", "--list-dicts", "--data-dir", root, "--only-data-dir"]
            )
            for line in out.splitlines():
                # sdcv prints a header row before the dictionaries.
                if line.strip() and not line.startswith("Dictionary's name"):
                    print(f"stardict  {line.strip()}")
    return 0


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="dict-lookup",
        description="Look a word up in the configured offline dictionaries.",
    )
    ap.add_argument("--config", required=True, help="JSON config from the Nix module")
    ap.add_argument("--list", action="store_true", help="show loaded dictionaries")
    ap.add_argument("--html", action="store_true", help="render HTML, not text")
    ap.add_argument(
        "--sections",
        action="store_true",
        help="emit JSON with one HTML fragment per dictionary, for the popup",
    )
    ap.add_argument(
        "--theme",
        help="JSON theme file; its colour keys style the HTML (HTML only)",
    )
    ap.add_argument("--font-px", type=int, default=14, help="base font size (HTML only)")
    ap.add_argument(
        "--pronunciation",
        choices=["respell", "ipa"],
        default="respell",
        help="which pronunciation to keep from Apple dictionaries",
    )
    ap.add_argument("--note", default="", help="line shown above the result")
    ap.add_argument("words", nargs="*", help="word or phrase")
    args = ap.parse_args(argv)

    cfg = lookup.Config.load(args.config)

    # A broken theme must not stop a lookup: the colours fall back to
    # render.py's own, which is a cosmetic loss rather than a failure.
    theme: dict = {}
    if args.theme:
        try:
            with open(args.theme, encoding="utf-8") as fh:
                loaded = json.load(fh)
            if isinstance(loaded, dict):
                theme = loaded
        except (OSError, ValueError) as exc:
            print(f"dict-lookup: ignoring theme {args.theme}: {exc}", file=sys.stderr)

    # The theme wins over --font-px. Without this the flag's value — which is
    # baked in by the Nix wrapper — silently beat the live theme file, so
    # `fontPx` was the one size in theme.json that did nothing: the section
    # heading resized and the body text did not. Everything else derives from
    # the base size (the indent ladder is in em, the headword is 120% of it),
    # so this is the knob that matters most for "make it bigger".
    base_px = args.font_px
    if isinstance(theme.get("fontPx"), (int, float)) and theme["fontPx"] > 0:
        base_px = int(theme["fontPx"])

    if args.list:
        return list_dictionaries(cfg)

    if not args.words:
        ap.print_usage(sys.stderr)
        return 2

    word, entries = lookup.lookup(" ".join(args.words), cfg)

    if not word:
        # base_px here too: without it this one message rendered at the
        # argument default while every other line used the theme's size.
        if args.sections:
            json.dump(
                render.render_sections(
                    "", [], theme=theme, base_px=base_px, note="Nothing to look up."
                ),
                sys.stdout,
            )
        elif args.html:
            print(
                render.render_html(
                    "", [], theme=theme, base_px=base_px, note="Nothing to look up."
                )
            )
        else:
            print("Nothing to look up.")
        return 0

    if args.sections:
        json.dump(
            render.render_sections(
                word,
                entries,
                theme=theme,
                base_px=base_px,
                pronunciation=args.pronunciation,
                note=args.note,
            ),
            sys.stdout,
        )
    elif args.html:
        print(
            render.render_html(
                word,
                entries,
                theme=theme,
                base_px=base_px,
                pronunciation=args.pronunciation,
                note=args.note,
            )
        )
    else:
        sys.stdout.write(
            render.render_text(
                word, entries, note=args.note, pronunciation=args.pronunciation
            )
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
