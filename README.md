# Classi

<img src=".github/logo.png" alt="Classi logo" width="120" />

Classi is a local-first Flutter app for teachers. It stores groups, students,
grades, notes, checklists, and material tracking data in encrypted `.classi`
libraries, with portable `.classi-backup` export/import for sync.

## Initial release

This first release focuses on the local-first teaching workflow:

- encrypted local libraries with passphrase setup and recovery key support
- groups, students, notes, checklists, homework, and material tracking
- grade entry with configurable systems and chart-based history
- Android, macOS, Windows, and Linux desktop support
- GitHub Actions for CI and release artifact builds

## Supported platforms

- Android
- macOS
- Windows
- Linux

## Implemented foundation

- SQLCipher-backed Drift database with the planned seven-table schema
- First-run passphrase setup with secure storage
- Adaptive navigation for groups, notes, and settings
- Working groups and students flow, including archive, unarchive, and clone
- Batch student creation and WebUntis class-list import
- Grade entry, chart-based grade history, checklist management, note management,
  material tracking, and delete actions for student history items
- Avatar editing powered by `avatar_maker`, persisted per student in the local
  database
- English and German translations through `easy_localization`

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

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, pull request
expectations, and release hygiene.

## GitHub Actions

Three workflows are included:

- `ci.yml` — runs on every push to `main`/`master` and on pull requests. It
  installs dependencies, runs Drift code generation, analyzes the code, and
  executes the test suite.
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
- `release.yml` — triggered by version tags (`v*`). It generates a changelog
  with `git-cliff`, commits an updated `CHANGELOG.md`, builds release artifacts
  for Android (APK), Linux (AppImage), macOS (DMG), and Windows (EXE installer)
  using [Fastforge](https://fastforge.dev/), and publishes a GitHub Release with
  all artifacts attached.

The Android release build currently uses the debug signing config, which keeps
CI buildable out of the box. Replace that with your real signing setup before
shipping to users.

## License

Released under the [MIT License](LICENSE).
