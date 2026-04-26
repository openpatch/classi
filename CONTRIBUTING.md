# Contributing to Classi

Thanks for contributing to Classi.

## Ground rules

- Keep pull requests focused and easy to review.
- Prefer issues or discussions before large feature or architecture changes.
- Do not commit secrets, signing keys, or personal library data.
- Keep user-facing text in the translation files under
  `assets/translations/`.

## Local setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

For Linux desktop builds, install the native packages listed in `README.md`
first. For macOS builds, use a Mac with Xcode and the command-line tools
installed.

## Development expectations

- Follow the existing Flutter, Riverpod, and Drift patterns in the repo.
- Keep changes local-first and offline-friendly.
- Update tests when behavior changes.
- Update `README.md` when platform support, build steps, or release-facing
  behavior changes.

## Pull requests

Before opening a pull request:

1. Run `flutter analyze`.
2. Run `flutter test`.
3. Regenerate code with `dart run build_runner build --delete-conflicting-outputs`
   if you changed Drift or generated models.
4. Include a clear summary of the user-visible change.

## Icons and branding

If your change updates the app logo or icons, replace the platform assets
documented in `README.md` and rebuild the affected targets.

## License

By contributing to this project, you agree that your contributions will be
licensed under the MIT License.
