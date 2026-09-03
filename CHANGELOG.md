# Changelog

All notable changes to this project will be documented in this file.

## [1.20.0] - 2026-09-02

### Bug Fixes

- *(session)* Keep the app in step with its library, and usable while it saves
- *(seating-plan)* Show every rule a student has, near or far
- *(seating-plan)* Take a tap anywhere in a student's cell
- *(i18n)* Restore the seating plan's translations and guard them


### Features

- *(security)* Wait a moment before locking when the app goes away
- *(seating-plan)* Draw the rules, suggest a seating, export a plan
- *(groups)* Take students, rules and a seating plan from another group
- *(lists)* Sort the lists and the entries inside them


## [1.19.0] - 2026-09-02

### Bug Fixes

- *(session)* Hand the reopened database to the app after a resume
- *(seating-plan)* Keep two students off the same cell


### Features

- *(seating-plan)* Rules for who should and should not sit together


## [1.18.5] - 2026-09-02

### Bug Fixes

- *(database)* Stay quiet when a library closes under a live stream


## [1.18.4] - 2026-09-01

### Bug Fixes

- *(errors)* Report the failure behind the inline error states too


## [1.18.3] - 2026-09-01

### Features

- *(errors)* Let teachers report the error behind the error screen


## [1.18.2] - 2026-08-29

### Documentation

- *(metadata)* Correct and refresh the store descriptions


## [1.18.1] - 2026-08-29

### Bug Fixes

- Update german website


### Features

- *(site)* Add the classi.openpatch.org landing page
- *(release)* Publish fastlane changelogs and screenshots to Play


## [1.18.0] - 2026-08-28

### Bug Fixes

- *(ci)* Move the release tag onto the commit it names


### Features

- *(linux)* Package Classi as a Flatpak
- *(linux)* Use desktop screenshots for the AppStream metainfo
- *(ci)* Add each release to the AppStream metainfo automatically


## [1.17.0] - 2026-08-28

### Bug Fixes

- *(attendance)* Keep homework and material when a student is marked absent


### Documentation

- Add the Classi 2.0 plan


### Features

- *(database)* Copy the library aside before migrating it
- *(school-year)* Make the school year the frame the app works in


### Performance

- *(database)* Index every foreign key and date column


## [1.16.0] - 2026-08-28

### Features

- *(avatar)* Student-designed avatars via a browser companion app


### Miscellaneous Tasks

- Vendor dart and flutter agent skills


## [1.15.0] - 2026-08-28

### Bug Fixes

- *(setup)* Store Android libraries in app storage


### Features

- *(schedule)* Add a weekly timetable view
- *(schedule)* Show lesson labels and a responsive timetable
- Replace the Today dashboard with the weekly timetable


## [1.14.1] - 2026-08-22

### Features

- Report stacktrace via email when clicking the error toast


## [1.14.0] - 2026-08-21

### Features

- *(lessons)* Plan lessons from a group's weekly schedule


## [1.13.0] - 2026-08-21

### Features

- *(timeframes)* Define timeframes per school year instead of per group


## [1.12.1] - 2026-08-05

### Bug Fixes

- Prevent chip label overflow and drop unused imports
- Keep pre-existing list labels tied to their student
- Roll back the adopted revision when conflict re-export fails


### Features

- Add Today dashboard and backup conflict resolution UI
- Let the Today dashboard browse other dates
- Make the Today dashboard's date deep-linkable
- Add a call name (Rufname) for students


## [1.12.0] - 2026-08-04

### Bug Fixes

- Don't let pre-restore auto-export clobber the WebDAV backup being restored
- Make page width consistent across screens and remove horizontal table scrolling
- Prevent dropdown overflow with long labels
- Silence unnecessary_underscores lint in student_detail_screen


### Features

- Attach device identity to WebDAV backups
- Add a best-effort WebDAV sync lock around export
- Detect conflicting WebDAV backups instead of silently overwriting
- Add a foreground safety-net export timer and a visual backup status button


### Miscellaneous Tasks

- Remove dead code and fix broken lesson repository test


### Styling

- Use null-aware collection elements (dart fix)


## [1.11.0] - 2026-07-03

### Features

- *(timeframe)* Add timeframe information to student details screen


## [1.10.0] - 2026-06-22

### Features

- *(timeframes)* Simple implementation of timeframes.


## [1.9.0] - 2026-05-21

### Bug Fixes

- *(lessons)* Create session on save, fix 1970 date in session list
- *(calendar)* Show dots only for sessions, colored by category
- *(sessions)* Remove isUtc: true to fix off-by-one date in table
- *(database)* Upsert sessions from grade entries on conflict
- *(lessons)* Show all notes instead of capping at 5


### Features

- *(database)* Migrate sessions from grade entries (v18)
- *(database)* Also seed sessions from attendance logs in v18 migration
- *(settings)* Add restore-from-backup button in backups section
- *(settings)* Show inline backup list with restore per entry
- *(notes)* Add search bar to global notes view
- *(groups)* Add CSV export for grades, attendance, homework and summary
- *(groups)* Let user choose save location for CSV exports


### Styling

- *(sessions)* Remove category color circles from sessions table
- *(sessions)* Hide checkbox column in sessions table


## [1.8.1] - 2026-05-20

### Bug Fixes

- Add FAB clearance bottom padding in lesson mode screen


### Miscellaneous Tasks

- Add checkout step to publish-playstore job


## [1.8.0] - 2026-05-13

### Features

- *(lesson)* Enhance seating plan lesson actions


## [1.7.1] - 2026-05-12

### Bug Fixes

- *(seating-plan)* Improve edit mode moves


## [1.7.0] - 2026-05-11

### Bug Fixes

- *(settings)* Store settings in classi projects


## [1.6.2] - 2026-05-08

### Bug Fixes

- *(app)* Refine sync, update, and seating feedback


## [1.6.1] - 2026-05-08

### Features

- Improve error handling and notify users on failure


## [1.6.0] - 2026-05-08

### Bug Fixes

- *(android)* Remove redundant edge-to-edge helper
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

- *(linux)* Align AppImage app identity
- *(webdav)* Avoid false newer-backup prompt


## [1.4.3] - 2026-05-06

### Bug Fixes

- *(backup)* Clear pending-import flag after restore and show restoring state
- *(changelog)* Skip fastlane changelog commits and deduplicate entries
- *(changelog)* Use unique filter for cleaner deduplication


## [1.4.2] - 2026-05-06

### Bug Fixes

- *(android)* Add INTERNET permission to release manifest
- *(linux)* Close window when app is in lock mode
- *(ci)* Remove [skip ci] from fastlane changelog commit


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


## [1.2.0] - 2026-04-28

### Bug Fixes

- Address review issues in list screens and student selection sheet


### Features

- Better lists


## [1.1.9] - 2026-04-28

### Bug Fixes

- Prevent app from locking when file picker dialog is open
- Restore navigation context after app unlock


## [1.1.8] - 2026-04-28

### Features

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
