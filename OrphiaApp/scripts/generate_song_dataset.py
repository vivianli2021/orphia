#!/usr/bin/env python3
"""Regenerates Orphia/Models/SongCatalogData.swift from the full
design/song-library-by-age-decade.csv dataset.

Run from the repo root (CongressionalAppChallenge/):
    python3 OrphiaApp/scripts/generate_song_dataset.py

Why this exists: the app's song library used to be a small, hand-curated
18-song subset (2 per genre, one fixed age bracket). Residents should see
every song in their own age bracket's genre, not a hand-picked sample, so
this script ports the whole CSV into Swift instead of us hand-transcribing
it (error-prone at 250+ rows).
"""
import csv
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SRC = REPO_ROOT / "design" / "song-library-by-age-decade.csv"
OUT = REPO_ROOT / "OrphiaApp" / "Orphia" / "Models" / "SongCatalogData.swift"

BRACKET_MAP = {
    "50s": "fifties",
    "60s": "sixties",
    "70s": "seventies",
    "80s": "eighties",
    "90s": "nineties",
    "100+": "hundredPlus",
}

GENRE_MAP = {
    "Classical": "classical",
    "Jazz & Blues": "jazzBlues",
    "Oldies & Rock 'n' Roll": "oldiesRock",
    "Pop": "pop",
    "Country & Folk": "countryFolk",
    "Gospel & Hymns": "gospelHymns",
    "Broadway & Musical Theater": "broadway",
    "Big Band & Swing": "bigBandSwing",
    "R&B & Soul": "rbSoul",
}

ANNOTATION_RE = re.compile(r"\s\(([a-z].*)\)\s*$")


def strip_annotation(s: str) -> str:
    """Strips a trailing ' (...)' whose contents start lowercase — these are
    curator notes glued onto the CSV's Genre/Title/Year fields (e.g.
    "Oldies & Rock 'n' Roll (pre-rock'n'roll precursor)" or "1939 (legacy
    classic, predates generation)"), not part of the real value. A
    capitalized parenthetical like "(Oklahoma!)" or "(Mama)" is left alone
    since that IS part of the real title.
    """
    m = ANNOTATION_RE.search(s)
    if m:
        return s[: m.start()].rstrip()
    return s.strip()


def swift_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def youtube_id(url: str) -> str:
    m = re.search(r"[?&]v=([A-Za-z0-9_-]{6,})", url)
    if not m:
        raise ValueError(f"no video id found in {url!r}")
    return m.group(1)


def main() -> None:
    rows_by_bracket: dict[str, list[dict]] = {b: [] for b in BRACKET_MAP.values()}

    with SRC.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            bracket_raw = row["Age Bracket"].strip()
            if not bracket_raw:
                continue
            bracket = BRACKET_MAP[bracket_raw]

            genre_raw = strip_annotation(row["Genre"].strip())
            genre = GENRE_MAP[genre_raw]

            title = strip_annotation(row["Song Title"].strip())
            artist = row["Artist / Composer"].strip()
            year = strip_annotation(row["Year"].strip())
            vid = youtube_id(row["YouTube Link"].strip())

            rows_by_bracket[bracket].append(
                {"genre": genre, "id": vid, "title": title, "artist": artist, "year": year}
            )

    lines: list[str] = []
    lines.append("// GENERATED FILE — do not hand-edit.")
    lines.append("// Regenerate with: python3 OrphiaApp/scripts/generate_song_dataset.py")
    lines.append(f"// Source: design/{SRC.name}")
    lines.append("")
    lines.append("struct CatalogRow {")
    lines.append("    let bracket: AgeBracket")
    lines.append("    let song: Song")
    lines.append("}")
    lines.append("")

    var_names: list[str] = []
    for bracket_name, entries in rows_by_bracket.items():
        var_name = f"{bracket_name}Rows"
        var_names.append(var_name)
        lines.append(f"private let {var_name}: [CatalogRow] = [")
        for e in entries:
            title_s = swift_escape(e["title"])
            artist_s = swift_escape(e["artist"])
            year_s = swift_escape(e["year"])
            lines.append(
                f'    CatalogRow(bracket: .{bracket_name}, song: Song(id: "{e["id"]}", '
                f'title: "{title_s}", artist: "{artist_s}", genre: .{e["genre"]}, '
                f'yearLabel: "{year_s}")),'
            )
        lines.append("]")
        lines.append("")

    lines.append("let allCatalogRows: [CatalogRow] = " + " + ".join(var_names))
    lines.append("")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")

    total = sum(len(v) for v in rows_by_bracket.values())
    print(f"Wrote {OUT.relative_to(REPO_ROOT)} — {total} rows across {len(rows_by_bracket)} brackets")
    for b, entries in rows_by_bracket.items():
        by_genre = {}
        for e in entries:
            by_genre[e["genre"]] = by_genre.get(e["genre"], 0) + 1
        print(f"  {b}: {len(entries)} total — " + ", ".join(f"{g}={n}" for g, n in by_genre.items()))


if __name__ == "__main__":
    main()
