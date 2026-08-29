#!/usr/bin/env python3
"""Build a Google-Play-ready copy of the fastlane metadata tree.

`fastlane/metadata/android` is authored for F-Droid, which accepts whatever it
is given. Google Play does not: it rejects release notes over 500 characters,
screenshots whose longest side is more than twice the shortest, and screenshots
carrying an alpha channel. The phone screenshots in this repo are 1080x2424
(1:2.24), so handing the tree to `fastlane supply` unchanged fails the upload.

Rather than degrade the F-Droid assets to Play's lowest common denominator,
this writes a normalised copy that `supply --metadata_path` consumes:

  * release notes are trimmed to 500 characters on a line/word boundary,
  * screenshots are flattened to RGB and letterboxed (never cropped) by
    repeating their edge pixels until the aspect ratio is within Play's 2:1
    limit,
  * oversized screenshots are scaled down under Play's 3840 px ceiling.

Anything hand-written that Play would reject is an error rather than a silent
fix, because a truncated store title or a dropped screenshot should be a human
decision.

Usage:
    tool/prepare_play_metadata.py SOURCE_DIR OUTPUT_DIR

SOURCE_DIR and OUTPUT_DIR are both the directory that holds the locale folders,
i.e. `fastlane/metadata/android`.
"""

from __future__ import annotations

import argparse
import math
import shutil
import sys
from pathlib import Path

from PIL import Image

# https://support.google.com/googleplay/android-developer/answer/9859455
MAX_TITLE = 30
MAX_SHORT_DESCRIPTION = 80
MAX_FULL_DESCRIPTION = 4000
MAX_RELEASE_NOTES = 500

# https://developers.google.com/android-publisher/api-ref/rest/v3/AppImageType
MIN_SIDE = 320
MAX_SIDE = 3840
MAX_RATIO = 2.0
MAX_SCREENSHOTS_PER_TYPE = 8

TEXT_LIMITS = {
    "title": MAX_TITLE,
    "short_description": MAX_SHORT_DESCRIPTION,
    "full_description": MAX_FULL_DESCRIPTION,
}
# `video` holds a URL, so it has no length limit worth enforcing here.
TEXT_FILES = list(TEXT_LIMITS) + ["video"]

IMAGE_TYPES = {
    "featureGraphic": (1024, 500),
    "icon": (512, 512),
    "tvBanner": (1280, 720),
}
SCREENSHOT_TYPES = [
    "phoneScreenshots",
    "sevenInchScreenshots",
    "tenInchScreenshots",
    "tvScreenshots",
    "wearScreenshots",
]
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg"}

warnings: list[str] = []
errors: list[str] = []


def trim_release_notes(text: str) -> str:
    """Cuts release notes to Play's 500-character limit at a readable boundary.

    git-cliff writes one bullet per commit, so a busy release overshoots easily.
    Cutting at the last newline keeps whole bullets; a section header left with
    no bullets under it is then dropped, since a trailing "Features" reads as a
    rendering bug rather than as a truncated list.
    """
    text = text.strip()
    if len(text) <= MAX_RELEASE_NOTES:
        return text

    head = text[:MAX_RELEASE_NOTES]
    for boundary in ("\n", " "):
        cut = head.rfind(boundary)
        # Refuse a boundary that throws away most of the budget; a hard cut of
        # 500 readable characters beats 40 tidy ones.
        if cut > MAX_RELEASE_NOTES // 2:
            head = head[:cut]
            break

    lines = head.rstrip().splitlines()
    while lines and not lines[-1].startswith("- "):
        lines.pop()
    return "\n".join(lines).rstrip() or head.rstrip()


def letterbox(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """Centres the image on a larger canvas, filling the margins by stretching
    the outermost row/column of pixels outwards.

    A flat fill colour would put black bars beside a coloured app bar. Repeating
    the edge pixels instead continues whatever is already there, so the padding
    reads as part of the screenshot rather than as a border around it.
    """
    width, height = image.size
    target_width, target_height = size
    canvas = Image.new("RGB", size)
    left, top = (target_width - width) // 2, (target_height - height) // 2
    canvas.paste(image, (left, top))

    if left > 0:
        right = target_width - width - left
        canvas.paste(image.crop((0, 0, 1, height)).resize((left, height)), (0, top))
        canvas.paste(
            image.crop((width - 1, 0, width, height)).resize((right, height)),
            (left + width, top),
        )

    # Read the rows back off the canvas rather than off the image, so that a
    # canvas needing both directions gets corners filled instead of left black.
    if top > 0:
        bottom = target_height - height - top
        first = canvas.crop((0, top, target_width, top + 1))
        last = canvas.crop((0, top + height - 1, target_width, top + height))
        canvas.paste(first.resize((target_width, top)), (0, 0))
        canvas.paste(last.resize((target_width, bottom)), (0, top + height))

    return canvas


def normalise_screenshot(source: Path, destination: Path) -> None:
    with Image.open(source) as opened:
        image = opened.convert("RGB")  # Play rejects an alpha channel.

        width, height = image.size
        if min(width, height) < MIN_SIDE:
            errors.append(
                f"{source}: {width}x{height} is below Play's {MIN_SIDE} px minimum side"
            )
            return

        if max(width, height) > MAX_SIDE:
            scale = MAX_SIDE / max(width, height)
            width, height = round(width * scale), round(height * scale)
            image = image.resize((width, height), Image.LANCZOS)
            warnings.append(f"{source}: scaled down to {width}x{height}")

        # Letterbox instead of cropping: losing a row of the screenshot is a
        # worse outcome than a strip of the app's own background colour.
        target_width = max(width, math.ceil(height / MAX_RATIO))
        target_height = max(height, math.ceil(width / MAX_RATIO))
        if (target_width, target_height) != (width, height):
            image = letterbox(image, (target_width, target_height))
            warnings.append(
                f"{source}: padded {width}x{height} to {target_width}x{target_height} "
                f"for Play's {MAX_RATIO:g}:1 aspect ratio limit"
            )

        destination.parent.mkdir(parents=True, exist_ok=True)
        image.save(destination, "PNG")


def copy_text_files(locale_dir: Path, out_locale: Path) -> None:
    for name in TEXT_FILES:
        source = locale_dir / f"{name}.txt"
        if not source.exists():
            continue
        text = source.read_text(encoding="utf-8").strip()
        limit = TEXT_LIMITS.get(name)
        if limit and len(text) > limit:
            errors.append(
                f"{source}: {len(text)} characters exceeds Play's {limit}-character limit"
            )
            continue
        (out_locale / f"{name}.txt").write_text(text + "\n", encoding="utf-8")


def copy_changelogs(locale_dir: Path, out_locale: Path) -> None:
    source_dir = locale_dir / "changelogs"
    if not source_dir.is_dir():
        return
    out_dir = out_locale / "changelogs"
    out_dir.mkdir(parents=True, exist_ok=True)
    for source in sorted(source_dir.glob("*.txt")):
        text = source.read_text(encoding="utf-8")
        trimmed = trim_release_notes(text)
        if len(trimmed) < len(text.strip()):
            warnings.append(
                f"{source}: trimmed from {len(text.strip())} to {len(trimmed)} characters"
            )
        (out_dir / source.name).write_text(trimmed + "\n", encoding="utf-8")


def copy_images(locale_dir: Path, out_locale: Path) -> None:
    source_dir = locale_dir / "images"
    if not source_dir.is_dir():
        return

    for image_type, expected_size in IMAGE_TYPES.items():
        matches = [
            path
            for path in sorted(source_dir.iterdir())
            if path.stem == image_type and path.suffix.lower() in IMAGE_SUFFIXES
        ]
        for source in matches:
            with Image.open(source) as image:
                if image.size != expected_size:
                    errors.append(
                        f"{source}: {image.size[0]}x{image.size[1]} but Play requires "
                        f"{expected_size[0]}x{expected_size[1]} for {image_type}"
                    )
                    continue
            destination = out_locale / "images" / source.name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)

    for screenshot_type in SCREENSHOT_TYPES:
        type_dir = source_dir / screenshot_type
        if not type_dir.is_dir():
            continue
        sources = sorted(
            path for path in type_dir.iterdir() if path.suffix.lower() in IMAGE_SUFFIXES
        )
        if len(sources) > MAX_SCREENSHOTS_PER_TYPE:
            errors.append(
                f"{type_dir}: {len(sources)} screenshots but Play accepts at most "
                f"{MAX_SCREENSHOTS_PER_TYPE}"
            )
            continue
        for source in sources:
            out_name = source.with_suffix(".png").name
            normalise_screenshot(source, out_locale / "images" / screenshot_type / out_name)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="fastlane/metadata/android")
    parser.add_argument("output", type=Path, help="where to write the Play-ready copy")
    args = parser.parse_args()

    if not args.source.is_dir():
        print(f"ERROR: {args.source} is not a directory", file=sys.stderr)
        return 1

    if args.output.exists():
        shutil.rmtree(args.output)
    args.output.mkdir(parents=True)

    locales = sorted(
        path for path in args.source.iterdir() if path.is_dir() and not path.name.startswith(".")
    )
    if not locales:
        print(f"ERROR: no locale directories found in {args.source}", file=sys.stderr)
        return 1

    for locale_dir in locales:
        out_locale = args.output / locale_dir.name
        out_locale.mkdir(parents=True, exist_ok=True)
        copy_text_files(locale_dir, out_locale)
        copy_changelogs(locale_dir, out_locale)
        copy_images(locale_dir, out_locale)
        print(f"Prepared {locale_dir.name}")

    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
