# Dictionary Look Up

macOS-style "Look Up": select a word anywhere, press **SUPER + CTRL + D**, and
a definition popup opens at the mouse. `q`, `Esc`, or a click anywhere else
closes it.

Declared in [`modules/home-manager/desktop/dictionary/`](../modules/home-manager/desktop/dictionary/default.nix),
except the shortcut, which is in
[`home/nagih/caelestia/hypr-user.lua`](../home/nagih/caelestia/hypr-user.lua)
so it can be rebound with `hyprctl reload` rather than a switch.

## The pieces

| Piece | What it is |
| --- | --- |
| `dict-lookup WORD` | the lookup, as plain text on stdout — no Wayland, no window |
| `dict-lookup --html WORD` | the same lookup as an HTML document, for the popup |
| `dict-lookup --list` | which dictionaries are actually loaded |
| `dict-popup` | reads the selection and shows the result |
| `dict-import-macos user@host` | converts macOS dictionaries to StarDict |

When a definition looks wrong, reach for `dict-lookup` first: nothing about
Wayland, Quickshell or the compositor is involved in it.

The engine and both renderers are Python — `lookup.py` (the lookups),
`render.py` (text and HTML), `cli.py` (the entry point). The HTML renderer has
to parse each backend's own text format into structure to get the typography,
which is real parsing rather than something sed should attempt; keeping the
text renderer beside it means one implementation of the lookups instead of two
that drift.

## Getting the word: why selecting is enough

Three sources, best first:

1. **PRIMARY** — the "just select it" buffer. Free, no side effects.
2. **A synthesized copy** — ask the focused window to copy, then put the
   clipboard back.
3. **The clipboard** — nothing selected anywhere, so show what was last
   copied, clearly labelled as such.

Step 2 exists because PRIMARY is not reliable enough to build on. Electron apps
never publish it, and neither does GTK for a keyboard selection — measured:
Ctrl+A in a `zenity --entry` leaves PRIMARY empty. A find-in-page highlight
leaves it empty too. Without step 2, "select a word and press the shortcut"
works only in some apps, which defeats the point.

Three details that each cost a debugging round:

- **The copy keystroke is retried.** The shortcut is a chord, so SUPER and
  CTRL are usually still held when the script runs and the app receives
  Super+Ctrl+C, copying nothing. The same code worked when started from a
  shell with no keys held. Retrying a few times beats adding a fixed delay to
  every lookup.
- **The sentinel.** With no selection the keystroke is a no-op and the
  clipboard simply does not change — indistinguishable from successfully
  copying whatever was already there. Parking a random string there first
  makes "nothing happened" detectable, so a stale clipboard is never shown as
  if it were a selection. That was the original bug: looking up a word showed
  `tôi` from an hour-old copy.
- **Terminals and remote desktops are skipped** (`selection.skipClasses`).
  Ctrl+C in a terminal is SIGINT and would kill whatever is running; in a
  Horizon/RDP/VNC client it is forwarded to another machine, where the
  selection lives anyway so the copy could not come back. Terminals publish
  PRIMARY reliably, so nothing is lost by skipping them.
- **The previous popup is closed first, before the selection is read.** This
  is the ordering that matters, and getting it backwards produced an exact
  symptom: the first lookup worked and every one after it showed a stale
  clipboard. The popup holds exclusive keyboard focus, so while one is open a
  synthesized Ctrl+C lands on the popup rather than the window holding the
  selection, and `hyprctl activewindow` still reports the window that had
  focus *before* it — so the terminal skip-rule was being tested against the
  wrong window, and skipped a browser lookup because an unrelated Alacritty
  was "focused".
- **The popup is identified by an environment marker, not its command line.**
  `DICT_POPUP_MARKER` is checked in `/proc/<pid>/environ`. A cmdline match
  worked for the terminal backend, which carries `--class dict-popup` in
  argv, but the Quickshell one is `qs -p /nix/store/<hash>-popup.qml` and
  contains the class nowhere — so "close the previous popup" silently never
  fired and popups stacked up, one per lookup.
- **A directory guard covers startup**, which the marker does not.
  `close_previous` keys off the pidfile, and the pidfile is only written once
  the lookup has finished — so two presses inside that window meant the second
  found no pidfile, killed nothing, and both popups opened, both writing the
  same payload and truncating the same log.

  This was a `flock` first, and **that broke the shortcut after exactly one
  use.** A descriptor is inherited by every child, and `wl-copy` *daemonises*
  to keep serving the clipboard selection — so the `wl-copy` left behind by
  the clipboard restore held the lock for as long as it owned the selection,
  which is to say indefinitely:

  ```
  pid 142027  wl-copy --type image/png   fd 9 -> .../dict-popup/lock
  ```

  Every press after that exited silently at `flock -n 9 || exit 0`, *before*
  the log is truncated — so the one diagnostic that would have explained it
  was frozen at the timestamp of the last working lookup. Closing the
  descriptor before `exec` does not help: the fork already has its own copy.

  `mkdir` is atomic and belongs to no descriptor, so nothing can inherit it.
  The marker holds the owner's pid, and a start is refused only while that pid
  is **both alive and younger than 60s** — so a killed lookup is taken over on
  the next press rather than waited out. That matters more than it sounds:
  bash defers a trap until the running foreground command returns, and
  `SIGKILL` runs no trap at all, so "the owner is gone" has to be detectable
  from outside. Verified against the three cases that matter — a second press
  during startup (refused), a daemonised child outliving the script (does not
  block), and `SIGKILL` mid-lookup (next press takes over immediately).
- **The clipboard restore is a trap**, not a last line. Nothing inside
  `synthesize_copy` can trip `errexit` — everything fragile has `|| true` —
  but an external kill can, and that left `dict-popup-1234-…` in the
  clipboard with the real contents only in `clipboard.saved`, which the next
  run overwrites. Note that bash defers a trap until the current foreground
  command finishes, so a kill during the lookup itself restores when it
  returns; `SIGKILL` still strands the sentinel, which nothing can help.
- **A failed `hyprctl` must not be fatal.** `read` returns non-zero at EOF,
  and under `errexit` that aborted the script at the geometry step — *after*
  the old popup had been killed, so the shortcut closed the popup and opened
  nothing. It also made the defaults just below unreachable, which is the
  misleading part: they read as a safety net but could never run. Both reads
  now end in `|| :` and the fallback logs itself.

The clipboard is saved and restored around the synthesized copy. Only one type
survives, since `wl-copy` advertises one at a time, and **text/plain is
preferred over the first type `--list-types` reports** — that order is not a
preference order, so text copied out of a browser lists `text/html` first and
taking the first type turned a plain-text clipboard into `<meta http-equiv=…`.

Every read is pinned to `text/plain` for the same family of reason: given no
type, `wl-paste` returns whatever the owner offers first, and a copied image
advertises `text/html` and `image/png` but no `text/plain`, so a bare
`wl-paste` hands back HTML which then gets looked up as a word. `wl-clipboard`
synthesizes `text/plain` for owners advertising only
`text/plain;charset=utf-8` or `UTF8_STRING`, so pinning it still works for
XWayland apps.

If a lookup surprises you, `$XDG_RUNTIME_DIR/dict-popup/last-run.log` records
which source answered and why, in lengths rather than contents.

## Dictionaries

`custom.dictionary.dictionaryOrder` sets which appear and in what order — the
equivalent of Dictionary.app's *"Drag reference sources into the order you
prefer"*. Backend order alone cannot express it, because the converted macOS
dictionaries and the Vietnamese ones are all the same backend. The default
mirrors Dictionary.app's own list:

| Dictionary | Words | Source |
| --- | --- | --- |
| New Oxford American Dictionary | 111,579 | converted from macOS |
| Oxford American Writer's Thesaurus | 16,007 | converted from macOS |
| Từ Điển Tiếng Việt | 43,751 | converted from macOS |
| Từ điển Lạc Việt | 280,474 | converted from macOS |
| Wiktionary | 8.0M headwords | `dictdDatabases` |

Lạc Việt is the one that answers in both directions: despite billing itself
`(vi-vi)` it returns entries for `nhà` and `khả năng` as well as for
`application`. That is why `stardict.packages` is empty. FVDP's Anh-Việt
(103,872 words, fetched by hash in `stardict-dictionaries.nix`) was the
default until the macOS dictionaries could be converted — nixpkgs has nothing
Vietnamese — and Lạc Việt then beat it on size, direction and spelling, so it
was only adding a section to every English lookup. It stays defined because it
is the only Vietnamese dictionary this repo can build unaided; the converted
four need the Mac again after a reinstall.

### WordNet, and why it is off

`wordnet.enable` is `false`, and the argument that kept it on for most of this
module's life no longer holds — worth writing down, because the argument is a
good one and will look like a reason to re-enable it.

WordNet was never here for its definitions. It is the only backend that does
morphology — `wn` resolves "discoveries" to "discovery" and "ran" to "run",
where `wordnet.index` has no entry for either — and those lemmas were reused
to rescue the *other* backends, which match exactly. Without it, selecting
"discoveries" really did return no Vietnamese at all.

That was true of **FVDP Anh-Việt**, a bare StarDict dictionary with no `.syn`.
The macOS dictionaries index their own inflections:

```
oxford-american.syn   mice present  children present  teeth present  women present
lacviet-vi-en.syn     mice present  children present  teeth present  women present
```

So dropping FVDP made the rescue redundant, which was not noticed at the time.
Measured with the WordNet section off, comparing `wn` present against `wn`
absent over `discoveries ran mice children teeth women swum begun went
applications houses better worse feet knives lay`: **byte-identical output for
all 16**, every irregular included.

What was left was a synset dump under NOAD's typography, English-only,
duplicating a better source, for 108 MiB of closure.

Setting `wordnet.enable = true` brings it back, and brings `wn` back with it —
`wordnet_lemmas` is gated on the same flag, so with it off nothing spawns a
`wn` that cannot run. The entry stays in `dictionaryOrder` and is inert while
the dictionary is absent, as "Anh Việt" is. It is also the only English
dictionary this repo can build unaided, which is the one real argument for
keeping it: the converted four need the Mac again after a reinstall, and
Wiktionary would be all that is left.

### Importing the macOS dictionaries

```bash
dict-import-macos nghiavm7@192.168.0.16
```

Needs Remote Login on the Mac and key-based ssh. It finds each bundle by name
(the path contains an asset hash that changes with every macOS update), copies
it excluding localisations, converts it with pyglossary, dictzips the result
and installs it under `stardict.dataDir`, one directory each — they all ship a
`res/style.css` and would otherwise collide.

Costs, measured: 92 MB copied, 580 MB of HTML after conversion, **86 MB** on
disk after dictzip.

Two things worth knowing:

- **pyglossary's Apple reader needs `biplist`**, which is in nixpkgs but not
  among pyglossary's own dependencies. The tool adds it to `PYTHONPATH`.
- **The result is not reproducible from this repo**, and cannot be: Nix cannot
  fetch a bundle that only exists on a licensed Mac. A reinstall needs the Mac
  again. This was a deliberate trade for having the real Oxford and Lạc Việt
  content; the alternative was GCIDE plus Moby Thesaurus, which are free and
  fetchable.
- These are Oxford and Lạc Việt licensed content. Fine on your own machine,
  **not** redistributable.

### Adding a Vietnamese StarDict dictionary

Anything dropped into `~/.local/share/stardict/dic` is picked up with no
rebuild. A dictionary already in dictd format goes in `dictdDatabases`
instead, which does need a switch.

### Wiktionary ships wikitext, not prose

Its dictd body is the raw article source, so `kubernetes` used to render as

```
1. {{lb|en|computing}} An open-source orchestrator system of
   containerized applications, originally designed by Google.
        {{syn|en|k8s<q:stylized>}}
```

and `Providence` as `{{place|en|A <<city>> in <<co/Providence County>>...}}`.
A `{{quote-book}}` is worse — fifteen lines of `author=`, `isbn=`, `page=`.
Counted over six words: 132 `{{ux}}`, 101 `{{lb}}`, 45 `{{quote-book}}`.

`clean_wikitext()` resolves this, and the tables in it are a census of what
the data actually contains rather than a guess. `{{lb|en|computing}}` becomes
*(computing)*, matching how macOS brackets its own domain labels; `{{ux}}`
keeps the example and drops the wrapper; `{{syn}}` becomes
`synonyms: k8s (stylized)`; quote templates go entirely. Anything unlisted
falls through to "keep the positional text, drop the name", which is what
makes prose templates like `{{place}}` come out readable.

Two details that decide whether it works at all. Templates **nest**, so they
are resolved innermost-first — which is also what lets the argument split be
a plain `str.split("|")`, since by then the arguments contain no braces. And
because the dictd body is hard-wrapped, a template **straddles line breaks**,
so this runs over the whole body rather than line by line; a dropped quote
takes its newlines with it and leaves a bullet alone on a line, which is why
punctuation-only lines are dropped afterwards.

Both renderers call it, so `dict-lookup WORD` and the popup cannot disagree.

### Dropping Wiktionary

`dictdDBs.wiktionary` is 497 MB. `dictdDatabases = [ ];` removes it.

## No daemon, no sudo

Everything is offline and user-level — no `services.dictd`, nothing needing a
system rebuild.

A dictd database is not a server protocol, it is two files: a sorted `.index`
of `headword<TAB>offset<TAB>length` (offset and length in dictd's own base-64)
beside a `.dict` or `.dict.dz`. `dictzip -S/-E` accepts those base-64 fields
verbatim and prints exactly that byte range, so the daemon the `dict` client
would otherwise need is redundant.

The index is **bisected over an `mmap`**, not read. Wiktionary's is 172 MB and
8.0M lines, and reading it from the top for every candidate spelling cost a
paragraph selection 1.76s — three full scans before `candidates()` falls back
to the first word. Being sorted is the whole point of the format; dictd's own
client binary-searches it too.

Two things the comparison has to get right:

- **The first field only.** Whole lines are *not* ordered — entries sharing a
  headword leave the base-64 offset column in arbitrary order, which is why
  `sort -c` on the whole file fails at line 2.
- **Byte order, not locale.** Verified over the whole index with
  `cut -f1 wiktionary-en.index | LC_ALL=C sort -c`. Worth re-running when
  adding a dictd database: a case-insensitively sorted index would make the
  bisect miss silently. `candidates()` already tries both cases, so each
  spelling is its own bisect.

The replacement was checked against the old scan over 328 headwords — the
file's first and last entries, the empty-headword lines at its head, the 20
most-duplicated headwords, 300 random ones and 5 misses — with no differences.

| | before | after |
| --- | --- | --- |
| single word | 0.51s | 0.19s |
| no match | 0.38s | 0.06s |
| 840-char paragraph | 1.76s | 0.51s |

Some of that was also `wn` being memoised — it ran twice per candidate, once
for the lemmas and once for WordNet's own entry — though that only applies
with `wordnet.enable = true`, which is no longer the default.

`sdcv` is driven with `--json-output` rather than its default text, which is
not meant to be parsed: it marks both the dictionary name and the headword
with the same `-->`, claims "Found 1 items" even under `--exact-search`, and
prints `save to cache <path>` on stdout the first time it indexes a
dictionary. Its cache lands in `~/.cache/sdcv`, so a read-only store path for
a dictionary is fine.

## The popup

`popup.backend` picks between:

- **`quickshell`** (default) — the macOS-style popup: a layer-shell surface
  with proportional type, blur and rounded corners. ~175ms to appear on its
  own, ~0.8s including the lookup.
- **`terminal`** — the plain-text rendering in a floating terminal with
  `less`. Kept because it needs nothing but a terminal, so it still works if
  the popup breaks.

The popup gets everything in one JSON file whose path is in
`$DICT_POPUP_FILE`: geometry, the screen, and the document. One file rather
than a pile of environment variables because the document is 30–40 KB.

### Why it looks like macOS

Because it is Apple's own markup. A converted `.dictionary` yields Apple's
HTML with Apple's class names intact (`hw`, `syl_txt`, `ph`, `pos`, `sn`,
`df`, `eg`, `ex`, `gp`…), so `render.py` styles that vocabulary rather than
inventing one. Apple's own 45 KB stylesheet is *not* reused — most of its
selectors are outside Qt's subset — but its semantics are.

What that buys, straight from the data: dot-separated syllables
(`ap·pli·ca·tion`), the diacritical respelling, italic part of speech,
numbered senses, italic examples, DERIVATIVES/ORIGIN, blue cross-references.

### Matching the popover, not the main window

Apple's stylesheet carries **83 `html.apple_client-panel` rules** for the
compact Look Up popover, and they are much tighter than the main window's:
`x_xh0` margin-bottom 0.6em → 0.1em, `x_xd0` 0.3/2.0em → 0.1/0.4em, `x_xd1`
0.3/0.7em → 0.1/0.3em, the POS line 0.5em → 0.1em, and the headword 158% →
120%. This popup *is* a popover, so those are the right numbers; the
main-window values left it about twice as airy as Dictionary.app.

Four more things the popover does that this had wrong:

- **Section headings are language/role labels**, not dictionary titles:
  "English", "English Thesaurus", "Vietnamese - English" — where this printed
  "New Oxford American Dictionary (en-en)". See `sectionLabels`.
- **The first part of speech sits on the headword line**
  (`ap·pli·ca·tion | ˌapləˈkāSHən | noun`). Apple's CSS actually keeps it on
  its own line and the panel override that would inline it is commented out,
  so recent macOS evidently does not drive this popover from the stylesheet —
  this matches what is on screen rather than the CSS. A *second* part of
  speech still starts its own line, which is also what the popover does.
- **Two type families.** `body { font-family: ui-serif }` with `system-ui` on
  `sn`, `pos`/`posg`/`ps`, `lg`/`gg` and `fld`/`lev` — so definitions are
  serif and numbers, parts of speech and labels are sans. A very visible
  signature that was missing while everything used one sans family. This
  machine has **SF Pro Text** (Apple's own system font) for the labels; New
  York is not installed, so Noto Serif stands in for the body.
- **The pronunciation is 120%**, as large as the headword, and the part of
  speech is **not italic** — Apple sets only family, colour and weight on it.
  The italic was invented here.

### The section rule, finally inline

`English ─────────` with the rule running off to the right now works, and the
reason is structural: once each dictionary became its own item for the
truncation work, the heading stopped being rich text. It is a QML `Row` with a
`Text` and a 1px `Rectangle`, so it is exact.

In rich text it was genuinely unreachable, and it is worth recording what was
tried so nobody repeats it: a two-cell table with no widths collapsed the rule
to a dash; `width="100%"` on the rule cell squeezed the name to one character
per line; `nowrap` was ignored; an `<hr>` is always full width; and a measured
run of `─` glyphs needs font metrics Python cannot see, so it undershot to a
three-dash stub for one name and vanished for another.

### The layout, taken from Apple's own stylesheet

The converted bundles ship Apple's `DefaultStyle.css` (as `res/style.css`,
~2,800 lines), so the layout is not guesswork — it is read off the real thing.
The important discovery: **the semantic classes carry no layout at all.**
`se1` and `sg` have no rule in the entire stylesheet; `se2`, `msDict`, `semb`,
`exg` and `trg` have only typography. Every box and every margin arrives
through the `x_xd*`/`x_xo*` class sitting on the same element — and both the
monolingual and bilingual dictionaries use the **same** ladder.

So this renderer keys off those, not the semantic names, which is what retired
a run of per-dictionary special cases (`se2` vs `semb`; `gramb` turning out to
be a part-of-speech group rather than a sense; `ps` vs `posg`). Lạc Việt and
NOAD now go through one code path.

Apple's ladder, in em, applied cumulatively:

| Level | Class | margin-left |
| --- | --- | --- |
| headword group | `x_xh0` | 0 |
| part of speech | `x_xd0` | 1.0em |
| the POS label | `x_xdh` under `x_xd0` | **−0.8em** — hangs left, own line |
| sense | `x_xd1` | +1.0em when `.hasSn` |
| subsense | `x_xd1sub` | +1.0em when `.hasSn` |
| deeper (bilingual) | `x_xd2`, `x_xd3` | +1.0em when `.hasSn` |
| ORIGIN / phrases | `x_xo0`… | 0 / 1.0em |

**The single most load-bearing rule in the file**: the container immediately
after a sense number is forced back to `display: inline` unless it carries a
number of its own. That is what keeps "1 a formal request to an authority" on
one line, and why examples flow after the definition rather than sitting on
their own line.

Hanging indents: Apple writes them as a negative margin on the *inline* number
and sets `text-indent: 0em` explicitly — there is exactly one active
`text-indent` in the whole file and it is that zero. A Qt text block has no
negative inline margin, but block `margin-left` plus negative `text-indent` is
the exact equivalent, which is what this emits (per block, as an inline style,
since the same class occurs at several depths).

`line-height` is 140% (150% in the bilingual, for the Vietnamese script).
Nothing was setting it here, which was a large part of why this read tighter
than Dictionary.app.

**The dotted headword is the one place this deliberately diverges.** Apple
hides `syl_txt` and shows `hw`, whose interpuncts are generated content —
`span.hsb:before { content: '\2022' }`. Qt's rich text has no `:before`, so
that is unreachable; this uses the hidden `syl_txt`, which carries the dots as
literal text.

Also taken from Apple: the classes it sets `display: none` on under a
`/* Hide */` banner — `construction`, `cdf`, `domClass`, `semClass`,
`encClass`, `morphSet`, `meta`, `lbrk_txt`. That metadata ships in the data
and Dictionary.app never shows it, so hiding it is matching macOS rather than
a style choice.

### Truncation and "more"

Each dictionary shows at most `theme.maxLines` lines, then a blue **more**
that expands that dictionary alone. Which is why the popup renders one `Text`
per section rather than one for the whole document.

macOS does the same thing and does it **geometrically** — it cuts mid-token
(`… | [with  more`, `requisition,  more`), never at a sense boundary. That is
also the answer to why there is no priority metadata anywhere in the data: a
line budget needs none.

`maxLines` is a budget, not a sense count: the headword renders larger than
the body, so 9 lines is about a headword plus four or five lines of
definition.

**Not** `Text.maximumLineCount`. That property, along with `Text.lineCount`,
`Text.truncated` and `Text.elide`, does nothing under
`textFormat: RichText` — that path lays out through QTextDocument, where Qt
does not implement them. Setting `maximumLineCount: 5` was silently ignored.
So the budget is converted to pixels (`maxLines × fontPx × lineHeightPct`) and
a clipped container enforces it, which works regardless of text format;
whether anything is hidden is `implicitHeight > budget` rather than
`truncated`.

One visible difference from macOS remains: because the cut is at a pixel
height and the content mixes font sizes, the boundary can land mid-line and
leave a sliver of the next line showing. Dictionary.app can measure its own
line boxes and cuts cleanly; nothing in Qt's rich text exposes that.

One thing is **not** in the CSS at all and so cannot be copied:
- **Choosing respelling vs IPA.** No rule for `t_respell` or `t_IPA` anywhere;
  the CSS renders both, which is why they appeared concatenated before the
  `pronunciation` option existed. Dictionary.app filters in app code.

And one that explains the palette: all of Apple's greys are hard-coded black
alphas (`rgba(0, 0, 0, 0.498)`) with no dark-mode adaptation beyond
`img { filter: invert(100%) }`. On a dark background they would be invisible,
so Dictionary.app composites against a light panel — which is why a dark port
needs its own palette, and why `theme.json` carries a light preset for anyone
wanting the closer match.

Five things learned the hard way:

- **The walk must not be able to lose content.** Stopping at marked elements
  and recursing otherwise silently discarded whole subtrees: a *single-sense*
  entry carries no `.se2` at all — NOAD prints no number for those — so
  "serendipity" rendered as a headword, "noun", and then straight to ORIGIN,
  and the Thesaurus lost every synonym. Any subtree with no marked
  descendants is now emitted as-is instead of recursed into.
- **`.gramb` is not a sense.** It looks like one but, like `.se1`, it is a
  part-of-speech group *containing* the senses. Treating it as a sense made
  the walk stop there and Lạc Việt's twelve senses came back as one paragraph
  beginning "danh từ 1 … 2 … 12 …".
- **Part of speech is `.posg` in NOAD but `.ps` in the bilingual
  dictionaries.** Missing the second spelling silently dropped "danh từ" from
  every Lạc Việt entry.
- **Empty pronunciation groups leave their separators behind**, so a
  dictionary with no IPA rendered its headword as `khả năng |  |`.
- **`<br>` has to be substituted, not stripped, in the text renderer.** It was
  being removed with every other tag, which left `providencetừ trái nghĩa` in
  the terminal while the popup — which actually renders the break — looked
  correct.

Five more, about Apple's markup itself:

- **Apple ships two different schemas.** NOAD and the Thesaurus mark each
  sense `.se2`; the bilingual dictionaries use Oxford's other schema, where
  `.semb` is a sense and `.exg` an example. All are spans, so without an
  inserted `<br>` every sense runs into the previous one — Lạc Việt's
  "application" has twelve and arrived as one solid paragraph.
- **`.hw` is only redundant where `.syl_txt` exists.** NOAD ships both and
  macOS shows the dotted one; the bilingual dictionaries ship `.hw` alone, so
  dropping it unconditionally **deleted Lạc Việt's headword** and the entry
  rendered as a bare pronunciation.
- **Breaks split into two groups.** A `.se2` opens its entry, so the first one
  must not get a break or the definition starts blank. A `.synList` always
  follows something, so every one needs its break — including the first, which
  the single-list version skipped, rendering `providencetừ trái nghĩa`.
- **Pick one pronunciation.** The dictionaries ship a respelling and an IPA;
  showing both renders them concatenated as
  `| ˌapləˈkāSHənˌæpləˈkeɪʃən |`. `pronunciation` selects, defaulting to
  the respelling like Dictionary.app's own setting.
- **Inflections are bracketed one at a time**, with the separator written
  *inside* the next bracket — `(runs) (, running |ˈrəniNG|) (past; ran
  |ran|)`, which was the first line of every verb in the popup. Nothing in
  the dictionary's `style.css` or `fbm.css` hides those brackets, so
  Dictionary.app must do it from its own bundle stylesheet, which the
  conversion does not carry. Reconstructing the line takes three changes
  together, and doing only the first makes "break" *worse* — its groups run
  into each other with no separator at all:

  1. keep the first `(` and the last `)` of a run of `.infg` groups;
  2. supply `; ` where Apple authored no separator;
  3. drop the `;` trailing a `.sy` label, since the label and its inflection
     are one phrase — "past ran", not "past; ran".

  Which gives Dictionary.app's own line:

  ```
  run | rən | verb (runs, running | ˈrəniNG |; past ran | ran |; past participle run | rən |)
  set 1 | set | verb (sets, setting | ˈsediNG |; past and past participle set | set |)
  ```

  Entries whose inflections were already one group (`go`, `be`) are left
  alone, and the change was checked against 37 words for differences outside
  the headword line: none.

### Appearance

One `custom.dictionary.theme` attrset, in three layers, each overriding the
last per-key:

1. `themeDefaults` in the module.
2. The `theme` option, for what should be declared in the repo.
3. **`home/nagih/dictionary/theme.json`** — an out-of-store symlink to
   `~/.config/dict-popup/theme.json`, re-read on **every lookup**.

Layer 3 is why border, shadow, radius, colours and fonts can be changed with
**no rebuild**: `hms` is far too slow a loop for "is that border too bright".
Same pattern as `hypr-vars.lua`. Invalid JSON there falls back to the defaults
with a note in the log rather than breaking the popup.

The file documents a **light preset** too, since Dictionary.app's own popup is
a light frosted panel and the dark default matches this desktop instead.

Colours are `#RRGGBBAA` everywhere — CSS order. Qt parses an 8-digit hex as
`#AARRGGBB`, alpha *first*, so `dict-popup` rotates them in jq on the way out;
doing it there rather than in Nix is what lets the live file carry colours.

### The shadow

`RectangularShadow` (QtQuick.Effects, 6.9+), **not** `MultiEffect`.

Hyprland cannot help: its layer rules are `blur`, `blur_popups`, `dim_around`,
`ignore_alpha`, `xray`, `order`, `animation`, `above_lock`, `no_anim`,
`no_screen_share` — no shadow. So Qt has to draw it.

`MultiEffect` was the wrong tool twice over. It draws its *source* as well as
the shadow, and the shadow is derived from the source's alpha, so the source
has to be opaque — which means an opaque stand-in ends up visible through a
translucent card, as a darker rectangle inside a lighter rim. That was the
"two layers" the popup used to show. It also scales its source to its own
bounds, so making it bigger to give the blur room stretched a black rectangle
over the whole surface. `RectangularShadow` takes a shape rather than a
source and draws only the shadow, so there is nothing to bleed through.

The surface is still the card plus `shadowPad` on every side: a layer surface
clips to its own bounds, so the shadow needs that room to fall into, and
`dict-popup` subtracts the same pad from the margins so the *card* stays under
the cursor.

### `blurIgnoreAlpha`, or: the second rounded rectangle

`popup.blurIgnoreAlpha` is the alpha below which Hyprland does **not** blur
the backdrop. It has to sit between the shadow's alpha and the card's, and
getting it wrong looks like a bug in the popup rather than a blur setting.

It was 0.1, which is below everything, so Hyprland blurred the **whole
surface** — the shadow pad included. Blurred wallpaper is lighter and flatter
than the wallpaper around it, so a second, lighter rounded rectangle appeared
about `shadowPad` outside the card. It reads as an outer frame; it is blur
bleeding past the card. Raising it to 0.7 — above `shadowColor`'s 0xA0 (0.63),
below `background`'s 0xd0 (0.82) — leaves exactly the card blurred.

Too high and the card itself stops being blurred. And because it is a
`layer_rule` it needs `hms` **and** `hyprctl reload`, unlike everything else
in the appearance, so lowering `background`'s alpha in theme.json below it
silently turns the blur off until this is lowered to match.

### Qt and QML gotchas

- **Qt rich text does support `<style>` with class selectors.** That was the
  main risk in the whole approach, and it is what makes the above possible.
- **An 8-digit hex colour is `#AARRGGBB`**, alpha *first*, not CSS's
  `#RRGGBBAA`. The options take the familiar order and rotate it, because
  getting it wrong is silent: `#1C1A1Fd0` read as Qt intends is 11% opaque and
  blue, so the popup renders as a barely visible tint rather than an error.
- **`||`, not `??`, for strings that default to empty.** `fontFamily`
  defaults to `""`, which `??` does not catch, so Qt was handed
  `font.family: ""` and fell back to a serif face.
- **`Flickable` + `Text`, not `ScrollView` + `TextEdit`.** A `TextEdit` owns a
  text cursor and scrolls itself to it, and a 34 KB rich-text document
  relayouts after its first pass, so the popup kept opening part-way down the
  second dictionary. Resetting `contentY` raced the relayout. The cost is
  losing mouse selection of the text.
- **Blur needs a `layer_rule` on the namespace.** Without it the translucent
  background is merely see-through and the text behind reads straight through
  the definition, like ghost text. Verified by screenshotting it both ways.
- **Placement is margins, not coordinates.** A layer surface is anchored to an
  edge and pushed in, and those margins are measured from the *usable* area —
  inside whatever the bar reserved — so `dict-popup` computes them against
  hyprctl's `reserved` values, and divides by `scale` because hyprctl reports
  sizes in physical pixels but positions in logical ones.
- **`keyboardFocus: Exclusive` needs a `HyprlandFocusGrab`.** Taking exclusive
  focus is what makes `q` and `Esc` work without the popup being clicked
  first, but on its own it also means the popup *keeps* the keyboard until it
  closes: click back into an editor and type, and the characters went nowhere
  — or onto `q`, which closed it. The grab makes losing the pointer the same
  event as pressing Escape, which is both the fix and the macOS behaviour.
  Hyprland-specific, which is no new constraint: the geometry already comes
  from hyprctl.
- **`Text` defaults to `AutoText`**, which sniffs its content for markup. The
  section labels are set to `PlainText` explicitly — nothing in the data has
  angle brackets today, and this makes sure it could not matter if it did.

### Hyprland 0.55 geometry (terminal backend)

`size` and `move` are muParser expressions, not keywords: `+ - * / ( )`, the
muParser builtins (`min`/`max` matter here), and the variables
`cursor_x`/`cursor_y` (relative to the window's monitor), `monitor_w`/`monitor_h`,
`window_w`/`window_h`. Verified against the 0.55.2 source, not the wiki:

- **`parseExpressionVec2` splits x from y on the first whitespace**, so
  neither half may contain a space: `cursor_x-260`, and `min(a,b)` with
  nothing after the comma.
- **`window_w`/`window_h` do not reflect the `size` rule.**
  `DefaultFloatingAlgorithm.cpp` computes `size` first and comments "update
  for pos to work with size", then writes the result into `m_realPosition`
  rather than `m_realSize` — so at `move` time those variables still hold the
  client's requested size. The module uses literals instead.
- **`move onscreen cursor -50% -50%` is gone**: "onscreen" appears nowhere in
  0.55.2. Staying on screen is the config's job, which is the `min`/`max`
  clamp.

Floating is a precondition, not a preference: the position expression is read
only by the floating layout, and only on a window's first map.

### Not Hyprland's, but worth knowing

- **`hyprctl dispatch closewindow class:…` is dead** under a Lua config:
  hyprctl wraps whatever it is given in `hl.dispatch(...)` and then cannot
  parse it as Lua. "One popup at a time" uses a pidfile in `$XDG_RUNTIME_DIR`
  instead, which needs no compositor API.
- **`${var//[[:space:]]/}` is quadratic.** Using it to test whether a backend
  returned anything cost 2.5s on a 38 KB entry, most of a 4.4s lookup.
  `grep -q '[^[:space:]]'` does it in 2ms.

## Changing things

| Change | To apply |
| --- | --- |
| the shortcut, in `hypr-user.lua` | `hyprctl reload` |
| popup size, colours, font, order, dictionaries | `hms` |
| adding a StarDict dictionary by hand | nothing |
| importing from macOS | `dict-import-macos` |

Geometry is worth checking after a change, since a bad expression fails by
putting the popup somewhere odd rather than by erroring:

```bash
hyprctl layers -j | jq '..|objects|select(.namespace?=="dict-popup")'
```
