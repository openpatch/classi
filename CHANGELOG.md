# Changelog

All notable changes to this project will be documented in this file.

## [1.6.0] - 2026-05-08

### Bug Fixes

- *(database)* Make v12/v13 attendance migrations idempotent
- *(seating-plan)* Prevent chip from snapping back on concurrent drag
- *(seating-plan)* Fix UNIQUE constraint error and remove dark background
- *(seating-plan)* Select next plan after deleting the active one
- *(groups)* Replace ListView with SingleChildScrollView in group detail


### Features

- *(seating-plan)* Add seating plan feature
- *(seating-plan)* Replace free-drag canvas with configurable grid
- *(seating-plan)* Auto-expand columns like rows
- *(seating-plan)* Default plan with star + auto-load on view switch


### Miscellaneous Tasks

- *(release)* Update X-AppImage-Version in Linux desktop file on tag


## [1.5.0] - 2026-05-08

### Bug Fixes

- Align grade table header with rows using Expanded columns
- *(lessons)* Load grades reactively when category changes
- *(android)* Remove redundant edge-to-edge helper


### Features

- *(lessons)* Add lesson notes and attendance states
- Improve teacher UX with quick note, class average line, and attendance badge
- Add date-range filter and parent summary screen
- Custom date range filter, overflow fix, and summary screen filtering
- Add quick note FAB to parent summary screen
- *(ui)* Improve layout for desktop and wide screens
- *(lessons)* Add category-driven lesson planner


## [1.4.4] - 2026-05-07

### Bug Fixes

- *(webdav)* Avoid false newer-backup prompt


## [1.4.3] - 2026-05-06

### Bug Fixes

- *(linux)* Align AppImage app identity
- *(changelog)* Skip fastlane changelog commits and deduplicate entries
- *(changelog)* Use unique filter for cleaner deduplication


## [1.4.2] - 2026-05-06

### Bug Fixes

- *(android)* Add INTERNET permission to release manifest
- *(linux)* Close window when app is in lock mode
- *(ci)* Remove [skip ci] from fastlane changelog commit
- *(backup)* Clear pending-import flag after restore and show restoring state


## [1.4.1] - 2026-05-06

### Bug Fixes

- *(setup)* Overwrite prompt for duplicate DB names and WebDAV credential correction


### Features

- *(sync)* Improve WebDAV sync reliability and UX


## [1.4.0] - 2026-05-06

### Bug Fixes

- *(backup)* Test WebDAV connection using current field values
- *(backup)* Upload before locking and show progress indicator


### Documentation

- Update README and CHANGELOG for WebDAV backup and theme settings
- Remove section from changelog


### Features

- *(settings)* Add configurable theme setting (light/dark/auto)
- *(backup)* Replace local-folder backup with WebDAV support
- *(backup)* Restore from WebDAV with credential prompt when unconfigured


### Refactoring

- *(setup)* Extract create database dialog into StatefulWidget


## [1.3.0] - 2026-05-05

### Bug Fixes

- Address code review issues in AppUpdater
- Address second round of code review issues in AppUpdater


### Features

- Add auto-update for desktop apps using updat package


## [1.2.4] - 2026-05-04

### Bug Fixes

- *(students)* Match displayed names to sort order
- Await delete before popping sheet and navigate cleanly after deletion
- *(backup)* Extend suspendBackgroundLock to cover all async state updates


### Features

- Add delete button to student edit sheet with confirmation dialog


### Refactoring

- *(backup)* Use if/else to remove early return and dead code


## [1.2.3] - 2026-05-03

### Bug Fixes

- *(setup)* Show error snackbar if database creation fails


### Documentation

- Update changelog


## [1.2.2] - 2026-04-29

### Bug Fixes

- *(android)* Enable edge-to-edge for Android 15 compatibility


### Documentation

- Add PRIVACY_POLICY.md for Google Play Store
- Add fastlane metadata


### Miscellaneous Tasks

- Remove publish-playstore from release job needs


## [1.2.1] - 2026-04-28

### Miscellaneous Tasks

- Add playstore release


## [1.1.9] - 2026-04-28

### Bug Fixes

- Prevent app from locking when file picker dialog is open
- Restore navigation context after app unlock


## [1.1.8] - 2026-04-28

### Bug Fixes

- Address review issues in list screens and student selection sheet


### Features

- Better lists
- *(students)* Add Lists tab to student detail screen


### Refactoring

- *(students)* Extract _ListItemTile widget to avoid code duplication


## [1.1.7] - 2026-04-28

### Bug Fixes

- *(ci)* Replace invalid reactions permission with issues write


### Features

- *(setup)* Force folder selection and warn about storage risk on Android


### Refactoring

- *(setup)* Extract default library name to a named constant


## [1.1.6] - 2026-04-28

### Bug Fixes

- *(android)* Use stable release keystore for signed APK builds


### Miscellaneous Tasks

- Add archive: false to upload-artifact steps for direct download links


## [1.1.5] - 2026-04-28

### Bug Fixes

- Add missing biometricService argument to test constructors
- Prevent app from locking twice on background


### Features

- *(ci)* Add rocket reaction on build start and direct binary download links


### Reverts

- *(ci)* Restore upload-artifact for zip downloads, keep rocket reaction


## [1.1.4] - 2026-04-27

### Bug Fixes

- Cache PackageInfo future and unify shell quoting in Windows build step


### Features

- Add fingerprint/biometric unlock support on Android, iOS, and macOS
- Add PR build app name suffix and version info in settings


## [1.1.3] - 2026-04-27

### Bug Fixes

- *(session)* Centralize app session errors
- *(ui)* Replace raw error output
- *(data)* Query group student counts


### Refactoring

- *(lessons)* Extract lesson sections


### Testing

- *(app)* Cover session entry states


## [1.1.2] - 2026-04-27

### Bug Fixes

- *(ci)* Wait for changelog before building, fix release body linebreaks


## [1.1.1] - 2026-04-27

### Bug Fixes

- *(ci)* Bump pubspec.yaml version on release
- PR builds use .pr applicationId suffix to avoid overwriting the real app


## [1.1.0] - 2026-04-27

### Bug Fixes

- Enable swipe between tabs in Notes and Groups screens
- *(setup)* Dispose nameController and deduplicate path in dialog
- *(ci)* Use actions/upload-artifact@v7 to match release.yml
- *(setup)* Use descriptive validator error messages in wizard steps


### Features

- *(setup)* Allow folder and name selection when creating a database
- *(ci)* On-demand per-platform PR builds with artifact comment
- *(ci)* Trigger per-platform builds via PR comment with direct artifact link
- *(setup)* Convert SetupScreen into a 4-step database creation wizard


### Miscellaneous Tasks

- *(ci)* Update upload artifact to v7
- *(ci)* Add PR build workflow for downloadable binaries


## [1.0.0] - 2026-04-26

<!-- generated by git-cliff -->
