#!/usr/bin/env bash
# Checks that the prebuilt sqlite3mc binary and the one compiled from the
# amalgamation agree on the encrypted on-disk format.
#
# The app normally links the prebuilt libsqlite3mc.so that the `sqlite3`
# package downloads; the Flatpak has to compile the same version from source,
# because Flathub builds offline and from source. If the two ever disagree, a
# teacher moving between the AppImage and the Flatpak would find their library
# unopenable — which looks exactly like a lost passphrase.
#
# Writes a database with each build and reads it back with the other, in both
# directions. Run it whenever the sqlite3 dependency or the pinned
# SQLite3 Multiple Ciphers version changes.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

work_dir="$(mktemp -d)"
backup="${work_dir}/pubspec.yaml.orig"
cp pubspec.yaml "${backup}"
trap 'cp "${backup}" "${repo_root}/pubspec.yaml"; rm -rf "${work_dir}"' EXIT

"${repo_root}/tool/fetch_sqlite3mc.sh"

use_prebuilt() { cp "${backup}" pubspec.yaml; }

use_source() {
  cp "${backup}" pubspec.yaml
  grep -q '^      source: sqlite3mc$' pubspec.yaml || {
    echo "pubspec.yaml no longer pins 'source: sqlite3mc'; update this script." >&2
    exit 1
  }
  sed -i 's|^      source: sqlite3mc$|      source: source\n      path: third_party/sqlite3mc/sqlite3mc_amalgamation.c|' pubspec.yaml
}

run() { # run <mode> <db>
  CLASSI_COMPAT_MODE="$1" CLASSI_COMPAT_DB="$2" \
    flutter test --tags cipher-compat --run-skipped test/cipher_compat_test.dart
}

echo "==> source build writes, prebuilt build reads"
use_source
run create "${work_dir}/a.db"
use_prebuilt
run verify "${work_dir}/a.db"

echo "==> prebuilt build writes, source build reads"
use_prebuilt
run create "${work_dir}/b.db"
use_source
run verify "${work_dir}/b.db"

echo
echo "Both sqlite3mc builds read each other's encrypted databases."
