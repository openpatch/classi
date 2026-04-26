# Classi

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

```bash
flutter build apk --release
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

## App logos and icons

Replace the platform icon files with your own square logo assets, then rebuild:

- **Android:** `android/app/src/main/res/mipmap-*/ic_launcher.png`
- **Windows:** `windows/runner/resources/app_icon.ico`
- **macOS:** `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png`

For macOS, provide each required size in the app icon set:

- `app_icon_16.png`
- `app_icon_32.png`
- `app_icon_64.png`
- `app_icon_128.png`
- `app_icon_256.png`
- `app_icon_512.png`
- `app_icon_1024.png`

After replacing icons, rebuild the affected platform so the new logo is bundled
into the app artifact.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, pull request
expectations, and release hygiene.

## GitHub Actions

Two workflows are included:

- `ci.yml` runs dependency resolution, Drift code generation, analysis, and
  tests on pushes and pull requests.
- `build.yml` builds release artifacts for Android, macOS, Windows, and Linux,
  then uploads them as workflow artifacts.

The Android release build currently uses the debug signing config, which keeps
CI buildable out of the box. Replace that with your real signing setup before
shipping to users.

## License

Released under the [MIT License](LICENSE).
