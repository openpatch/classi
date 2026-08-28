# Flatpak packaging

`org.openpatch.classi.yml` builds Classi as a Flatpak. It is the **development**
manifest — it builds from this checkout and grants the build network access, so
it can be iterated on without first generating an offline source list. Flathub
needs an offline, build-from-source manifest; see [Submitting to
Flathub](#submitting-to-flathub).

## Building locally

```sh
flatpak install flathub org.freedesktop.Platform//25.08 \
  org.freedesktop.Sdk//25.08 org.freedesktop.Sdk.Extension.llvm20//25.08

cd packaging/flatpak
flatpak-builder --force-clean --user --install build org.openpatch.classi.yml
flatpak run org.openpatch.classi
```

`--disable-rofiles-fuse` may be needed on filesystems where the fuse overlay
misbehaves (btrfs, some overlayfs setups).

## The two things that make Flutter awkward here

**Flutter needs clang, the base SDK only has gcc.** Flutter's Linux build
invokes CMake with `CC=clang`/`CXX=clang++` hard-coded
(`flutter_tools/lib/src/linux/build_linux.dart`), and the environment cannot
override it. Hence the `org.freedesktop.Sdk.Extension.llvm20` SDK extension.

**SQLite is normally downloaded, not built.** `pubspec.yaml` pins
`hooks.user_defines.sqlite3.source: sqlite3mc`, which makes the `sqlite3`
package download a prebuilt `libsqlite3mc.so` from GitHub at build time. That
is impossible offline and not allowed on Flathub. The manifest therefore:

1. declares the SQLite3 Multiple Ciphers amalgamation as a pinned, checksummed
   `archive` source, and
2. rewrites `pubspec.yaml` to `source: source` so the hook compiles it instead.

The compiled library must produce **the same encrypted on-disk format** as the
prebuilt one, or a teacher moving between the AppImage and the Flatpak would
find their library unopenable — which looks exactly like a forgotten
passphrase. `tool/check_cipher_compat.sh` writes a database with each build and
reads it back with the other, in both directions. Run it whenever the `sqlite3`
dependency changes:

```sh
./tool/check_cipher_compat.sh
```

If it fails, do not ship the Flatpak until the versions are realigned.

### Keeping the version pins in step

Three places name the same SQLite3 Multiple Ciphers version, and they must
agree:

| Where | What |
| --- | --- |
| `~/.pub-cache/.../sqlite3-<v>/CHANGELOG.md` | the version the prebuilt ships |
| `tool/fetch_sqlite3mc.sh` | version, SQLite version, sha256 |
| `packaging/flatpak/org.openpatch.classi.yml` | archive URL + sha256 |

To bump: read the `sqlite3` package changelog for the "SQLite3 Multiple
Ciphers" version, find the matching `v<version>` release on
[SQLite3MultipleCiphers](https://github.com/utelle/SQLite3MultipleCiphers/releases),
take the `-amalgamation.zip` checksum from that release's `SHA256SUMS`, update
both files, then run `tool/check_cipher_compat.sh`.

## Self-updates are compiled out

Flathub delivers updates, and a self-updater would at best do nothing inside
the sandbox. The build passes `--dart-define=CLASSI_DISABLE_SELF_UPDATE=true`,
which turns off `supportsSelfUpdate` and removes both the update checker and
the update section in Settings.

## Permissions, and why

| Permission | Reason |
| --- | --- |
| `--share=ipc`, `--socket=wayland`, `--socket=fallback-x11`, `--device=dri` | Drawing the window. |
| `--share=network` | WebDAV backup and restore, to a server the teacher configures. |
| `--talk-name=org.freedesktop.secrets` | `flutter_secure_storage` keeps the WebDAV password and the biometric-unlock passphrase in the Secret Service. |
| `--filesystem=xdg-documents` | Libraries default to `~/Documents/Classi`. Without it the app cannot create or reopen its own default library, and users coming from the AppImage would not find their existing one. Libraries elsewhere go through the file chooser portal, so nothing broader is needed. |

## Submitting to Flathub

Not done yet. What remains:

1. **Generate the offline manifest.** Flathub builds with no network, so the
   Flutter SDK and every pub package must be declared sources. Use
   [flatpak-flutter](https://github.com/TheAppgineer/flatpak-flutter), which
   reads `pubspec.lock` and emits `pubspec-sources.json` plus a pinned SDK
   module. The generated manifest must drop the `--share=network` build arg.
2. **Replace the screenshots.** The metainfo currently points at the Android
   phone screenshots so that it validates. Classi is listed as a desktop app;
   capture desktop-sized screenshots and point at those, on a tag (not a
   branch) so the URLs stay stable.
3. **Confirm domain ownership** of `openpatch.org` — the app ID `org.openpatch.classi`
   requires it. Otherwise the ID has to become `io.github.openpatch.classi`,
   which means changing it in `linux/CMakeLists.txt`, the desktop file, the
   metainfo, and this manifest.
4. **Run `flatpak-builder-lint`** over the manifest and the built repo; it
   catches what the Flathub bot will.
5. **Open the PR** against [flathub/flathub](https://github.com/flathub/flathub)
   on a branch named for the app ID, containing the generated manifest.
6. **Add a CI job** that builds the Flatpak, so the `pubspec.yaml` rewrite in
   the manifest cannot rot silently when the hooks block changes.

## Verified so far

- Builds clean against `org.freedesktop.Platform//25.08`.
- `libsqlite3.so` in the bundle reports `SQLite3 Multiple Ciphers 2.5.0` /
  SQLite `3.53.4`, compiled in the sandbox, and exposes the `sqlcipher` cipher
  the app uses.
- Both cipher-compatibility directions pass.
- `appstreamcli validate` passes on the metainfo.
- The app installs, launches, and the exported desktop entry carries the
  correct `Icon=org.openpatch.classi`.
