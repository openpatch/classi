# Classi

<img src=".github/logo.png" alt="Classi logo" width="120" />

Classi is a local-first Flutter app for teachers. It stores groups, students,
grades, notes, checklists, and material tracking data in encrypted `.classi`
libraries. Automatic backup and restore to a WebDAV server keeps your data safe
and portable across devices.

## Supported platforms

- Android
- macOS
- Windows
- Linux

## Features

- SQLCipher-backed Drift database with passphrase setup and recovery key support
- Adaptive navigation for groups, notes, and settings
- Groups and students flow, including archive, unarchive, clone, and deletion
- Batch student creation and WebUntis class-list import
- Grade entry, chart-based grade history, checklist management, note management,
  and material tracking
- Avatar editing powered by `avatar_maker`, persisted per student in the local
  database, plus a browser [Avatar Designer](#avatar-designer) that lets students
  build their own avatar and hand you a short code
- WebDAV backup with automatic upload on lock and automatic restore on startup
- Configurable light, dark, and system theme
- Auto-update for desktop platforms (macOS, Windows, Linux) via the `updat` package
- English and German translations through `easy_localization`

## Data storage

Classi stores your library in a `.classi` folder. Library-specific settings
such as grade systems, sorting, theme, lock, and WebDAV backup configuration
are stored inside that `.classi` folder too, so they move with the project
instead of being kept as global app preferences.

On **desktop**, the first-run setup requires an explicit folder selection so
your data is never silently placed inside an app-private directory. On
**Android**, scoped storage forbids raw file access to folders you pick in
shared storage, so libraries are always created in Classi's app-specific
storage directory (`Android/data/<package>/files/Classi`). This directory is
removed when the app is uninstalled — configure a WebDAV backup to keep a
restorable copy.

**Recommended locations:**

| Platform | Recommended folder |
|---|---|
| Android | Fixed to Classi's app storage; use WebDAV backup for portability |
| macOS (App Store) | `~/Documents/Classi` or another location outside `~/Library/Containers/` |
| macOS / Windows / Linux | Any folder in your home directory or an accessible drive |

### WebDAV backups

Classi can automatically back up your library to any WebDAV server (e.g.
Nextcloud, ownCloud, or a self-hosted server). Configure the server URL,
credentials, and remote folder path in **Settings → Backups**. Once saved:

- **Auto-export** uploads a `.classi-backup` archive whenever Classi locks or
  switches libraries.
- **Auto-import** checks for a newer backup on startup and offers to restore it.

You can also trigger a manual restore from the setup screen by choosing
*Restore from WebDAV backup*.

## Avatar Designer

The Avatar Designer is a standalone Flutter web app (a second entry point in this
repo, `lib/avatar_designer/`) that students open in a browser at
<https://classi.openpatch.org/avatar/>. They design an avatar with the same
`avatar_maker` customizer used in the app, press **Create code**, and hand you a
short code like `AV1-XXXX-XXXX-XX`. In Classi, open a student's avatar editor and
choose **Enter code** to load and save it.

The code encodes only the avatar selections (no personal data). It is tied to the
`avatar_maker` version bundled here; a code made with a mismatched version is
rejected with a clear message rather than applied incorrectly.

Run it locally:

```bash
flutter run -d chrome -t lib/avatar_designer/main.dart
```

Build for hosting (served at `/avatar/` on classi.openpatch.org):

```bash
flutter build web --release \
  --target lib/avatar_designer/main.dart \
  --base-href /avatar/ \
  --pwa-strategy=none
```

Pushes to `main` that touch the designer are published automatically by the
`deploy-site.yml` workflow (see [GitHub Actions](#github-actions)).

## Website

<https://classi.openpatch.org> is a static landing page kept in `site/`
(`index.html`, `styles.css`, `main.js`, `CNAME`). It is bilingual: German is
authored inline and English lives in `data-en*` attributes that `main.js` swaps
in, defaulting to the browser language and remembering the choice. Direct
download links and the version line are filled in at runtime from the GitHub
releases API, so the page never has to be edited for a release; without that
request every button still falls back to the releases page.

`tool/build_site.sh [OUTDIR] [DESIGNER_BUILD_DIR]` assembles the deployable
tree. It copies the logo and the screenshots from the places that already own
them — `.github/logo.png`, the AppStream screenshots in
`linux/packaging/screenshots/`, and the Play Store phone screenshots — so the
site cannot drift from the store listings. Passing the designer build directory
places it at `OUTDIR/avatar`.

Preview it locally:

```bash
tool/build_site.sh build/site
python3 -m http.server 8000 --directory build/site
```

## Local development

Linux desktop builds need native packages installed first:

```bash
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev libssl-dev
```

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d android
flutter run -d macos
flutter run -d windows
flutter run -d linux
```

macOS desktop builds require Xcode on a Mac with command-line tools installed.

## Release builds

Releases are packaged with [Fastforge](https://fastforge.dev/):

```bash
dart pub global activate fastforge
fastforge package --platform android --targets apk
fastforge package --platform linux   --targets appimage
fastforge package --platform macos   --targets dmg
fastforge package --platform windows --targets exe
```

Or run all platforms at once using the project release config:

```bash
fastforge release --name release
```

## Store metadata

`fastlane/metadata/android/` holds the store listing — title, descriptions,
icon, phone screenshots and one release-notes file per version code
(`en-US/changelogs/46.txt` belongs to the build whose `version_code.txt` said
`46`). F-Droid reads this tree straight from the repository; the Play Store
gets it from the `release.yml` workflow via `fastlane supply`.

The tree is authored for F-Droid, which accepts anything. Google Play does not:
release notes are capped at 500 characters, screenshots may not have an alpha
channel, and their longest side may be at most twice the shortest — the
1080x2424 phone screenshots here are 1:2.24 and would be rejected. Rather than
degrade the F-Droid assets, `tool/prepare_play_metadata.py` writes a normalised
copy that only Play sees:

```bash
python3 tool/prepare_play_metadata.py fastlane/metadata/android build/play-metadata
```

It trims release notes on a bullet boundary, drops the alpha channel and
letterboxes screenshots by repeating their edge pixels (so padding continues
the app bar instead of adding black bars), and fails loudly on anything
hand-written that Play would reject, such as a title over 30 characters.

Because the whole tree is uploaded on every release, the repository is the
source of truth: edits made directly in the Play Console are overwritten on the
next tag. To see what would be sent without committing anything to Play, add
`--validate_only true`:

```bash
fastlane supply --package_name org.openpatch.classi \
  --metadata_path build/play-metadata \
  --skip_upload_aab true --skip_upload_apk true --skip_upload_changelogs true \
  --json_key playstore-credentials.json --validate_only true
```

(Release notes are skipped there because they attach to a release that only
exists once the bundle is uploaded.)

German release notes fall back to `de-DE/changelogs/default.txt`, since the
generated changelog is English only. Add `de-DE/changelogs/<version code>.txt`
to give a release proper German notes.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, pull request
expectations, and release hygiene.

## GitHub Actions

Five workflows are included:

- `ci.yml` — runs on every push to `main`/`master` and on pull requests. It
  installs dependencies, runs Drift code generation, analyzes the code, and
  executes the test suite.
- `deploy-site.yml` — on pushes to `main` that touch the [website](#website) or
  the [Avatar Designer](#avatar-designer), builds the designer, assembles the
  site with `tool/build_site.sh` and deploys it to GitHub Pages as
  classi.openpatch.org — the landing page at `/`, the designer at `/avatar/`.
  Requires **Settings → Pages → Source: GitHub Actions** to be enabled once, and
  a `CNAME` DNS record pointing `classi.openpatch.org` at `openpatch.github.io`.
- `build-pr.yml` — triggered by posting a slash command as a comment on any pull
  request. Supported commands:
  - `/build android` — builds and uploads an APK
  - `/build linux` — builds and uploads an AppImage
  - `/build macos` — builds and uploads a DMG
  - `/build windows` — builds and uploads an EXE installer

  Only the requested platform is built using [Fastforge](https://fastforge.dev/).
  Once the artifact is uploaded the workflow replies directly on the pull request
  with a link to download the artifact.

  Android PR builds use the application ID `org.openpatch.classi.pr` so they
  can be installed alongside the production app without overwriting it.
- `changelog.yml` — on every push to `main`, regenerates the unreleased section
  with `git-cliff` into `fastlane/metadata/android/en-US/changelogs/<next
  version code>.txt` and commits it, so the next release already carries its
  notes for both stores. See [Store metadata](#store-metadata).
- `release.yml` — triggered by version tags (`v*`). It generates a changelog
  with `git-cliff`, commits an updated `CHANGELOG.md`, builds release artifacts
  for Android (APK and AAB), Linux (AppImage), macOS (DMG), and Windows (EXE
  installer) using [Fastforge](https://fastforge.dev/), publishes a GitHub
  Release with all artifacts attached, and uploads the AAB to the Play Store
  production track together with the
  [store metadata](#store-metadata) using `fastlane supply`.

## Development support

Classi is developed with support from Claude Opus 5.

## License

Released under the [MIT License](LICENSE).
