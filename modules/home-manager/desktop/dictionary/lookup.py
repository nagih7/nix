"""Dictionary lookup, with a plain-text and an HTML renderer over one engine.

Why Python and not more shell: the HTML renderer has to parse each backend's
own text format into structure (headword, pronunciation, part of speech,
numbered senses, examples) to get the macOS Look Up typography. That is real
parsing, and doing it in sed would be unreadable and fragile. The plain-text
renderer lives here too so that there is a single implementation of the
lookups rather than two that drift.

Configuration arrives as a JSON file written by the Nix module, so none of the
paths are hardcoded here.

Backends, and what they return:

  wordnet   `wn WORD -over`, plain text. Off by default. The only backend
            that does morphology, so its lemmas can also rescue exact-match
            lookups in the others ("discoveries" -> "discovery") — redundant
            now that every configured dictionary indexes its own inflections.
  dictd     a sorted `.index` of "headword<TAB>offset<TAB>length" (base-64, in
            dictd's own alphabet) beside a `.dict`/`.dict.dz`. `dictzip -S/-E`
            takes those fields verbatim and prints that byte range, so no
            dictd daemon is involved.
  stardict  sdcv, with --json-output rather than its default text, which
            marks the dictionary name and the headword with the same "-->",
            claims "Found 1 items" even under --exact-search, and prints
            "save to cache <path>" on stdout.

Dictionaries converted from macOS return Apple's own HTML, class names and
all, which is the whole reason the HTML renderer can look like the real thing.
Everything else is plain text and gets parsed.
"""

from __future__ import annotations

import functools
import json
import mmap
import os
import re
import subprocess
import sys
from dataclasses import dataclass, field, fields


# --------------------------------------------------------------------------
# config


@dataclass
class Config:
    order: list[str] = field(default_factory=lambda: ["stardict", "wordnet", "dictd"])
    # Substrings matched against each dictionary's own name, in the order they
    # should appear — the equivalent of Dictionary.app's "Drag reference
    # sources into the order you prefer". Backend order alone cannot express
    # this, because the converted macOS dictionaries and the Vietnamese ones
    # are all the same backend (stardict) and still want a defined order.
    # Anything unmatched sorts after everything matched, keeping its relative
    # order.
    dict_order: list[str] = field(default_factory=list)
    # Substring of a dictionary's own name -> the heading to show instead.
    # Dictionary.app does not label a section with the dictionary's title: it
    # shows the language or role — "English", "English Thesaurus",
    # "Vietnamese - English" — where this was printing "New Oxford American
    # Dictionary (en-en)". Longest match wins, so a more specific pattern can
    # sit alongside a general one.
    dict_labels: dict[str, str] = field(default_factory=dict)
    dictd_roots: list[str] = field(default_factory=list)
    stardict_roots: list[str] = field(default_factory=list)
    wordnet: bool = True
    stardict: bool = True
    max_senses: int = 6
    max_entries: int = 2

    @staticmethod
    def load(path: str) -> "Config":
        """Build a Config, ignoring keys this class does not know about.

        A bare ``Config(**data)`` raises TypeError on any unexpected key, and
        the JSON is written by the Nix module — a different file. Adding a
        setting there without adding the field here would turn every lookup
        into "lookup failed", with the traceback only in the popup's log. An
        unknown key is a missing feature, not a reason to stop answering.
        """
        with open(path, encoding="utf-8") as fh:
            data = json.load(fh)

        known = {f.name for f in fields(Config)}
        unknown = sorted(set(data) - known)
        if unknown:
            print(
                f"dict-lookup: ignoring unknown config keys: {', '.join(unknown)}",
                file=sys.stderr,
            )
        return Config(**{k: v for k, v in data.items() if k in known})


@dataclass
class Entry:
    """One dictionary's answer for one spelling."""

    dict_name: str
    word: str
    body: str
    is_html: bool = False


def run(cmd: list[str], stdin: bytes | None = None) -> str:
    """Run a command, returning stdout and swallowing failure.

    Every backend here signals "no result" by printing nothing, or by an exit
    status that also fires for ordinary misses, so failure is never fatal.
    """
    try:
        proc = subprocess.run(
            cmd,
            input=stdin,
            capture_output=True,
            timeout=20,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    return proc.stdout.decode("utf-8", "replace")


# --------------------------------------------------------------------------
# query normalisation


PUNCT_EDGE = re.compile(r"^[^\wÀ-ỹ]+|[^\wÀ-ỹ]+$")


def normalise(raw: str) -> str:
    """One line, no control characters, no edge punctuation.

    The Unicode range in PUNCT_EDGE keeps Vietnamese letters out of the
    "punctuation" class; a plain [^\\w] would strip them under some locales,
    which matters because the Vietnamese dictionaries are the point.
    """
    text = raw.replace("\n", " ").replace("\t", " ").replace("\r", " ")
    text = "".join(ch for ch in text if ch.isprintable())
    text = re.sub(r" {2,}", " ", text).strip()
    return PUNCT_EDGE.sub("", text)


def candidates(word: str) -> list[str]:
    """Spellings to try, best first, deduplicated.

    A selection routinely arrives capitalised or as a phrase when only its
    first word is a headword.
    """
    first = word.split(" ")[0] if " " in word else word
    out: list[str] = []
    for cand in (word, word.lower(), first, first.lower()):
        if cand and cand not in out:
            out.append(cand)
    return out


# --------------------------------------------------------------------------
# backends


SENSE_RE = re.compile(r"^(\d+)\.\s+(?:\(\d+\)\s+)?(.*)$")
OVERVIEW_RE = re.compile(r"^Overview of (\w+) (.+)$")


@functools.lru_cache(maxsize=64)
def wordnet_raw(word: str) -> str:
    """`wn WORD -over`, cached for the life of the process.

    Called twice for the same word on a normal lookup — once by
    `wordnet_lemmas`, to rescue the exact-match backends, and once by
    `lookup_wordnet` for the entry itself — and `wordnet_lemmas` runs per
    candidate spelling. One `wn` process each time, for identical output.
    """
    return run(["wn", word, "-over"])


def wordnet_lemmas(word: str) -> list[str]:
    """WordNet's own morphology, read back out of its output.

    `wn discoveries -over` prints "Overview of noun discovery". Multi-word
    entries come back joined with underscores ("red_herring"), which no other
    dictionary spells that way.
    """
    lemmas: list[str] = []
    for line in wordnet_raw(word).splitlines():
        m = OVERVIEW_RE.match(line.strip())
        if m:
            lemma = m.group(2).replace("_", " ").strip()
            if lemma and lemma not in lemmas:
                lemmas.append(lemma)
    return lemmas


def lookup_wordnet(word: str, cfg: Config) -> list[Entry]:
    text = wordnet_raw(word)
    if not text.strip():
        return []

    blocks: list[str] = []
    senses = 0
    for line in text.splitlines():
        line = line.rstrip()
        stripped = line.strip()
        m = OVERVIEW_RE.match(stripped)
        if m:
            senses = 0
            blocks.append(f"\x00{m.group(1)}\x00{m.group(2).replace('_', ' ')}")
            continue
        m = SENSE_RE.match(stripped)
        if m:
            senses += 1
            if senses <= cfg.max_senses:
                blocks.append(f"{m.group(1)}. {m.group(2)}")
    if not blocks:
        return []
    return [Entry("WordNet", word, "\n".join(blocks))]


B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"


def _headword_at(mm: mmap.mmap, start: int) -> bytes:
    """The first tab-delimited field of the line beginning at `start`."""
    end = mm.find(b"\t", start)
    if end < 0:
        end = mm.find(b"\n", start)
    if end < 0:
        end = len(mm)
    return mm[start:end]


def _index_bisect(mm: mmap.mmap, word: bytes) -> int:
    """Offset of the first line whose headword is >= `word`.

    A dictd `.index` is sorted by headword, which is what makes the format
    usable at all — dictd's own client binary-searches it rather than reading
    it. This did read it: 8.0M lines and 172 MB for wiktionary-en, scanned
    from the top for every candidate spelling, which cost 1.8s on a paragraph
    selection (three misses) and a 172 MB read cold.

    Two things the comparison has to get right. It is on the *first field*
    only: whole lines are not ordered, because entries sharing a headword
    leave the base-64 offset column in arbitrary order (`sort -c` on the whole
    file fails at line 2 for exactly that reason). And it is a byte
    comparison, matching how the file is sorted rather than any locale —
    verified over the whole index with:

        cut -f1 wiktionary-en.index | LC_ALL=C sort -c

    Worth re-running when adding a dictd database: a case-insensitively
    sorted index would make this miss silently. `candidates()` already tries
    both cases, so each spelling is its own bisect.
    """
    lo, hi = 0, len(mm)
    # Invariant: lo is the start of a line, hi is a line start or EOF.
    while lo < hi:
        mid = (lo + hi) // 2
        start = mm.rfind(b"\n", 0, mid) + 1
        if start < lo:
            # mid fell inside the line that begins before the window.
            start = lo
        if _headword_at(mm, start) < word:
            nl = mm.find(b"\n", start)
            if nl < 0:
                return len(mm)
            lo = nl + 1
        else:
            hi = start
    return lo


def _index_matches(path: str, word: bytes, limit: int) -> list[list[bytes]]:
    """Up to `limit` index lines whose headword is exactly `word`, split."""
    out: list[list[bytes]] = []
    with open(path, "rb") as fh:
        if os.fstat(fh.fileno()).st_size == 0:
            return out
        mm = mmap.mmap(fh.fileno(), 0, access=mmap.ACCESS_READ)
        try:
            pos = _index_bisect(mm, word)
            while pos < len(mm) and len(out) < limit:
                nl = mm.find(b"\n", pos)
                end = len(mm) if nl < 0 else nl
                line = mm[pos:end]
                parts = line.split(b"\t")
                if parts[0] != word:
                    break
                if len(parts) >= 3:
                    out.append(parts)
                if nl < 0:
                    break
                pos = nl + 1
        finally:
            mm.close()
    return out


def lookup_dictd(word: str, cfg: Config) -> list[Entry]:
    entries: list[Entry] = []
    for root in cfg.dictd_roots:
        if not os.path.isdir(root):
            continue
        for name in sorted(os.listdir(root)):
            if not name.endswith(".index"):
                continue
            base = os.path.join(root, name[: -len(".index")])
            dictfile = next(
                (p for p in (base + ".dict.dz", base + ".dict") if os.path.exists(p)),
                None,
            )
            if dictfile is None:
                continue

            title = os.path.basename(base)
            # Compared as bytes and exactly: the headword came from a mouse
            # selection, so it must never be treated as a pattern.
            try:
                matches = _index_matches(
                    base + ".index", word.encode("utf-8"), cfg.max_entries
                )
            except (OSError, ValueError):
                # ValueError: mmap of a file that changed size under us.
                continue
            for parts in matches:
                start, size = parts[1].decode(), parts[2].decode()
                body = run(["dictzip", "-c", "-d", "-S", start, "-E", size, dictfile])
                # The entry repeats its own headword on line 1.
                body = "\n".join(body.splitlines()[1:])
                if body.strip():
                    entries.append(Entry(title, word, body))
    return entries


def lookup_stardict(word: str, cfg: Config) -> list[Entry]:
    """sdcv, once per root because --data-dir takes a single directory.

    Exact matching only: sdcv's fuzzy search answers with edit-distance
    neighbours, which is worse than nothing in a popup. WordNet's lemmas cover
    the inflected cases instead.
    """
    # Gated: with wordnet off, `wn` is not on PATH either, so this would
    # spawn a process per candidate to fail silently. The lemmas are a rescue
    # for dictionaries that do not index their own inflections — which the
    # macOS ones do, in their `.syn` files.
    tries = [word]
    if cfg.wordnet:
        tries += [lemma for lemma in wordnet_lemmas(word) if lemma != word]
    entries: list[Entry] = []

    for root in cfg.stardict_roots:
        if not os.path.isdir(root):
            continue
        for attempt in tries:
            out = run(
                [
                    "sdcv",
                    "--non-interactive",
                    "--json-output",
                    "--utf8-input",
                    "--utf8-output",
                    "--exact-search",
                    "--data-dir",
                    root,
                    "--only-data-dir",
                    "--",
                    attempt,
                ]
            )
            try:
                parsed = json.loads(out) if out.strip() else []
            except json.JSONDecodeError:
                parsed = []
            if not parsed:
                continue
            # Capped per dictionary, not per root: one root can hold several
            # dictionaries (the converted macOS ones all live in one
            # directory) and each deserves its entry, but a single dictionary
            # returning every homograph buries the common sense — Lạc Việt
            # answers "application" twice.
            seen: dict[str, int] = {}
            for item in parsed:
                name = item.get("dict", root).strip()
                seen[name] = seen.get(name, 0) + 1
                if seen[name] > cfg.max_entries:
                    continue
                body = item.get("definition", "")
                entries.append(
                    Entry(
                        name,
                        item.get("word", attempt),
                        body,
                        is_html=looks_like_html(body),
                    )
                )
            break
    return entries


def looks_like_html(text: str) -> bool:
    head = text.lstrip()[:200].lower()
    return "<!doctype html" in head or "<html" in head or "<span" in head


def _rank(name: str, dict_order: list[str]) -> int:
    for i, pattern in enumerate(dict_order):
        if pattern.lower() in name.lower():
            return i
    return len(dict_order)


def collect(word: str, cfg: Config) -> list[Entry]:
    out: list[Entry] = []
    for backend in cfg.order:
        if backend == "wordnet" and cfg.wordnet:
            out += lookup_wordnet(word, cfg)
        elif backend == "stardict" and cfg.stardict:
            out += lookup_stardict(word, cfg)
        elif backend == "dictd":
            out += lookup_dictd(word, cfg)

    if cfg.dict_order:
        # Stable, so entries from one dictionary keep the order the backend
        # returned them in (its homographs stay in sequence).
        out.sort(key=lambda e: _rank(e.dict_name, cfg.dict_order))

    # Renamed after sorting and after dict_order has done its work, so the
    # order still keys off the real dictionary names rather than the labels.
    if cfg.dict_labels:
        for entry in out:
            entry.dict_name = label_for(entry.dict_name, cfg)
    return out


def label_for(name: str, cfg: Config) -> str:
    """The heading to show for a dictionary, per `dict_labels`."""
    best = ""
    for pattern, label in cfg.dict_labels.items():
        if pattern.lower() in name.lower() and len(pattern) > len(best):
            best, chosen = pattern, label
    return chosen if best else name


def lookup(raw: str, cfg: Config) -> tuple[str, list[Entry]]:
    word = normalise(raw)
    if not word:
        return "", []
    for cand in candidates(word):
        entries = collect(cand, cfg)
        if entries:
            return cand, entries
    return word, []
