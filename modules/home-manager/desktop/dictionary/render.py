"""Renderers over lookup.py: plain text for a terminal, HTML for the popup.

The HTML renderer targets Qt's rich text (QTextDocument), which understands a
subset of HTML 4 and CSS 2.1. Three things about that subset were established
by rendering candidates and looking at them, not from documentation:

  - <style> blocks with class selectors work. That is what makes styling
    Apple's own markup possible instead of rewriting it.
  - A negative `text-indent` on a block with a `margin-left` gives a real
    hanging indent — the sense number sits in a gutter and wrapped lines align
    under the text, which is how macOS lays a definition out. Tables also
    work but need their column widths guessing.
  - `display` is not reliable, so nothing is hidden with CSS; anything that
    should not appear is removed from the tree instead.

Dictionaries converted from macOS arrive as Apple's HTML with Apple's class
names, so the work is to prune it and then *promote* its senses into blocks:
Apple nests everything in inline <span>s, and inline content cannot carry the
margins the layout needs. Apple's own 45 KB stylesheet is not reused — most of
its selectors are outside Qt's subset — but its vocabulary is:

  hg/hwg     head group; .hw is the headword, carrying empty .hsb spans as
             syllable-break markers
  syl_txt    the headword already dot-separated ("ap·pli·ca·tion"), the form
             macOS shows, so .hw is dropped in its favour — but only where
             .syl_txt exists, which is not every dictionary
  ph         a pronunciation: .t_respell is the US diacritical respelling,
             .t_IPA the IPA. Dictionary.app shows one, so one is kept
  posg/pos   part of speech
  se2        a sense (NOAD, Thesaurus)
  semb       a sense (the bilingual dictionaries, a different Oxford schema)
  eg/exg     an example
  sn         sense number
  df         definition
  gp         "grammatical punctuation" — the glue commas, pipes and spaces
  d:*        Apple's namespaced elements, which carry no text
"""

from __future__ import annotations

import html
import re

from lookup import Entry

# Removed unconditionally. `hsb` marks a syllable boundary and is empty —
# Apple draws the interpunct with `span.hsb:before { content: '\2022' }`,
# which Qt's rich text has no equivalent for, so the dotted headword here
# comes from `syl_txt` instead (see _prune).
#
# The rest is what Apple's own stylesheet sets `display: none` on, under a
# "/* Hide */" banner: metadata that ships in the data and that Dictionary.app
# never shows. Hiding it here is not a style choice, it is matching macOS.
DROP_CLASSES = frozenset(
    {
        "hsb",
        "construction",
        "cdf",
        "domClass",
        "semClass",
        "encClass",
        "morphSet",
        "meta",
        "lbrk_txt",
    }
)

# Apple's layout vocabulary, and the reason this renderer keys off it.
#
# The semantic classes — se1, se2, msDict, semb, exg, trg, sg — carry *no
# layout at all* in Apple's stylesheet. `se1` and `sg` have no rule
# whatsoever; every box and every margin arrives through the `x_xd*`/`x_xo*`
# class sitting on the same element. Crucially both the monolingual and the
# bilingual dictionaries use the same ladder, so keying off these retires the
# per-dictionary special cases this used to need (se2 vs semb, gramb turning
# out to be a part-of-speech group rather than a sense, ps vs posg).
ALWAYS_BLOCK = ("x_xh0", "x_xd0", "x_xd1", "x_xo0", "x_xo1", "x_xo2", "x_xo3")

# Block only when numbered. Apple forces the container immediately after a
# sense number back to `display: inline` unless it carries a number of its
# own — that single rule is what keeps "1 a formal request to an authority"
# on one line instead of two, and it is the most load-bearing behaviour in
# the whole stylesheet.
BLOCK_IF_NUMBERED = ("x_xd1sub", "x_xd2", "x_xd2sub", "x_xd3", "x_xd4", "x_xd5", "x_xd6")

# margin-left, in em, exactly as Apple's stylesheet sets it per level.
# Cumulative: an x_xd1 inside an x_xd0 is indented by both.
INDENT_EM = {
    "x_xh0": 0.0,
    "x_xd0": 1.0,
    "x_xd1": 0.0,
    "x_xd1sub": 0.0,
    "x_xd2": 0.0,
    "x_xd2sub": 0.0,
    "x_xd3": 0.0,
    "x_xd4": 0.0,
    "x_xd5": 0.0,
    "x_xd6": 0.0,
    "x_xo0": 0.0,
    "x_xo1": 1.0,
    "x_xo2": 1.0,
    "x_xo3": 0.0,
}

# `.hasSn` adds this much, and the number then hangs back out by the same —
# Apple writes the hang as a negative margin on the inline number and sets
# `text-indent: 0em` explicitly. A Qt text block has no negative inline
# margin, but block margin-left plus negative text-indent is the exact
# equivalent, which is why that is what this emits.
NUMBERED_EXTRA_EM = 1.0
HANG_EM = 1.0

# `span.x_xd0 > span.x_xdh { margin-left: -0.8em }` — the part of speech
# hangs left of the senses it introduces, on its own line.
POS_OUTDENT_EM = 0.8

# Example groups, kept only so _prune can put a break before the Vietnamese
# synonym labels. Layout no longer keys off any semantic class — see the
# ALWAYS_BLOCK comment for why that mattered.
EXAMPLE_CLASSES = ("eg", "exg")


DEFAULT_COLORS = {
    "fg": "#ECECEC",
    "muted": "#A8A8A8",
    "faint": "#8A8A8A",
    "rule": "#4A4A4A",
    "accent": "#4DA3FF",
    "sec": "#BFBFBF",
}

# The theme file writes #RRGGBBAA, which is CSS order; Qt's rich text wants
# plain #RRGGBB for text colours and ignores an alpha it does not understand,
# so the alpha is trimmed rather than rotated here. (The *window* colours do
# get rotated, by the jq in dict-popup, because QML's color type reads an
# 8-digit hex as #AARRGGBB.)
THEME_TO_COLOR = {
    "foreground": "fg",
    "muted": "muted",
    "faint": "faint",
    "rule": "rule",
    "accent": "accent",
    "section": "sec",
}


def theme_colors(theme: dict | None = None) -> dict[str, str]:
    colors = dict(DEFAULT_COLORS)
    for key, name in THEME_TO_COLOR.items():
        value = (theme or {}).get(key)
        if isinstance(value, str) and value.startswith("#"):
            colors[name] = value[:7]
    return colors


def stylesheet(
    t: dict[str, str],
    base_px: int,
    section_px: int,
    line_pct: int,
    body_font: str,
    label_font: str,
) -> str:
    """Qt-compatible CSS: Apple's class vocabulary plus our block classes.

    The indentation ladder is the layout. A sense hangs its number in a
    gutter (margin-left minus text-indent) and an example sits further in
    again, which is what makes a long entry scannable rather than a wall.
    """
    # Horizontal position is NOT here: it is computed per block from Apple's
    # cumulative em ladder and emitted as an inline style, because the same
    # class appears at several depths. These rules carry only colour and the
    # vertical rhythm, whose em values are Apple's too (x_xd0 0.3em/2.0em,
    # x_xd1 0.3em/0.7em, x_xo0 0.5em).
    em = base_px
    # The vertical rhythm is Apple's *popover* rhythm, not its main window's.
    # The stylesheet carries 83 `html.apple_client-panel` rules for the Look Up
    # popover, and they are far tighter: x_xh0 margin-bottom 0.6em → 0.1em,
    # x_xd0 0.3/2.0em → 0.1/0.4em, x_xd1 0.3/0.7em → 0.1/0.3em, and the POS
    # line 0.5em → 0.1em. This popup *is* a popover, so those are the right
    # numbers; the main-window ones left it twice as airy as the reference.
    return f"""
      body       {{ color: {t['fg']}; font-size: {base_px}px;
                    line-height: {line_pct}%;
                    font-family: {body_font}; }}

      .sec       {{ color: {t['sec']}; font-size: {section_px}px;
                    font-family: {label_font}; }}
      .b-head    {{ margin-top: 0px; margin-bottom: {em * 0.1:.0f}px; }}
      .b-pos     {{ margin-top: {em * 0.1:.0f}px; margin-bottom: {em * 0.1:.0f}px; }}
      .b-sense   {{ margin-top: {em * 0.1:.0f}px; margin-bottom: {em * 0.3:.0f}px; }}
      .b-sub     {{ margin-top: {em * 0.1:.0f}px; margin-bottom: {em * 0.2:.0f}px; }}
      .b-ex      {{ margin-top: 0px; margin-bottom: 0px;
                    color: {t['muted']}; font-style: italic; }}
      .b-extra   {{ margin-top: {em * 0.3:.0f}px; margin-bottom: {em * 0.3:.0f}px;
                    color: {t['muted']}; }}

      /* 120% and weight 500, both Apple's popover values — not bold, and not
         the 158% of the main window. */
      .syl_txt   {{ font-size: {base_px * 1.2:.0f}px; font-weight: 500; }}
      .hwplain   {{ font-size: {base_px * 1.2:.0f}px; font-weight: 500; }}
      /* .hw survives only where there is no .syl_txt, and there it *is* the
         headword. */
      .hw        {{ font-size: {base_px * 1.2:.0f}px; font-weight: 500; }}
      /* Apple sets font-size 120% on span.pr inside the headword group, so
         the pronunciation is as large as the headword. Very visible in
         Dictionary.app, and missing here entirely until now. (Braces avoided
         in this comment on purpose: the stylesheet is an f-string, and a lone
         brace in a CSS comment is parsed as an expression.) */
      .ph        {{ color: {t['muted']}; font-weight: normal;
                    font-size: {base_px * 1.2:.0f}px; }}
      .prx       {{ color: {t['muted']}; font-size: {base_px * 1.2:.0f}px; }}
      .pr        {{ color: {t['muted']}; font-size: {base_px * 1.2:.0f}px; }}
      /* Upright, not italic: Apple sets only family/colour/weight on these.
         The italic here was invented. */
      .pos       {{ color: {t['muted']}; font-weight: 500; font-family: {label_font}; }}
      .posg      {{ color: {t['muted']}; font-weight: 500; font-family: {label_font}; }}
      .ps        {{ color: {t['muted']}; font-weight: 500; font-family: {label_font}; }}
      .sn        {{ color: {t['faint']}; font-weight: 600; font-family: {label_font}; }}
      .df        {{ color: {t['fg']}; }}
      .eg        {{ color: {t['muted']}; font-style: italic; }}
      .ex        {{ color: {t['muted']}; font-style: italic; }}
      .gp        {{ color: {t['faint']}; }}
      .syn       {{ color: {t['fg']}; }}
      .trans     {{ color: {t['fg']}; }}
      .lg        {{ color: {t['muted']}; font-style: italic; font-family: {label_font}; }}
      .fld       {{ color: {t['faint']}; font-style: italic; font-family: {label_font}; }}
      .ant       {{ color: {t['muted']}; }}
      .xr        {{ color: {t['accent']}; }}
      .vipos     {{ color: {t['muted']}; font-style: italic; }}
      .wnsyn     {{ font-weight: bold; }}
    """


def _inner_html(el) -> str:
    import lxml.html

    return (el.text or "") + "".join(
        lxml.html.tostring(child, encoding="unicode") for child in el
    )


def _by_class(el, names: tuple[str, ...]) -> list:
    """Descendants carrying any of these classes, in document order."""
    return el.xpath(
        " | ".join(
            f".//*[contains(concat(' ', @class, ' '), ' {c} ')]" for c in names
        )
    )


def _merge_inflection_groups(doc) -> None:
    """Run consecutive `.infg` groups together inside one pair of brackets.

    Apple brackets every inflection separately and scatters the punctuation
    through the markup rather than between the groups::

        (<span class=inf>runs</span>) (, <span class=inf>running</span> |..|)
        (<span class=sy>past</span>; <span class=inf>ran</span> |..|)

    Rendered literally that is the first line of every verb in the popup:

        run | rən | verb (runs) (, running | ˈrəniNG |) (past; ran | ran |)

    No dictionary prints "(, running", and the leading comma only makes sense
    if the inner ")" and "(" close up — so three things have to happen
    together, and doing only the first makes "break" *worse*, running its
    groups into each other with no separator at all:

      * keep the first "(" and the last ")" of a run, dropping the rest;
      * where Apple authored no separator, supply "; ", which is what it uses
        between the tenses elsewhere;
      * drop the ";" that trails a `.sy` label, since that label and its
        inflection are one phrase ("past ran", not "past; ran").

    Together they give Dictionary.app's line::

        run | rən | verb (runs, running | ˈrəniNG |; past ran | ran |;
        past participle run | rən |)

    Neither the dictionary's style.css nor fbm.css hides those brackets, so
    Dictionary.app does this from its own bundle stylesheet, which the
    conversion does not carry. lxml moves a dropped element's tail onto its
    previous sibling, so punctuation written outside the bracket spans — and
    the "; " set here — survives the drop.
    """

    def classes_of(el) -> set:
        return set((el.get("class") or "").split())

    def brackets(group, want: str) -> list:
        return [
            child
            for child in group
            if {"gp", "tg_infg"} <= classes_of(child)
            and (child.text or "").strip().startswith(want)
        ]

    for parent in list(doc.iter()):
        run: list = []
        for child in list(parent) + [None]:
            if child is not None and "infg" in classes_of(child):
                run.append(child)
                continue

            if len(run) > 1:
                for index, group in enumerate(run):
                    if index:
                        for bracket in brackets(group, "("):
                            # Only supply a separator where none was written.
                            if not (bracket.tail or "").strip(" "):
                                bracket.tail = "; "
                            bracket.drop_tree()
                    if index < len(run) - 1:
                        for bracket in brackets(group, ")"):
                            bracket.drop_tree()

                for group in run:
                    for label in group:
                        if "sy" in classes_of(label) and (label.tail or "").strip() in {
                            ";",
                            ",",
                        }:
                            label.tail = " "
            run = []


def _prune(doc, pronunciation: str) -> None:
    """Remove what Qt cannot use or what macOS itself hides."""
    for el in doc.xpath("//link | //script | //style"):
        parent = el.getparent()
        if parent is not None:
            parent.remove(el)

    for el in list(doc.iter()):
        tag = el.tag
        if isinstance(tag, str) and tag.lower().startswith("d:"):
            el.drop_tree()

    keep = "t_respell" if pronunciation == "respell" else "t_IPA"
    drop = "t_IPA" if pronunciation == "respell" else "t_respell"

    # .hw is only redundant where .syl_txt exists to replace it. NOAD ships
    # both and macOS shows the dotted one; the bilingual dictionaries ship
    # .hw alone, so dropping it unconditionally deleted Lạc Việt's headword
    # and the entry rendered as a bare pronunciation.
    has_syl = bool(doc.xpath("//*[contains(concat(' ', @class, ' '), ' syl_txt ')]"))

    for el in list(doc.iter()):
        classes = set((el.get("class") or "").split())
        if not classes:
            continue
        if classes & DROP_CLASSES:
            el.drop_tree()
        elif "hw" in classes and has_syl:
            el.drop_tree()
        elif "ph" in classes and drop in classes and keep != drop:
            el.drop_tree()

    _merge_inflection_groups(doc)

    # Synonym and antonym lists stay inline inside their sense, but the label
    # that introduces them ("từ đồng nghĩa", "từ trái nghĩa") follows the
    # previous word with no separator at all, so they render as
    # "providencetừ trái nghĩa". A break is the fix; promoting them to blocks
    # would mean recursing into the sense and rearranging content that is
    # otherwise correct.
    import lxml.html as _lh

    for el in _by_class(doc, ("synList", "antList")):
        el.addprevious(_lh.Element("br"))

    # A pronunciation group whose contents are gone — either dropped above, or
    # never there, as in Từ Điển Tiếng Việt — otherwise leaves its separators
    # behind and the headword renders as "khả năng |  |".
    for el in list(doc.iter()):
        classes = set((el.get("class") or "").split())
        if classes & {"prx", "pr"} and not (el.text_content() or "").strip(" | "):
            el.drop_tree()


def _contains_block(el) -> bool:
    """Does anything below `el` lay out as a block?

    Decides whether an unstyled wrapper is walked through or treated as
    inline content.
    """
    for node in el.iter():
        if node is el:
            continue
        classes = set((node.get("class") or "").split())
        layout = _layout_class(classes)
        if layout and (layout in ALWAYS_BLOCK or "hasSn" in classes):
            return True
    return False


def _layout_class(classes: set[str]) -> str | None:
    for name in ALWAYS_BLOCK + BLOCK_IF_NUMBERED:
        if name in classes:
            return name
    return None


def apple_blocks_v2(markup: str, pronunciation: str = "respell") -> list[dict]:
    """Apple's nested spans flattened into absolutely-indented blocks.

    Returns dicts of {html, kind, indent, hang} with indent/hang in em.

    Promotion rather than <br> insertion, because only a block can carry a
    margin: inline content cannot be indented, and an earlier version that
    merely inserted line breaks produced a flush-left wall of text.

    The walk accumulates indentation on the way down instead of mapping each
    class to a fixed depth, because Apple's margins nest — an `x_xd1.hasSn`
    inside an `x_xd0` is indented by both, for 2em, with its number hanging
    back to 1em.

    Returns [] when the markup cannot be parsed, so callers can fall back.
    """
    try:
        import lxml.html
    except ModuleNotFoundError:
        return []
    try:
        doc = lxml.html.fromstring(markup)
    except Exception:
        return []

    _prune(doc, pronunciation)

    blocks: list[dict] = []

    def emit(html_text: str, kind: str, indent: float, hang: float = 0.0) -> None:
        if html_text and html_text.strip():
            blocks.append(
                {"html": html_text, "kind": kind, "indent": indent, "hang": hang}
            )

    def walk(el, indent: float, kind: str, parent_layout: str | None) -> None:
        import lxml.html as lh

        run: list[str] = []
        hang = HANG_EM if "hasSn" in set((el.get("class") or "").split()) else 0.0

        def flush() -> None:
            nonlocal run
            if run:
                emit("".join(run), kind, indent, hang)
                run = []

        if el.text and el.text.strip():
            run.append(el.text)

        for child in el:
            classes = set((child.get("class") or "").split())
            layout = _layout_class(classes)
            numbered = "hasSn" in classes

            # The part of speech: a block that hangs left of its senses.
            if parent_layout == "x_xd0" and "x_xdh" in classes and layout is None:
                flush()
                emit(_outer_html(child), "pos", indent - POS_OUTDENT_EM)
                if child.tail and child.tail.strip():
                    run.append(child.tail)
                continue

            is_block = layout is not None and (
                layout in ALWAYS_BLOCK or numbered
            )

            if not is_block:
                # Unstyled wrappers have to be walked *through*, at the same
                # indent, not swallowed. Apple has several — the record's
                # outer <div>, and `span.sg`, which has no rule in the
                # stylesheet at all and holds block-level children. Treating
                # them as inline content put the whole entry on one line.
                #
                # Anything with no block descendants is genuinely inline and
                # joins the run. That is also what stops a subtree being
                # dropped: a single-sense entry carries no numbered container
                # anywhere, and recursing past it used to lose the definition.
                if _contains_block(child):
                    flush()
                    walk(child, indent, kind, parent_layout)
                else:
                    run.append(lh.tostring(child, encoding="unicode"))
                    continue
                if child.tail and child.tail.strip():
                    run.append(child.tail)
                continue

            flush()
            child_indent = indent + INDENT_EM.get(layout, 0.0)
            if numbered and layout in BLOCK_IF_NUMBERED:
                child_indent += NUMBERED_EXTRA_EM
            elif numbered and layout == "x_xd1":
                child_indent += NUMBERED_EXTRA_EM

            child_kind = kind
            if layout == "x_xh0":
                child_kind = "head"
            elif layout.startswith("x_xo"):
                child_kind = "extra"
            elif "exg" in classes or "eg" in classes:
                child_kind = "example"
            elif layout in BLOCK_IF_NUMBERED:
                child_kind = "subsense"
            else:
                child_kind = "sense"

            walk(child, child_indent, child_kind, layout)

            if child.tail and child.tail.strip():
                run.append(child.tail)

        flush()

    body = doc.find("body")
    target = body if body is not None else doc
    walk(target, 0.0, "head", None)

    # The first part of speech joins the headword line.
    #
    # Apple's own CSS keeps it on its own line (`span.x_xd0 > span.x_xdh {
    # display: block }`, and the panel override that would inline it is
    # commented out) — but Dictionary.app's Look Up popover plainly shows
    # "ap·pli·ca·tion | ˌapləˈkāSHən | noun" on one line, so in recent macOS
    # the popover is evidently not driven by this stylesheet. Matching the
    # thing on screen rather than the CSS.
    #
    # Only the first: a second part of speech ("verb" after "noun") still
    # starts its own line, which is also what the popover does.
    if len(blocks) >= 2 and blocks[0]["kind"] == "head" and blocks[1]["kind"] == "pos":
        blocks[0]["html"] += " " + blocks[1]["html"]
        del blocks[1]

    if not blocks:
        emit(_inner_html(target), "head", 0.0)
    return blocks


def _outer_html(el) -> str:
    import lxml.html

    return lxml.html.tostring(el, encoding="unicode", with_tail=False)


BLOCK_CSS = {
    "head": "b-head",
    "pos": "b-pos",
    "sense": "b-sense",
    "subsense": "b-sub",
    "example": "b-ex",
    "extra": "b-extra",
}


def apple_to_html(
    markup: str, pronunciation: str = "respell", base_px: int = 14
) -> str:
    """One <p> per block, positioned by inline style.

    The horizontal position cannot come from the class: the same class occurs
    at several depths, and the depth is what Apple's cumulative em ladder
    produces. So margin-left and the negative text-indent that makes the
    hanging number are written per block, in px converted from Apple's em.
    """
    blocks = apple_blocks_v2(markup, pronunciation)
    if not blocks:
        return f'<p>{html.escape(re.sub(r"<[^>]+>", "", markup))}</p>'

    out: list[str] = []
    for block in blocks:
        cls = BLOCK_CSS.get(block["kind"], "b-sense")
        left = max(0.0, block["indent"]) * base_px
        style = f"margin-left:{left:.0f}px;"
        if block["hang"]:
            style += f"text-indent:-{block['hang'] * base_px:.0f}px;"
        out.append(f'<p class="{cls}" style="{style}">{block["html"]}</p>')
    return "".join(out)


VI_HEAD = re.compile(r"^@(?P<word>.+?)\s*(?P<ipa>/[^/]*/)?\s*$")


def vietnamese_to_html(body: str) -> str:
    """The FVDP/sdcv text format, regular enough to parse:

        @serendipity /,seren'dipiti/
        *  danh từ
        - khả năng cầu may (...)
        =at a run+ đang chạy

    Rendered into the same block ladder as the Apple entries so the two do
    not look like two different programs.
    """
    out: list[str] = []
    # The format marks senses with a bare "-" and no number, but every other
    # dictionary here numbers them and so does macOS. Reset per headword.
    sense = 0
    for raw in body.splitlines():
        line = raw.strip()
        if not line:
            continue
        head = line[0]
        rest = line[1:].strip()
        if head == "@":
            sense = 0
            m = VI_HEAD.match(line)
            word = html.escape((m.group("word") if m else rest).strip())
            ipa = (m.group("ipa") or "").strip() if m else ""
            piece = f'<p class="b-head"><span class="hwplain">{word}</span>'
            if ipa:
                piece += f' <span class="ph">| {html.escape(ipa.strip("/"))} |</span>'
            out.append(piece + "</p>")
        elif head == "*":
            out.append(f'<p class="b-pos">{html.escape(rest)}</p>')
        elif head == "-":
            sense += 1
            out.append(
                f'<p class="b-sense"><span class="sn">{sense}</span>&nbsp; '
                f'<span class="df">{html.escape(rest)}</span></p>'
            )
        elif head == "=":
            ex, _, trans = rest.partition("+")
            piece = f'<p class="b-ex">{html.escape(ex.strip())}'
            if trans.strip():
                piece += f" &nbsp;{html.escape(trans.strip())}"
            out.append(piece + "</p>")
        elif head == "!":
            out.append(f'<p class="b-extra">{html.escape(rest)}</p>')
        else:
            out.append(f'<p class="b-sense">{html.escape(line)}</p>')
    return "".join(out)


def wordnet_to_html(body: str) -> str:
    """lookup_wordnet marks part-of-speech blocks with \\x00 separators.

    Synonyms are bolded and the parenthesised gloss left plain, which is how
    WordNet's overview reads: "run, go, pass -- (stretch out over ...)".
    """
    out: list[str] = []
    for line in body.splitlines():
        if line.startswith("\x00"):
            _, pos, lemma = line.split("\x00", 2)
            out.append(
                f'<p class="b-head"><span class="hwplain">{html.escape(lemma)}</span>'
                f' <span class="pos">{html.escape(pos)}</span></p>'
            )
            continue
        num, _, rest = line.partition(". ")
        syns, sep, gloss = rest.partition(" -- ")
        piece = f'<p class="b-sense"><span class="sn">{html.escape(num)}</span>&nbsp; '
        if sep:
            piece += f'<span class="wnsyn">{html.escape(syns)}</span> '
            piece += f'<span class="df">{html.escape(gloss)}</span>'
        else:
            piece += f'<span class="df">{html.escape(rest)}</span>'
        out.append(piece + "</p>")
    return "".join(out)


# Wiktionary's dictd body is the raw wikitext of the article, templates and
# all, so looking up "kubernetes" showed "{{lb|en|computing}} An open-source
# orchestrator..." and "Providence" showed "{{place|en|A <<city>> in
# <<co/Providence County>>...}}". Counted over six words: 132 {{ux}}, 101
# {{lb}}, 45 {{quote-book}}. These tables cover what the data actually
# contains -- a census rather than a guess -- and anything unlisted falls
# through to "keep the prose, drop the bookkeeping".
WIKI_DROP = frozenset(
    {
        "senseid",
        "seemorecites",
        "seecites",
        "defdate",
        "nb",
        "nbsp",
        "rfex",
        "rfdef",
        "rfquote",
        "attention",
        "anchor",
        "c",
        "topics",
    }
)
# Rendered as "(computing)", "(US, informal)" -- macOS brackets its own domain
# and register labels the same way.
WIKI_PAREN = frozenset({"lb", "label", "qualifier", "q", "gloss", "gl", "i"})
# A cross-reference to another term; only the term itself is wanted.
WIKI_TERM = frozenset({"l", "m", "w", "link", "mention", "ll", "pedlink"})
WIKI_LIST = {
    "syn": "synonyms",
    "ant": "antonyms",
    "hypo": "hyponyms",
    "hyper": "hypernyms",
    "cot": "coordinate terms",
    "near-syn": "near synonyms",
}
# The usage example, which is the one part of a {{ux}} worth showing.
WIKI_EXAMPLE = frozenset({"ux", "uxi", "usex", "ux-lite", "eg"})
WIKI_LANG_RE = re.compile(r"^[a-z]{2,3}(-[a-z0-9-]+)?$")
WIKI_NAMED_RE = re.compile(r"^[A-Za-z0-9_.-]+\s*=")
# <<city>> and <<co/Providence County>> inside {{place}}: the part after the
# slash is the display form, the part before is a bare entity type.
WIKI_ENTITY_RE = re.compile(r"<<([^<>]*?)>>")
# A line left holding only wiki list punctuation once its template is gone.
WIKI_BULLET_RE = re.compile(r"^[\s*#:;.,|-]*$")
# Wiktionary's inline modifiers on a list item: "k8s<q:stylized>" tags the
# synonym with a qualifier, <t:...> glosses it, <tr:...> transliterates it.
# The ones that carry words are worth keeping, bracketed like any other
# qualifier; <id:...>, <pos:...> and friends are bookkeeping.
WIKI_MOD_KEEP = frozenset({"q", "qq", "t", "gloss"})
WIKI_MOD_RE = re.compile(r"<([a-z]{1,5}):([^<>]*)>")


def _wiki_template(inner: str) -> str:
    """One `{{...}}` body (already free of nested templates) as plain text."""
    parts = [part.strip() for part in inner.split("|")]
    name = parts[0].strip().lower()
    # Named arguments are metadata -- author=, title=, page=, isbn= -- and are
    # what makes an unstripped {{quote-book}} fifteen lines long.
    args = [part for part in parts[1:] if part and not WIKI_NAMED_RE.match(part)]
    # Nearly every template takes the language as its first argument.
    if args and WIKI_LANG_RE.match(args[0]):
        args = args[1:]

    if name in WIKI_DROP or name.startswith(("quote-", "rq:", "rq ")) or name == "rq":
        return ""
    if name in WIKI_EXAMPLE:
        return args[0] if args else ""
    if name in WIKI_PAREN:
        return f"({', '.join(args)})" if args else ""
    if name in WIKI_TERM:
        return args[0] if args else ""
    if name in WIKI_LIST:
        return f"{WIKI_LIST[name]}: {', '.join(args)}" if args else ""
    if name.endswith(" of") and args:
        # "inflection of", "nonstandard spelling of", "plural of".
        return f"{name} {args[0]}"
    if name in {"smallcaps", "sc"}:
        return args[0] if args else ""
    # Unknown: keep the positional text, which for prose templates like
    # {{place}} is the definition itself, and drop the name.
    return " ".join(args)


def clean_wikitext(body: str) -> str:
    """Resolve wikitext markup to plain text, innermost template first.

    Templates nest and -- because the dictd body is hard-wrapped -- straddle
    line breaks, so this works on the whole body rather than line by line.
    Innermost-first means each template's arguments are already plain by the
    time it is handled, which is what lets the argument split be a plain
    `str.split("|")`.
    """
    # Bounded in case of unbalanced braces in the source.
    for _ in range(10000):
        close = body.find("}}")
        if close < 0:
            break
        open_ = body.rfind("{{", 0, close)
        if open_ < 0:
            break
        body = body[:open_] + _wiki_template(body[open_ + 2 : close]) + body[close + 2 :]

    body = WIKI_ENTITY_RE.sub(lambda m: m.group(1).rsplit("/", 1)[-1], body)
    body = WIKI_MOD_RE.sub(
        lambda m: f" ({m.group(2)})" if m.group(1) in WIKI_MOD_KEEP else "", body
    )

    out: list[str] = []
    for line in body.splitlines():
        # A dropped quote leaves its bullet behind, and its own newlines went
        # with it, so the leftovers are punctuation-only lines.
        if WIKI_BULLET_RE.match(line):
            continue
        indent = line[: len(line) - len(line.lstrip())]
        # Interior runs collapse because a template that spanned three wrapped
        # lines leaves their indentation inside what it is replaced by.
        out.append(indent + " ".join(line.split()))
    return "\n".join(out)


def text_to_html(body: str) -> str:
    """Fallback for formats with no structure worth parsing (Wiktionary).

    Indentation is meaningful there, so it is mapped onto the block ladder
    rather than collapsed by HTML layout.
    """
    out: list[str] = []
    for line in clean_wikitext(body).splitlines():
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip())
        cls = "b-head" if indent == 0 else ("b-pos" if indent <= 2 else "b-sense")
        out.append(f'<p class="{cls}">{html.escape(line.strip())}</p>')
    return "".join(out)


def entry_to_html(entry: Entry, pronunciation: str, base_px: int = 14) -> str:
    if entry.is_html:
        return apple_to_html(entry.body, pronunciation, base_px)
    if entry.dict_name == "WordNet":
        return wordnet_to_html(entry.body)
    if entry.body.lstrip().startswith("@"):
        return vietnamese_to_html(entry.body)
    return text_to_html(entry.body)


def section_heading(name: str, t: dict[str, str], theme: dict) -> str:
    """A dictionary's name with a full-width rule under it.

    Not what macOS does — it runs the rule inline to the right of the name,
    "English ─────────" — and not what this docstring used to claim either: a
    two-cell table was tried and abandoned. See the comment below for what
    else was tried, and `popup.qml` for where the inline version does happen,
    in QML rather than in the markup.
    """
    # The name, then a full-width rule on the next line.
    #
    # macOS runs the rule inline to the right of the name ("English ──────"),
    # and that is not reachable in Qt's rich text. Everything was tried:
    #
    #   - a two-cell table with no widths: the name cell took most of the
    #     table and the rule collapsed to a dash at the right edge;
    #   - width="100%" on the rule cell: Qt squeezed the name cell to its
    #     minimum and wrapped "New Oxford American Dictionary (en-en)" to one
    #     character per line;
    #   - nowrap on the name cell: ignored;
    #   - a measured run of ─ glyphs: the length has to be guessed from font
    #     metrics Python cannot see, so it undershot to a three-dash stub for
    #     a long name and vanished entirely for another. Guessing high
    #     instead wraps the rule onto its own line, which is worse.
    #
    # An <hr> is always full width, so it goes underneath. Stable for any
    # dictionary name, font and popup width, which a guessed length is not.
    _ = theme
    return (
        f'<p class="sec">{html.escape(name)}</p>'
        f'<hr color="{t["rule"]}"/>'
    )


def _fonts(theme: dict | None) -> tuple[str, str]:
    """Body and label families.

    Apple splits them: `body { font-family: ui-serif }`, with `system-ui` on
    `sn`, `pos`/`posg`/`ps`, `lg`/`gg`, `fld`/`lev` and `sy`. So definitions
    are serif and numbers, parts of speech and labels are sans — a very
    visible signature of Dictionary.app that this was missing by setting one
    sans family for everything.

    The defaults resolve on this machine to SF Pro Text (which *is* Apple's
    system font) and Noto Serif; New York, Apple's serif, is not installed.
    """
    th = theme or {}
    body = th.get("fontFamily") or "Noto Serif, serif"
    label = th.get("labelFontFamily") or "SF Pro Text, sans-serif"
    return str(body), str(label)


def _sizes(theme: dict | None, base_px: int) -> tuple[int, int]:
    section_px = (theme or {}).get("sectionFontPx")
    if not isinstance(section_px, (int, float)):
        section_px = base_px + 2
    # Apple sets line-height 140% on an entry (150% in the bilingual, for the
    # Vietnamese script). Nothing was setting it here, which is a large part of
    # why this read tighter than Dictionary.app.
    line_pct = (theme or {}).get("lineHeightPct")
    if not isinstance(line_pct, (int, float)):
        line_pct = 140
    return int(section_px), int(line_pct)


def render_sections(
    word: str,
    entries: list[Entry],
    *,
    theme: dict | None = None,
    base_px: int = 14,
    pronunciation: str = "respell",
    note: str = "",
) -> dict:
    """The same content, but per dictionary rather than as one document.

    For the popup, which gives each dictionary its own Text item so it can be
    truncated to a line budget independently and expanded on its own — which
    is how macOS does it. Dictionary.app cuts mid-token ("…| [with more"), so
    the limit is geometric, which is also why there is no priority metadata in
    the data to key a semantic truncation off.

    One document is still what the terminal and `--html` want, so render_html
    composes these rather than duplicating the work.
    """
    t = theme_colors(theme)
    section_px, line_pct = _sizes(theme, base_px)
    body_font, label_font = _fonts(theme)

    sections: list[dict] = []
    if not entries:
        sections.append(
            {
                "name": "",
                "html": (
                    f'<p class="b-head"><span class="hwplain">{html.escape(word)}</span></p>'
                    '<p class="b-extra">No entry in any configured dictionary.</p>'
                ),
            }
        )
    else:
        # One section per dictionary, not per entry: a dictionary with
        # homographs returns several entries for the same word, and repeating
        # its name above each reads as a rendering fault rather than as senses.
        for entry in entries:
            body = entry_to_html(entry, pronunciation, base_px)
            if sections and sections[-1]["name"] == entry.dict_name:
                sections[-1]["html"] += body
            else:
                sections.append({"name": entry.dict_name, "html": body})

    return {
        "word": word,
        "note": note,
        "style": stylesheet(t, base_px, section_px, line_pct, body_font, label_font),
        "bodyFont": body_font,
        "labelFont": label_font,
        "rule": t["rule"],
        "accent": t["accent"],
        "sectionPx": section_px,
        "sections": sections,
    }


def render_html(
    word: str,
    entries: list[Entry],
    *,
    theme: dict | None = None,
    base_px: int = 14,
    pronunciation: str = "respell",
    note: str = "",
) -> str:
    doc = render_sections(
        word,
        entries,
        theme=theme,
        base_px=base_px,
        pronunciation=pronunciation,
        note=note,
    )
    t = theme_colors(theme)
    parts = [f"<html><head><style>{doc['style']}</style></head><body>"]

    if note:
        parts.append(f'<p class="gp">{html.escape(note)}</p>')

    for section in doc["sections"]:
        if section["name"]:
            parts.append(section_heading(section["name"], t, theme or {}))
        parts.append(section["html"])

    parts.append("</body></html>")
    return "".join(parts)


def html_to_text(markup: str, pronunciation: str = "respell") -> str:
    """Flatten an Apple entry for the terminal renderer.

    Built from the same blocks as the popup, so the two renderers cannot
    disagree about where a sense begins.
    """
    blocks = apple_blocks_v2(markup, pronunciation)
    if not blocks:
        text = re.sub(r"<[^>]+>", "", markup)
        return html.unescape(re.sub(r"[ \t]{2,}", " ", text)).strip()

    lines: list[str] = []
    for block in blocks:
        # <br> first, and to a space: stripping it with every other tag is
        # what left "providencetừ trái nghĩa" in the text renderer while the
        # popup, which actually renders the break, looked right.
        text = re.sub(r"(?i)<br[^>]*>", " ", block["html"])
        text = html.unescape(re.sub(r"<[^>]+>", "", text))
        text = re.sub(r"[ \t]{2,}", " ", text).strip()
        if not text:
            continue
        # Two spaces per em of Apple's indent, so the text rendering shows the
        # same hierarchy as the popup rather than a separate guess at it.
        lines.append("  " * int(max(0.0, block["indent"])) + text)
    return "\n".join(lines)


def _wordnet_text(body: str) -> str:
    lines: list[str] = []
    for line in body.splitlines():
        if line.startswith("\x00"):
            _, pos, lemma = line.split("\x00", 2)
            lines.append(f"{lemma}  {pos}")
        else:
            lines.append(line)
    return "\n".join(lines)


def render_text(
    word: str,
    entries: list[Entry],
    note: str = "",
    pronunciation: str = "respell",
) -> str:
    out: list[str] = []
    if note:
        out.append(note)
        out.append("")
    out.append(word)

    if not entries:
        out.append("")
        out.append("No entry in any configured dictionary.")
        out.append('Run "dict-lookup --list" to see which ones are loaded.')
        return "\n".join(out) + "\n"

    last = None
    for entry in entries:
        out.append("")
        if entry.dict_name != last:
            out.append(f"── {entry.dict_name} ──")
            out.append("")
            last = entry.dict_name
        if entry.is_html:
            out.append(html_to_text(entry.body, pronunciation))
        elif entry.dict_name == "WordNet":
            out.append(_wordnet_text(entry.body))
        else:
            # Same cleanup as the HTML path, so `dict-lookup WORD` and the
            # popup cannot disagree about what a dictionary says.
            out.append(clean_wikitext(entry.body).strip("\n"))
    return "\n".join(out) + "\n"
