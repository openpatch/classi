#!/usr/bin/env python3
"""Insert a <release> entry into the AppStream metainfo.

App stores show the newest <release> description as "What's New", so the
metainfo has to gain an entry per release or the store keeps showing old notes.
Nothing else in the release workflow touches the metainfo, hence this.

Deliberately surgical: it inserts one element and leaves the rest of the file
byte-for-byte alone. (`appstreamcli news-to-metainfo` rewrites the whole file
and drops screenshots, URLs and categories, so it is not usable here.)

Usage:
    tool/add_metainfo_release.py VERSION CHANGELOG_MD METAINFO_XML [--date YYYY-MM-DD]

Re-running for a version that is already present is a no-op, so a re-run of a
release does not duplicate entries.
"""

from __future__ import annotations

import argparse
import datetime
import re
import sys
from xml.sax.saxutils import escape


def bullets(changelog: str) -> list[str]:
    """Pulls the bullet lines out of a git-cliff release body.

    git-cliff emits `- *(scope)* Summary`; the scope is dropped because the
    audience here is users reading a store page, not the commit log.
    """
    items: list[str] = []
    for line in changelog.splitlines():
        line = line.strip()
        if not line.startswith("- "):
            continue
        text = line[2:].strip()
        text = re.sub(r"^\*\(([^)]+)\)\*\s*", "", text)
        text = text.replace("**", "").replace("`", "")
        if text:
            items.append(text)
    return items


def render(version: str, date: str, items: list[str]) -> str:
    body = "\n".join(f"          <li>{escape(i)}</li>" for i in items)
    description = (
        f"      <description>\n        <ul>\n{body}\n        </ul>\n"
        "      </description>\n"
        if items
        else f"      <description>\n        <p>Classi {escape(version)}</p>\n"
        "      </description>\n"
    )
    return (
        f'    <release version="{escape(version)}" date="{date}">\n'
        f"{description}"
        f"    </release>\n"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("version")
    parser.add_argument("changelog")
    parser.add_argument("metainfo")
    parser.add_argument("--date", default=datetime.date.today().isoformat())
    args = parser.parse_args()

    with open(args.metainfo, encoding="utf-8") as handle:
        xml = handle.read()

    if re.search(rf'<release\s+version="{re.escape(args.version)}"', xml):
        print(f"metainfo already has a release for {args.version}; nothing to do")
        return 0

    if "<releases>" not in xml:
        print("ERROR: no <releases> block in the metainfo", file=sys.stderr)
        return 1

    with open(args.changelog, encoding="utf-8") as handle:
        entry = render(args.version, args.date, bullets(handle.read()))

    xml = xml.replace("<releases>\n", f"<releases>\n{entry}", 1)

    with open(args.metainfo, "w", encoding="utf-8") as handle:
        handle.write(xml)

    print(f"Added release {args.version} to {args.metainfo}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
