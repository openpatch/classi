#!/usr/bin/env bash
#
# Assemble the classi.openpatch.org site into a directory.
#
#   tool/build_site.sh [OUTDIR] [DESIGNER_BUILD_DIR]
#
# OUTDIR defaults to build/site. When DESIGNER_BUILD_DIR is given (the output of
# `flutter build web --target lib/avatar_designer/main.dart --base-href /avatar/`)
# it is placed at OUTDIR/avatar, where the landing page links to it.
#
# Screenshots and the logo are copied from the places that already own them —
# the AppStream and Play Store metadata — so the site cannot drift from the
# store listings.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="${1:-$repo_root/build/site}"
designer="${2:-}"

rm -rf "$out"
mkdir -p "$out/assets/screenshots"

cp "$repo_root"/site/index.html "$repo_root"/site/styles.css "$repo_root"/site/main.js "$out/"
cp "$repo_root/site/CNAME" "$out/CNAME"

cp "$repo_root/.github/logo.png" "$out/assets/logo.png"

cp "$repo_root/linux/packaging/screenshots/2.png" "$out/assets/screenshots/desktop-timetable.png"
cp "$repo_root/linux/packaging/screenshots/3.png" "$out/assets/screenshots/desktop-settings.png"
cp "$repo_root/linux/packaging/screenshots/1.png" "$out/assets/screenshots/desktop-unlock.png"
cp "$repo_root/fastlane/metadata/android/en-US/images/phoneScreenshots/3.png" \
   "$out/assets/screenshots/phone-group.png"

if [ -n "$designer" ]; then
  if [ ! -d "$designer" ]; then
    echo "ERROR: designer build directory '$designer' does not exist" >&2
    exit 1
  fi
  mkdir -p "$out/avatar"
  cp -R "$designer"/. "$out/avatar/"
fi

echo "Site assembled in $out"
