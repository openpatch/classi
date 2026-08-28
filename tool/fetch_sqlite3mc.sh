#!/usr/bin/env bash
# Fetches the SQLite3 Multiple Ciphers amalgamation so sqlite3 can be built
# from source instead of downloading a prebuilt binary.
#
# Needed for the Flatpak build, which has no network access and must build from
# source. Everything is pinned and checksummed, so running this twice is a
# no-op and a tampered download fails loudly.
#
# The version must match the one the `sqlite3` Dart package ships prebuilt,
# otherwise a library encrypted by one build may not open in the other. See
# packaging/flatpak/README.md for how to check that when bumping.
set -euo pipefail

SQLITE3MC_VERSION="2.5.0"
SQLITE_VERSION="3.53.4"
SHA256="cd3a598b667dea206b6c5319d4ecb9d687ee40565f9fd2ba280d0c2f93790f58"

ARCHIVE="sqlite3mc-${SQLITE3MC_VERSION}-sqlite-${SQLITE_VERSION}-amalgamation.zip"
URL="https://github.com/utelle/SQLite3MultipleCiphers/releases/download/v${SQLITE3MC_VERSION}/${ARCHIVE}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target_dir="${repo_root}/third_party/sqlite3mc"
amalgamation="${target_dir}/sqlite3mc_amalgamation.c"
stamp="${target_dir}/.version"

if [[ -f "${amalgamation}" && -f "${stamp}" ]] &&
  [[ "$(cat "${stamp}")" == "${SQLITE3MC_VERSION}-${SQLITE_VERSION}" ]]; then
  echo "sqlite3mc ${SQLITE3MC_VERSION} already present in ${target_dir}"
  exit 0
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT

echo "Downloading ${ARCHIVE}"
curl -fsSL --retry 3 -o "${work_dir}/${ARCHIVE}" "${URL}"

echo "${SHA256}  ${work_dir}/${ARCHIVE}" | sha256sum --check --status || {
  echo "Checksum mismatch for ${ARCHIVE}" >&2
  exit 1
}

rm -rf "${target_dir}"
mkdir -p "${target_dir}"
unzip -q "${work_dir}/${ARCHIVE}" -d "${target_dir}"
echo "${SQLITE3MC_VERSION}-${SQLITE_VERSION}" >"${stamp}"

echo "sqlite3mc ${SQLITE3MC_VERSION} (SQLite ${SQLITE_VERSION}) ready in ${target_dir}"
