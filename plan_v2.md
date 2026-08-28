# Classi 2.0 — Breaking Schema & Architecture Reset

## Context

Classi 1.x has accumulated ~24 Drift migrations, a plaintext settings sidecar,
v1/v2 security-metadata branching, JSON blobs standing in for relational tables,
denormalized copies that drift, `period = 0` / `isAbsent default true` sentinels,
per-student logs with no session link, hard-delete cascades that retroactively
mutate historical grade averages, and German defaults baked into column DDL.
None of it can be cleaned up while `.classi` files from old app versions must
keep opening.

Version 2.0 breaks that contract outright: **1.x libraries are not supported and
are not migrated.** 2.0 is a fresh schema with one `onCreate` baseline. That
removes what was previously the largest and riskiest part of this plan (a
standalone SQLCipher-level v1→v2 migrator, a frozen v1 schema snapshot, a
corpus harness, rollback fault-injection) and lets the effort go into the model
instead.

The second thing 2.0 changes is the shape of the app: **the school year becomes
the organizing spine**, not a field buried in Settings. Everything a teacher
sees is scoped to one year, and moving from one year to the next is a supported
flow rather than manual group cloning.

## Decisions

- **Clean break. No v1 migration.** 2.0 cannot open a 1.x library and will not
  try. It detects one and says so clearly (§1). All Drift steps 2..24 are
  deleted; v2 has one `onCreate` baseline and a *disciplined* forward ladder
  from 2.0 onward (§4 WS1).
- **School year is the spine.** One active year at a time, chosen in the app
  shell; groups, timetable, terms, holidays, notes and checklists all hang off
  it; a year rollover flow carries groups and people forward (§2).
- **Full scope.** Schema normalization + security-metadata v2 + backup-format v2
  + settings into the encrypted DB + architecture refactors (split god files,
  Riverpod `Notifier` + codegen) + i18n restructure.
- **Big-bang `v2` branch.** `main` stays 1.x maintenance; one long-lived `v2`
  branch; one breaking release.
- **No web build. Decided and closed.** Investigated and dropped: encrypted
  drift-on-web requires `PRAGMA key` to run inside a worker via a *synchronous,
  parameterless* setup callback that is handed no key (`WasmDatabaseSetup =
  void Function(CommonDatabase)`; `localSetup` is documented as not called when
  the database opens in a worker, which is the normal path), upstream web
  encryption is experimental, and the fallback storage modes cannot prevent
  multi-tab data races. Targets stay linux/macos/windows/android. Rationale kept
  in the appendix so this is not re-litigated from scratch later.

## Verification (global)

Every PR on `v2` must pass: `flutter analyze` (zero warnings, incl. the WS0 lint
rules), `flutter test`, and a clean `dart run build_runner build
--delete-conflicting-outputs`. Per-workstream verification is listed with each
workstream; the full test architecture is §6 and a manual end-to-end script
is §9.

---

## 1. The clean break from 1.x

### 1.1 Why v2 can't accidentally open a v1 file

The protection is physical, not a version check: v1 libraries are SQLCipher **3**
on disk (`PRAGMA legacy = 4` in `cipher_opener.dart:12`); v2 drops that pragma
and is SQLCipher **4**. A v1 file simply fails to decrypt under v2, and a v2 file
fails to decrypt under 1.x. Neither can silently half-read the other.

The problem is that "fails to decrypt" is *indistinguishable from a wrong
passphrase*. Without help, a 1.x user pointing 2.0 at their library gets
"invalid passphrase" forever and concludes the app ate their data.

### 1.2 `library.json` — the format marker

New plaintext file at the root of every `.classi` package, written at library
creation, read **before** the passphrase prompt:

```json
{ "formatVersion": 2, "createdBy": "2.0.0", "createdAt": "2026-08-28T…Z" }
```

`SessionController` open path, in order:
1. `library.json` missing → the directory contains `data.db` → **v1 library** →
   `AppSessionStatus.unsupportedLibrary` → `UnsupportedLibraryScreen`.
2. `library.json` missing → no `data.db` → brand-new location → normal setup.
3. `formatVersion > 2` → "this library needs a newer Classi" (a real error, not
   a decrypt failure).
4. `formatVersion == 2` → normal unlock.

`user_version` stays at **100** for v2 (§3) as a second, in-band tripwire — it
also gives the forward ladder room to grow (101, 102, …) without ever colliding
with a 1.x number.

### 1.3 What existing 1.x users see — decide before tagging

This is a product decision, not an engineering one, and the plan should not
pretend otherwise. A 1.x user who takes a routine app update and finds their
library unopenable is a support incident, not a migration.

- **Recommended:** ship 2.0 as a deliberate major release. 1.x stays installable
  and downloadable (pinned release + store note); `UnsupportedLibraryScreen`
  states plainly that the library is intact on disk, that 2.0 uses a new format,
  and links to the 1.x download and the "start fresh" path. Nothing is deleted,
  moved, or rewritten — 2.0 never touches a v1 `.classi` directory.
- **Alternative if the break proves too harsh:** add a *data-level* bridge —
  1.x (on `main`) grows an "export library to portable JSON" action; 2.0 imports
  that documented JSON. This is a fraction of the work of the binary migrator
  (no SQLCipher juggling, no frozen DDL, no rollback protocol) and it is
  decoupled: it can ship in 2.1 without holding up 2.0. **Not planned work — an
  option kept open.**

Whichever is chosen, `UnsupportedLibraryScreen` and the release notes must be
written before the tag, not after the first bug report.

### 1.4 What this removes from the plan

Deleted outright versus the previous draft: `lib/core/migration/v1/**`,
`lib/features/migration/**`, the frozen `v1_schema.dart` snapshot, the frozen
dual-format grade-scale parser, `legacy_cipher_opener.dart`, the 16-step
transform order, the `data.db.v2tmp` + `<pkg>/archive/` + `migration.json` swap
and resume protocol, `AppSessionStatus.needsMigration`, the anonymized-corpus CI
harness, rollback fault-injection tests, and WS8's "import a v1 WebDAV backup".
Also gone: the sequencing constraint that forced a v1 schema freeze before WS1
could touch the tables — WS1 is now unblocked on day one.

---

## 2. The school year as the organizing spine

Today a school year is a row in a table reachable only via
`/settings/school-years`; groups carry a nullable `schoolYearId`; nothing else
knows years exist. In 2.0 the year is the frame everything is drawn in.

### 2.1 One active year, chosen in the shell

- `settings['active_school_year_id']` (WS4 settings table) holds the choice.
- `@riverpod ActiveSchoolYear` resolves on library open, in order: the stored id
  if it still exists and is not archived → the year containing today → the
  newest non-archived year → (fresh library) the seeded current year.
- A **year switcher lives in `AppScaffold`** — nav-rail footer on desktop, app-bar
  dropdown on mobile — visible from every screen. Switching re-scopes the whole
  app; it is not a per-screen filter that has to be re-applied.
- Repositories take the active year as an explicit argument (`watchGroups(
  schoolYearId: …)`); providers supply it from `ActiveSchoolYear`. No repository
  reads global state.
- Archived year selected ⇒ the app is **read-only** for year-scoped writes, with
  a persistent banner. Prevents the classic "recorded today's lesson into last
  year" mistake.

### 2.2 Everything year-scoped is year-scoped *in the schema*

Not just by convention. `groups` gets `U(id, school_year_id)` so children can
carry a **composite foreign key** `(group_id, school_year_id) → groups(id,
school_year_id)`. SQLite enforces it, and a NULL `group_id` satisfies it (MATCH
SIMPLE), so free-floating rows still work:

- `lesson_slots(group_id, school_year_id)` — kills the "slot's year ≠ group's
  year" corruption class the previous draft left open.
- `notes(group_id, school_year_id)` — `school_year_id` **NOT NULL**, `group_id`
  nullable. An ungrouped note still belongs to a year, so last year's notes
  don't clutter this year's list.
- `checklists(group_id, school_year_id)` — same.

`sessions`, `grade_entries`, `session_participation`, `term_grades` and
`seating_plans` reach the year through `group_id` (indexed join); they need no
column of their own.

### 2.3 The year owns the calendar — `school_year_days`

New table (the year stops being just two dates). Non-teaching days are what a
teacher actually needs the year for:

- **Timetable** greys them out instead of offering to record a lesson.
- **Session generation** skips them.
- **Attendance statistics** exclude them from the denominator — today an absence
  rate is silently wrong across a holiday week.

Seeded empty; entered by hand, pasted, or imported later from a public-holiday
list (2.x, not now).

### 2.4 Terms belong to the year

`timeframes` → `terms`, `school_year_id` NN, DB-enforced non-overlap (trigger).
New: a **coverage check** surfaced as a warning, not a constraint — terms that
leave a gap in the year, or run past its `ends_on`, are flagged in the year
screen. Teachers do have irregular term structures; the app should notice, not
refuse.

A fresh library seeds the current year **and two terms** (locale-aware defaults —
`Halbjahr 1/2` for `de`, `Term 1/2` for `en`), split at the year midpoint. A
year with no terms means the term-grades screen is dead on arrival, so seeding
matters.

### 2.5 Rollover — "start the next school year"

The flagship flow, and the payoff for splitting `people` from `enrollments`.
Without it, that split is pure cost. From the year screen:

1. Propose the next year's dates from the boundary setting and the current
   year's shape; the teacher confirms or edits. Seed its terms the same way.
2. Show every group in the outgoing year with a checkbox: **carry forward?**
3. For each carried group, create a new `groups` row in the new year and copy:
   grade scale reference, `group_grade_categories` weights, `lesson_slots`
   (with `valid_from` = new year start), optionally seating plans.
4. **Re-enroll the same `people`** as fresh `enrollments` in the new group.
   Preselected, individually deselectable (students leave). This is the whole
   reason people and enrollments are separate tables: the *person* is continuous,
   the *membership* is per-year, and a student's history now spans years.
5. Sessions, grades, participation and term grades stay with the old year's
   enrollments. Nothing historical moves.
6. Switch the active year to the new one. Offer (don't force) archiving the old.

Runs in one transaction with a summary. This replaces today's ad-hoc "clone
group" in `groups_screen.dart:301`, which is reframed as a year-scoped operation.

### 2.6 Cross-year reporting — why grade categories move up

Per-group grade categories (the previous draft) mean every rollover duplicates
"Klassenarbeit" into a new row. After three years a student's Klassenarbeit
history is spread across three unrelated category ids and cannot be queried.
Weights drift silently between groups that were meant to match.

**Recommendation:** categories become **library-scoped**, with the per-group
*weight* in a join table:

- `grade_categories` — the definition (slug, name, `name_key`, color, order).
- `group_grade_categories(group_id, grade_category_id, weight, sort_order)` —
  the per-group usage.

`sessions.grade_category_id` and the weighted-average view point at the shared
definition, so "how has this student done on written work over three years" is
one query, and rollover copies weights instead of cloning definitions.

Cost: one extra table and a wider WS2 fan-out. *If rejected*, keep categories
per-group and accept duplication at rollover — but then cross-year category
reporting is off the table and should be struck from the goals.

### 2.7 UI consequences

- `/years` becomes a **top-level route** (out of Settings): the year overview —
  terms, holidays, groups, coverage warnings, "start next school year", archive.
- `/timetable` and `/groups` scope to the active year; `/groups` keeps an
  explicit "show other years" escape hatch (read-only).
- Student detail becomes **person** detail: enrollment history across years,
  with per-year grade summaries — the longitudinal view the model now supports
  and the current app cannot express.
- `/notes` and `/lists` scope to the active year.

---

## 3. v2 target schema

### Cross-cutting decisions

- **Dates** (calendar): `TEXT 'YYYY-MM-DD'` via a `Date` value type + `DateConverter` (`lib/core/database/converters/date_converter.dart`). Lexical == chronological, so `isBetweenValues` works on the `TextColumn` — this alone fixes the "Drift can't compare dates" workaround in `timeframe_repository.dart:75`. No `normalizeLessonDate` anywhere. All of `birth_date`, `joined_on`, `held_on`, `valid_from/to`, `starts_on/ends_on`.
- **Timestamps**: `DriftDatabaseOptions(storeDateTimeAsText: true)` DB-wide → ISO-8601 **UTC** text. Repos write `DateTime.now().toUtc()` (lint-enforced). Kills the `currentDateAndTime`-vs-`DateTime.now()` split.
- **Colors**: `colorHex` TEXT → `color INT` (ARGB32); one `colorToInt`/`colorFromInt` pair replaces three helpers.
- **Naming**: drop the `_table` suffix on every table; delete the `typedef` block in `app_database.dart:25-35`; explicit singular `@DataClassName` on every table; "list/checklist" → **checklist** everywhere.
- **Enums**: stored as `TEXT` + `CHECK (col IN (...))` + a Drift `TextEnum` converter (readable in SQL dumps / backups), not ints.
- **Link rule**: data *about the human across time* → `people.id` (`note_students`, `checklist_item_students`); data *about class membership* → `enrollments.id` (`session_participation`, `grade_entries`, `term_grades`, `seating_plan_positions`). Longitudinal views join `enrollments → people`.
- **Year rule** (§2.2): anything year-scoped that is not reachable through `group_id` carries `school_year_id` NN; anything that carries both carries a composite FK.
- **No materialized copies.** Every column that duplicates a value reachable by an indexed join is a bug in waiting (that is half of appendix A.4). If a copy is genuinely needed for a constraint, it is maintained by a trigger in the `.drift` file, never by repository discipline.
- **Drift**: bump `drift`/`drift_dev` to latest 2.x (stable `storeDateTimeAsText`, `customConstraints` for composite FKs). Triggers + views in an `include:`d `lib/core/database/app_database.drift`.
- **`schemaVersion` → 100.** In-band tripwire (§1.1) and headroom for the forward ladder. Single `onCreate` = `createAll()` + `library_seed.dart` (3 library grade scales, current school year, its two terms, the built-in grade categories). No `onUpgrade` in 2.0.0 — but see WS1 for the discipline that governs 2.1 onward.

### Tables (~24)

`FK→t.c (onDelete)` · `U(...)` unique · `IX(...)` index · `CK(...)` check.

- **school_years**: `id`, `name` NN, `starts_on` Date NN, `ends_on` Date NN, `archived_at` ts, `created_at` ts NN. `CK(ends_on > starts_on)`, `U(starts_on, ends_on)`, `U(name)`.
- **school_year_days** (§2.3): `id`, `school_year_id` NN `FK→school_years (CASCADE)`, `name` NN, `starts_on`/`ends_on` Date NN, `kind` NN `CK IN ('holiday','public_holiday','pd_day','exam','other')`, `created_at` ts NN. `CK(ends_on >= starts_on)`, `IX(school_year_id, starts_on)`.
- **terms** (was timeframes): `id`, `school_year_id` NN `FK→school_years (CASCADE)`, `name` NN, `starts_on`/`ends_on` Date NN, `created_at` ts NN. `U(school_year_id, name)`, `U(school_year_id, starts_on, ends_on)`, `CK(ends_on >= starts_on)`, `IX(school_year_id)`. Non-overlap enforced by a `BEFORE INSERT/UPDATE` trigger (`.drift` file); coverage gaps are a UI warning, not a constraint.
- **grade_scales**: `id`, `scope` NN `CK IN ('library','group')`, `name` NN, `kind` NN `CK IN ('lowerIsBetter','higherIsBetter')`, `created_at` ts NN, `archived_at` ts. Partial `U(name) WHERE scope='library'`.
- **grade_scale_entries**: `id`, `scale_id` NN `FK→grade_scales (CASCADE)`, `label` NN, `numeric_value` real NN, `sort_order` int NN, `is_passing` bool NN default 0. `U(scale_id, label)`, `U(scale_id, sort_order)`, `IX(scale_id)`. 3 templates from `defaultGradeSystemTemplates` seeded `scope='library'` at library creation (locale-aware names).
- **groups**: `id`, `name` NN, `color` int NN, `school_year_id` int **NN** `FK→school_years (RESTRICT)`, `grade_scale_id` int NN `FK→grade_scales (RESTRICT)`, `default_seating_plan_id` int `FK→seating_plans (SET NULL)`, `archived_at` ts, `created_at` ts NN. `U(id, school_year_id)` (composite-FK parent key, §2.2), `U(school_year_id, name)`, `IX(school_year_id)`. Drops `gradeScaleJson`, `gradeCategoriesJson`, `colorHex`.
- **grade_categories** (library-scoped, §2.6): `id`, `slug` NN, `name` NN, `name_key` text (i18n key for built-ins; NULL = user-named), `color` int NN, `sort_order` int NN, `archived_at` ts, `created_at` ts NN. `U(slug)`. Seeded with the three built-ins, locale-aware.
- **group_grade_categories** (§2.6): `group_id` NN `FK→groups (CASCADE)`, `grade_category_id` NN `FK→grade_categories (RESTRICT)`, `weight` real NN default 1 `CK > 0`, `sort_order` int NN, PK `(group_id, grade_category_id)`, `IX(grade_category_id)`.
- **people**: `id`, `first_name` NN, `last_name` NN, `call_name` text, `birth_date` Date, `email` text, `external_id` text (import id, **not unique**), `avatar` text (opaque `avatar_maker` descriptor), `archived_at` ts, `created_at` ts NN. `IX(last_name, first_name)`. Hard delete stays `CASCADE` and stays *deliberate* — it is the GDPR erasure path (§7), reached only through an explicit confirm-by-typing action, never through "remove from group" (which sets `enrollments.status`).
- **enrollments**: `id`, `person_id` NN `FK→people (CASCADE)`, `group_id` NN `FK→groups (CASCADE)`, `status` NN default 'active' `CK IN ('active','left','archived')`, `joined_on`/`left_on` Date, `origin_note` text, `sort_index` int, `created_at` ts NN. `U(person_id, group_id)`, `IX(group_id, status)`, `IX(person_id)`. Soft-delete replaces the hard `DELETE` cascade in `student_repository.dart:128`.
- **periods** (optional, empty by default): `id`, `school_year_id` NN `FK→school_years (CASCADE)`, `ordinal` int NN, `starts_at`/`ends_at` text ('HH:MM'), `label` text. `U(school_year_id, ordinal)`.
- **lesson_slots**: `id`, `group_id` NN, `school_year_id` NN, **composite** `FK(group_id, school_year_id)→groups(id, school_year_id) (CASCADE)`, `weekday` int NN `CK BETWEEN 1 AND 7`, `period_start` int NN `CK >= 1`, `period_end` int NN `CK >= period_start`, `grade_category_id` int `FK→grade_categories (SET NULL)`, `valid_from` Date NN, `valid_to` Date (NULL = open-ended), `created_at` ts NN. `U(group_id, weekday, period_start, valid_from)`, `IX(group_id, school_year_id)`. Stable ids ⇒ `replaceSlots` (`lesson_slot_repository.dart:53`) becomes upsert + close-out, not delete-all-reinsert.
- **sessions**: `id`, `group_id` NN `FK→groups (CASCADE)`, `slot_id` int `FK→lesson_slots (SET NULL)`, `grade_category_id` int NN `FK→grade_categories (RESTRICT)`, `held_on` Date NN, `period_start` int `CK NULL OR >= 1`, `period_end` int `CK NULL OR >= period_start` (NULL = unscheduled; no `0` sentinel), `label` text NN default '', `description` text, `created_at` ts NN. `IX(group_id, held_on)`, `IX(slot_id)`. Unique via expression index: `CREATE UNIQUE INDEX ux_sessions_slot ON sessions(group_id, held_on, grade_category_id, IFNULL(period_start, 0))` — note the consequence: **at most one *unscheduled* session per group/day/category**, which is intended (a second one means it should have a period).
- **grade_entries**: `id`, `session_id` int **NN** `FK→sessions (CASCADE)` (replaces the `sessionLabel` join key), `enrollment_id` NN `FK→enrollments (CASCADE)`, `scale_entry_id` int `FK→grade_scale_entries (SET NULL)`, `raw_value` text, `numeric_value` real (materialized at write — the one deliberate exception, since it is a *parse result*, not a copy), `created_at` ts NN. `CK(scale_entry_id IS NOT NULL OR raw_value IS NOT NULL)`, **`U(session_id, enrollment_id)`**, `IX(enrollment_id)`. **No `grade_category_id`** — one session has exactly one category, so a column here would be a denormalized copy of `sessions.grade_category_id` needing a trigger to stay honest; the category comes from the session by indexed join. (If multi-category sessions are ever wanted, that is a session-level change, not a column here.) Weighted average → SQL **view** `group_student_averages`, joining `sessions → grade_categories → group_grade_categories` for the weight (kills `_weightedAveragesFromRows`).
- **session_participation** — absorbs `attendance_logs` + `homework_logs` + `material_logs`: `id`, `session_id` NN `FK→sessions (CASCADE)`, `enrollment_id` NN `FK→enrollments (CASCADE)`, `attendance_status` text `CK IN ('present','absent','late','left_early')`, `excused` bool NN default 0 (independent of status), `homework_status` text `CK IN ('done','partial','missing')`, `material_status` text `CK IN ('complete','partial','missing')`, `note` text, `created_at`/`updated_at` ts NN. `U(session_id, enrollment_id)`, `IX(enrollment_id)`. Row presence = "recorded"; NULL sub-status = "not recorded". `markAbsent` sets one field on one row and never touches homework/material (fixes the `attendance_repository.dart:129` data-loss side effect). Summaries become `GROUP BY session_id` (kills the correlated subqueries in `session_repository.dart:396-449`).
- **term_grades** (was timeframe_grades): `id`, `term_id` NN `FK→terms (CASCADE)`, `enrollment_id` NN `FK→enrollments (CASCADE)`, `scale_entry_id` int `FK→grade_scale_entries (SET NULL)`, `raw_value` text, `numeric_value` real, `note` text, `created_at`/`updated_at` ts NN. `CK(scale_entry_id IS NOT NULL OR raw_value IS NOT NULL)`, `U(term_id, enrollment_id)`, `IX(enrollment_id)`.
- **notes**: `id`, `body` NN, `school_year_id` **NN**, `group_id` int, composite `FK(group_id, school_year_id)→groups(id, school_year_id) (SET NULL on group)` + `FK(school_year_id)→school_years (CASCADE)`, `kind` NN default 'note' `CK IN ('note','todo')`, `completed_at` ts (non-null ⇒ done; replaces `isTodo`+`todoDone`+`todoDoneAt`), `pinned_at` ts, `archived_at` ts, `created_at`/`updated_at` ts NN. `IX(school_year_id, group_id)`. Drops `studentId`, `studentIdsJson`.
- **note_students**: `note_id` NN `FK→notes (CASCADE)`, `person_id` NN `FK→people (CASCADE)`, PK `(note_id, person_id)`, `IX(person_id)`. "Notes for student" → indexed join (kills the O(all-notes) Dart filter in `note_repository.dart:34`).
- **checklists** (was lists): `id`, `school_year_id` **NN** `FK→school_years (CASCADE)`, `group_id` int, composite `FK(group_id, school_year_id)→groups(id, school_year_id)`, `name` NN, `archived_at` ts, `created_at` ts NN. `IX(school_year_id, group_id)`.
- **checklist_items**: `id`, `checklist_id` NN `FK→checklists (CASCADE)`, `label` text (NULL ⇒ render from the single linked person; drops `isGeneratedStudentDisplayName`), `checked_at` ts, `sort_order` int NN, `created_at` ts NN. `IX(checklist_id)`.
- **checklist_item_students**: `item_id` NN `FK→checklist_items (CASCADE)`, `person_id` NN `FK→people (CASCADE)`, PK `(item_id, person_id)`.
- **seating_plans**: `id`, `group_id` NN `FK→groups (CASCADE)`, `name` NN, `columns` int NN default 6 `CK > 0`, `rows` int NN default 5 `CK > 0`, `created_at` ts NN. `IX(group_id)`. Drops `isDefault`.
- **seating_plan_positions**: `id`, `seating_plan_id` NN `FK→seating_plans (CASCADE)`, `enrollment_id` NN `FK→enrollments (CASCADE)`, `col` int NN `CK >= 0`, `row` int NN `CK >= 0`. `U(seating_plan_id, enrollment_id)`, `U(seating_plan_id, col, row)` (one student per cell — new), `IX(seating_plan_id)`.
- **settings** — encrypted KV: `key` text PK, `value` text NN (JSON scalar), `updated_at` ts NN. Holds: **`active_school_year_id`**, school-year boundary (proposes dates for new years), theme mode, student sort, WebDAV url/username/server_path/max_versions/auto_export/auto_import, backup schedule + last-export/import timestamps + last-known-revision, WebUntis column mapping.

### Views (in `app_database.drift`)

- `group_student_averages` — weighted average per enrollment per group.
- `person_year_summary` — per `person_id` × `school_year_id`: average, attendance rate (**denominator excludes `school_year_days`**, §2.3), missing-homework count. Backs the longitudinal person screen (§2.7) without Dart aggregation.

---

## 4. Workstreams (`v2` branch)

Merge model: `main` stays 1.x. WS0/WS1 land first and fast. WS2 merges **feature
by feature** (never one 10k-line PR). WS3 runs parallel to WS1.

*(Numbering note: the old WS7 — the v1 migrator — is gone. School year is the
new WS5; the old WS5/WS6 shift to WS6/WS7. The web workstream is dropped.)*

### WS0 — Branch + tooling
Bump `drift`/`drift_dev`/`flutter_riverpod`+`riverpod_annotation`+`riverpod_generator`; add `build.yaml`; `storeDateTimeAsText: true`; `Date` + `DateConverter` scaffold; lint rules: ban `flutter_riverpod/legacy.dart`, ban `shared_preferences` outside one allowlisted file, require `.toUtc()` on `DateTime.now()` in `**/*_repository.dart`.
Files: `pubspec.yaml`, `build.yaml` (new), `analysis_options.yaml`, `lib/core/database/converters/date_converter.dart` (new), CI.
Verify: analyze + existing suite (minus the 2 deleted migration tests) green. **Land alone, green, before anything else** — drift bump + Riverpod codegen + `storeDateTimeAsText` will thrash if combined with other work.

### WS1 — v2 schema + Drift regen + baseline `onCreate` + forward-migration discipline
Replace all 16 table files with the ~24 v2 tables; delete the migration ladder (`_migrateTimeframesToSchoolYears`, `_schoolYearIdSql`, `_timeframe_grades_backup`, both `TableMigration` rewrites); single `onCreate` + `lib/core/database/seed/library_seed.dart` (new: 3 library grade scales, built-in grade categories, current school year, its two terms); `lib/core/database/app_database.drift` (new) for the term-overlap trigger, the `sessions` expression unique index, composite-FK `customConstraints`, and both views; drop `PRAGMA legacy = 4` from `cipher_opener.dart`; write `library.json` at creation (§1.2); delete `test/school_year_migration_test.dart` + `test/lesson_period_migration_test.dart`.

**The discipline that prevents the next 24-migration mess** — this is the whole
point of the reset and must land *with* the baseline, not later:
- Adopt `drift_dev schema dump` / `drift_dev schema generate`. At the 2.0.0 tag,
  check in `drift_schemas/v100.json`.
- From 2.1 on, any PR touching a table must: bump `schemaVersion`, add the
  `onUpgrade` step, dump the new schema, and regenerate the step-by-step
  migration tests. CI fails a table change without a matching schema dump.
- Migration steps get a **one-line comment naming the release** they shipped in,
  so a future reset can tell dead steps from live ones.
- No no-op version bumps (v1 wasted 15, 16, 20).

Depends: WS0.
Verify: `test/schema/` — `createAll` + `foreign_key_check` empty + `integrity_check` ok; seed assertions (fresh library = 3 library scales + 3 categories + current school year + 2 terms + `library.json`); one rejecting test per CHECK/UNIQUE, **including a cross-year composite-FK rejection** (a slot whose group belongs to another year); a checked-in golden `.sql` schema dump.

### WS2 — Repository + provider rewrite (LONG POLE)
Rewrite all 15 repositories to the v2 model. New: `PersonRepository`, `EnrollmentRepository` (split from `StudentRepository`), `SessionParticipationRepository` (absorbs attendance/homework/material repos), `GradeScaleRepository`, `GradeCategoryRepository`, `SchoolYearRepository` (rewritten, §2), `SchoolYearDayRepository`. Delete Dart weighted-average (use the view), `getPreferredSessionLabel`, `normalizeLessonDate`, the `23:59:59` range hack, the correlated-subquery session summaries. Every year-scoped query takes `schoolYearId` explicitly. Split `app_providers.dart` (390 lines) into `lib/core/providers/{repository,session,settings,school_year,sync}_providers.dart`. Screens updated only enough to compile — no screen refactors here.
Files: `lib/features/*/*_repository.dart` (all), `lib/core/providers/*`, `lib/shared/utils/formatting.dart` + `grade_categories.dart` (drop JSON parsers, keep pure formatting), every screen/widget that touches a repo (the real cost — wide fan-out).
Depends: WS1.
Verify: per-repository unit tests on `AppDatabase.test(NativeDatabase.memory())`, each seeding a minimal graph. Named-bug regression tests: two lessons/day no longer double-count; `markAbsent` leaves homework/material intact; editing a session label keeps its grades; `group_student_averages` matches a hand calc; attendance rate ignores `school_year_days`.
Mitigation: keep repo method names/signatures close to v1 where surviving semantics allow; land in slices behind a compiling build.

### WS3 — Security metadata v2 + SQLCipher 4 + delete v1 branches
`SecurityMetadata` v2-only — delete `createLegacy` (×2), every `supportsRecovery`/`!supportsRecovery` guard, `verifierSalt/Bytes`, `databaseSalt`, `integritySalt`, `_legacyStorageKey`+`getLegacyPassphrase`+`clearLegacyPassphrase`, `_legacyWebDavPasswordKey`, `bootstrapSecurity(includeRecoveryKey:false)`. `IntegrityManifest` gains `version`. Missing `.integrity.json` becomes **fatal** (no silent bypass). PBKDF2 iteration-count upgrade hook on unlock. New DBs are SQLCipher 4 (opener from WS1).
Files: `lib/core/security/key_service.dart`, `app_session_controller.dart` unlock path.
Depends: WS0 (independent of schema).
Verify: `test/security/` — bootstrap→verify→unlock→rotate→recover round-trip, v2-only; integrity-missing rejected; iteration upgrade rewraps; **a v1-era SQLCipher-3 file is rejected with `unsupportedLibrary`, not `invalidPassphrase`** (§1.2).

### WS4 — settings → DB; delete the 5 SharedPreferences migration paths; collapse the 4 controllers
`settings` table + `LibrarySettingsRepository` (typed accessors). Delete `project_settings_store.dart`, `security_preferences_service.dart`, `library_backup_preferences_service.dart` entirely. `theme_controller`/`student_sort_controller`/`grade_system_controller` → one `@riverpod SettingsNotifier`; `themeModeProvider` etc. become `.select` views.
**Chicken/egg**: `lockOnBackground`, `inactivityTimeout`, `biometricEnabled` are read *before* the DB is open → keep exactly those three in a tiny plaintext `lib/core/storage/app_prefs.dart` (`.prefs.json`, low sensitivity). Everything else → encrypted DB. Grade systems → the `grade_scales` tables. `shared_preferences` retained for exactly one thing: the `db_file_path` library pointer in `database_path_service.dart` (allowlisted).
Depends: WS1 (table), WS2 (providers), WS3 (security toggles).
Verify: settings round-trip; `SettingsNotifier` transitions; theme/sort/grade-system UI parity; a guard test that `shared_preferences` is imported in exactly one file.

### WS5 — School year as the spine (§2)
`ActiveSchoolYear` notifier + resolution order; `settings['active_school_year_id']`; the year switcher in `AppScaffold`; read-only mode for archived years; year-scoping every list screen (`/timetable`, `/groups`, `/notes`, `/lists`); `/years` promoted to a top-level route with the year overview (terms, holidays, groups, coverage warnings); `school_year_days` CRUD + timetable/statistics integration; the **rollover flow** (§2.5) as a transactional `SchoolYearRolloverService` + a multi-step sheet; person detail with cross-year enrollment history (§2.7) on `person_year_summary`.
Files: `lib/features/school_years/**` (largely new), `lib/shared/widgets/app_scaffold.dart`, `lib/shared/router/app_router.dart`, `lib/features/groups/groups_screen.dart` (year scoping; the old clone action folds into rollover), `lib/features/schedule/weekly_timetable_screen.dart`, `lib/features/students/student_detail_screen.dart`.
Depends: WS2 (repos), WS4 (the active-year setting). Its *schema* half (composite FKs, `school_year_days`, `group_grade_categories`, `school_year_id` on notes/checklists) lands in **WS1** — tables cannot be added after 2.0.0 without a migration, so they must be right at the baseline.
Verify: rollover golden test (carry 2 of 3 groups → new groups, new enrollments on the *same* `people`, slots and weights copied, old sessions untouched, all in one transaction, rollback on failure); switching years re-scopes every list screen (widget tests); archived year blocks writes; attendance rate excludes holidays; a fresh library lands on a usable year with terms.

### WS6 — split god objects + Riverpod codegen
`app_session_controller.dart` (1515) → `SessionController` (DB lifecycle, lock/unlock, inactivity, background-lock, the §1.2 format-marker check) + `SecurityController` (integrity repair, biometric, recovery-key handoff, passphrase change) + `WebDavSyncController` (all WebDAV config, auto-export, periodic timer, auto-import, conflict, sync status, backup banner, revision tracking) — all `@riverpod` Notifiers. Remove `flutter_riverpod/legacy.dart`; migrate `student_detail_screen`'s `StateProvider`. Split oversized screens: `group_detail_screen.dart` (3155) → `lib/features/groups/detail/cards/*.dart`; likewise `student_detail_screen.dart` (2398), `settings_screen.dart` (1305), `weekly_timetable_screen.dart` (971), `lesson_mode_screen.dart` (947), `lesson_sections.dart` (909).
Also fold the scattered platform checks into one `lib/core/platform/platform_capabilities.dart` (`supportsBiometricUnlock`, `supportsAutoUpdate`, `supportsCustomLibraryFolder`, `supportsWindowManagement`). This is native housekeeping, not web groundwork: the divergence already exists and is currently expressed three different ways — `isDesktopPlatform` in `app_updater.dart:20`, `Platform.isAndroid` in `database_path_service.dart:24`, and an ad-hoc availability probe in `biometric_service.dart`. One source of truth makes the controllers testable with a fake.
Depends: WS2, WS4, WS5. **Highest merge-conflict surface — sequence last among refactors.**
Verify: isolated unit tests per controller (fake injected services); widget smoke tests that each split screen builds; analyze shows no `legacy.dart` import.

### WS7 — i18n restructure
Namespaced keys (`attendance.status.excused`, `grade.category.default.klassenarbeit`, `school_year.term.default.first`); ICU plurals via `easy_localization`'s `plural()`; typed domain-error enums (`ImportError`, `GradeParseError`) mapped to messages at the UI layer instead of throwing i18n-key strings; `name_key` resolution for seeded categories, seeded terms and seeded scales; WebUntis import column mapping from a setting (not hardcoded `langname`/`vorname` in `student_import_parser.dart:44`); avatar-editor `Locale('en')` fix.
Files: `assets/translations/{en,de}.json` (codemod-assisted restructure), `lib/main.dart`, every `.tr()` call site (mechanical), `student_import_parser.dart`, new error enums.
Depends: independent; do the JSON restructure early and rename call sites continuously.
Verify: en/de key-parity test; ICU plural rendering (0/1/many); "no exception message is a bare i18n key"; import parser with a custom column map; seeded names resolve in both locales.

### WS8 — `.classi` package-only cleanup + backup format v2
Delete every `isPackagePath()` bare-file branch in `database_path_service.dart` (`moveTo` → one directory move; `containerParentPathFor` dead if/else gone) and `library_backup_service.dart` (package-only restore). Backup `formatVersion: 2`; attribution/revision fields required; `library.json` included in the archive; `_readMetaSidecar` stops swallowing errors; drop the "fail open on missing revision" carve-out (`:294-298`); a real "this backup needs a newer Classi" error instead of the bare `!= 1` throw; a **formatVersion-1 archive is rejected with the §1.3 message**, not migrated.
Depends: WS6 (sync controller).
Verify: backup build→restore round-trip at formatVersion 2; a formatVersion-1 archive → explicit unsupported error; `moveTo` directory-move test; restore of a backup from another year's active state lands on a valid active year.

---

## 5. De-risk order

Dropping the migrator removes the old spine, so the order is now driven by the
long pole (WS2) and by what must be right *at the baseline* (WS1).

1. **WS0** — branch + deps, green, alone.
2. **WS1** — the full v2 schema **including every §2 school-year table and
   composite FK**. Getting this wrong is the one mistake 2.0.0 cannot cheaply
   undo, because from the tag onward every change costs a migration step. Review
   the schema against §2 and §3 before writing repositories.
3. **WS3** in parallel with WS1 (independent of tables).
4. **WS2** — repository rewrite, merged in slices. Expect this to dominate the
   calendar.
5. **WS4 → WS5.** WS5 is where the year work becomes visible; its schema half
   already shipped in WS1.
6. **WS6 → WS7 → WS8.**
There is no eighth step: with the web build dropped, WS8 is the last thing
between the branch and a release candidate.

---

## 6. Testing & CI

The previous draft's heaviest test asset (the migration corpus) is gone. What
replaces it:

- **Schema goldens** — checked-in `.sql` dump + `drift_schemas/v100.json`. A PR
  that changes a table and not the dump fails CI (WS1).
- **Constraint tests** — one rejecting case per CHECK / UNIQUE / composite FK.
  These are cheap and they are the only thing standing between a repository bug
  and silent corruption now that there is no v1 file to fall back on.
- **Repository unit tests** on `AppDatabase.test(NativeDatabase.memory())`, each
  seeding a minimal graph — the bulk of the suite.
- **Named-bug regressions** — one test per fixed defect in appendix A/C/D, named
  after the defect, so a future refactor cannot quietly reintroduce it.
- **Widget smoke tests** — every screen builds with a seeded library; every
  split screen from WS6 keeps its own.
- **`integration_test`** for three flows only: first-run setup → group →
  lesson → grade; backup export → wipe → restore; **year rollover**.
- **Performance smoke** — seed a realistic worst case (10 groups × 30 students ×
  3 years ≈ 5k grade entries + 3k participation rows) and assert the timetable,
  the group averages view and person detail stay under a fixed budget. The
  view-based averages are a rewrite of hot code; without a budget the regression
  ships silently.
- **CI matrix** — analyze + test on linux; `flutter build` for
  linux/macos/windows/android. No web job.

---

## 7. Risks

- **No fallback if 2.0.0 corrupts a library (new top risk).** Previously the v1
  file survived every migration path; now the only copy of a teacher's data is
  the live v2 library. Mitigations, all required before tagging: an automatic
  backup before *any* future schema upgrade; `PRAGMA integrity_check` on open
  with a real error path; a visible, nagging prompt to configure file or WebDAV
  backup during first-run setup; never delete a library from within the app
  without an explicit typed confirmation.
- **The clean break is a product risk, not just a technical one (§1.3).** An
  unopenable library after a routine update is the worst experience this app can
  deliver. `library.json` + `UnsupportedLibraryScreen` + release notes + a
  downloadable 1.x are not optional polish.
- **Schema mistakes are now permanent-ish.** With one `onCreate` baseline and no
  migrator, anything wrong at the 2.0.0 tag costs a real migration step forever
  after. Hence: WS1 carries the whole §2 school-year schema, and the schema
  review gate in the de-risk order is a hard gate.
- **Repository rewrite fan-out is the long pole.** Every screen reads a repo.
  Keep method signatures close to v1; land in slices; don't also refactor screens
  in WS2.
- **Year-scoping is easy to half-do.** A single screen that forgets the active
  year shows last year's data as if it were current — a *quiet* wrong answer, the
  worst kind. Enforce by making `schoolYearId` a required parameter on every
  year-scoped repository method (a missing argument becomes a compile error,
  not a bug) and by widget-testing the switch on every list screen.
- **Rollover is destructive-adjacent.** It writes a lot of rows in one go. One
  transaction, a dry-run summary before committing, and a golden test that the
  outgoing year is byte-identical afterwards.
- **Grade-category scope change (§2.6) widens WS2.** It is the right model, but
  it touches sessions, grade entries, the averages view and the group editor.
  Decide before WS1 — it is a schema decision, not a refactor.
- **GDPR erasure vs. history.** `people` CASCADE means deleting a person erases
  their grades across every year. That is the correct behaviour for an erasure
  request and the wrong behaviour for a mis-tap. Only the explicit erasure action
  may reach it; "remove from group" sets `enrollments.status = 'left'`.
- **Big-bang tooling churn.** drift bump + Riverpod codegen + `storeDateTimeAsText`
  at once will thrash — WS0 lands alone first.
- **i18n rename rot.** ~458 keys × many call sites — codemod the JSON, guard with
  a key-parity test.
---

## 8. Release & rollout

- **Version:** 2.0.0, new `version_code` line. `main` keeps receiving 1.x
  patches until 2.0 is out; the last 1.x build stays downloadable indefinitely
  (GitHub release, pinned link from `UnsupportedLibraryScreen`).
- **Pre-announcement:** a 1.x point release that says, in-app, that 2.0 will use
  a new library format and that existing libraries will keep working in 1.x.
  Cheap, and it converts a support incident into an expectation.
- **Store listings** (Play, and the desktop distribution): note the break in the
  release notes *and* the description, not only the changelog.
- **Docs:** `README` + `doc/` get a "Classi 1.x libraries" section, mirroring
  §1.3, before the tag.
- **Rollback plan:** none at the data level, by design — which is exactly why
  §7's backup mitigations are mandatory rather than nice-to-have.

---

## 9. Manual end-to-end (before tagging 2.0.0, per platform)

1. Fresh install → setup (passphrase + recovery key) → lands on the current
   school year, with two seeded terms, `library.json` written.
2. Point the app at a 1.x `.classi` directory → `UnsupportedLibraryScreen`, clear
   message, 1.x link, **v1 files untouched on disk** (verify by checksum).
3. Create group (pick scale template + category weights) → add students (manual +
   WebUntis paste with custom column map).
4. Weekly timetable → fill a term → add a holiday week → confirm the timetable
   greys it out and offers no lesson.
5. Lesson mode for today → attendance (present/absent/late, excused) + homework +
   material → grades against the scale → session summary + weighted average
   correct → attendance rate ignores the holiday week.
6. Second lesson, same group, same day, different period → no double-count.
7. Term grades screen → enter final grades.
8. Notes (todo + multi-student) + checklist (auto names + free item) — confirm
   both are scoped to the active year.
9. Seating plan (default set on group).
10. **Year rollover**: start next year → carry 2 of 3 groups → new year becomes
    active → carried groups have the same people as new enrollments, copied slots
    and weights → switch back to the old year → it is read-only once archived,
    and its sessions/grades are unchanged.
11. Person detail → cross-year history shows both years.
12. Settings: theme, sort, security toggles, WebDAV → export backup → wipe →
    restore (formatVersion 2) → data intact, active year restored.
13. Move library to another folder → reopen (desktop; on Android confirm the
    folder picker is absent and libraries list from app-specific storage).

---

## Appendix — full findings inventory (from exploration)

### A. Database schema issues
Migration history (`app_database.dart:94-240`) collapsible into one `onCreate`; versions 15/16/20 were no-op bumps; the two `test/*_migration_test.dart` files go away.
1. **No indexes anywhere** — every FK filter and cascade is a table scan.
2. **Dead column** `students.seatIndex` (v10, never read/written).
3. **JSON-blob "tables"**: `groups.gradeScaleJson` + `gradeCategoriesJson`; `students.avatarJson`; `notes.studentIdsJson` + scalar `studentId` (dual, no RI, stale ids, O(all) Dart filter); `list_items.studentIdsJson` + scalar `studentId`.
4. **Denormalized copies**: `sessions.categoryName`, `grade_entries.categoryName` (stale on rename); `grade_entries.sessionLabel` as a join key with no `session_id` FK (editing a label silently detaches grades); `school_years.label`.
5. **Magic values**: `colorHex` TEXT; grade `value`/`grade` free TEXT re-parsed at read; `sessions.period* = 0` sentinel; `attendance.isAbsent` (default **true**) + `isExcused`; `homework.hadHomework`/`material.hadMaterial` (default true, tri-state via row presence); `notes.isTodo`+`todoDone`+`todoDoneAt`; `seating_plans.isDefault` unenforced.
6. **Dates**: all DateTimeColumns = unix epoch seconds; `date` columns store local-midnight DateTime, re-normalized in every repo before `.equals()` — TZ/DST-fragile; range queries use `23:59:59`; migration SQL uses `localtime` strftime; `createdAt` written inconsistently (SQL default vs `DateTime.now()`).
7. **Missing unique constraints** emulated in Dart: `grade_entries`, `attendance_logs`, `homework_logs`, `material_logs`, `timeframes`.
8. **Weak links**: `lesson_slots` not year-scoped; `lists.groupId` nullable+cascade; `seating_plan_positions` default (0,0) collisions.
9. **Naming**: `_table` suffix ×16; 3 data-class naming schemes; "list" vs "checklist"; `sessionLabel` vs `label`.
10. **Timeframe overlap detection in Dart** ("Drift 2.32.1 can't compare dates", `timeframe_repository.dart:75-88`).
11. **School years are inert** — a nullable `groups.schoolYearId` and a settings sub-screen; nothing scopes to a year, no holidays, no rollover, `timeframes` were group-scoped until v23 and are still not the app's frame. §2 is the fix.

### B. Sidecar files
- `.settings.json` — plaintext, unencrypted, next to encrypted DB; holds theme, sort, full grade-system definitions (a table as JSON), security toggles, WebDAV url/username, backup schedule + timestamps. Every key has a SharedPreferences→settings.json "legacy" migration. Leak: webdav username, which security features are on, grade-system names readable without passphrase.
- `.security.json` — PBKDF2/AES-GCM key-wrapping metadata; must stay external. `version` 1 (legacy, no recovery key) vs 2. All `!supportsRecovery`/`createLegacy`/`getLegacyPassphrase` branches (`key_service.dart:132-234,366-377`) are v1 compat — all deleted in WS3.
- `.integrity.json` — HMAC file hashes; correctly external; absence currently = "skip check" (bypass foothold).
- **No format marker** — nothing in a `.classi` directory says which app version wrote it, which is why §1.2 adds `library.json`.

### C. Domain model
The SQLite schema **is** the external data format (WebDAV backup zips `data.db` + `backup.json`). C1 grades → normalize (`grade_scales`+`grade_scale_entries`+`grade_categories`+`group_grade_categories`; `grade_entries.session_id` FK; `numeric_value` materialized; weighted avg as a view; drop dual-format parser; unify `timeframe_grades`). C2 session-centric logs (`session_participation`, unique `(session,student)`, status enum; kills double-count + `markAbsent` data-loss + correlated subqueries). C3 `sessions.slot_id` FK + timetable versioning (`valid_from`/`valid_to`) + `periods` table. C4 `people` + `enrollments` (soft-delete via status; rollover reuses people — §2.5). C5 `note_students`/`checklist_item_students` junctions. C6 `groups.school_year_id` NOT NULL; `timeframes`→`terms` with DB-enforced non-overlap; Aug–Jul boundary → setting that *proposes* year dates; `school_year_days`; composite FKs. C7 German defaults (in column DDL of 4 tables, repo param defaults, v18 migration SQL, Dart constants) → locale-aware seed rows + `name_key`; WebUntis locale-locked headers → configurable mapping. C8 dates as TEXT `'YYYY-MM-DD'`, no TZ. C9 i18n: 2 flat files ~455 keys, no namespacing, no ICU plurals, parser errors thrown as raw keys.

### D. Code-level cruft
- **D1** SharedPreferences→settings legacy migrations in 5 files (`security_preferences_service.dart` whole, `library_backup_preferences_service.dart` whole with duplicated `_read*`/`_write*` helpers, `theme_controller.dart`, `student_sort_controller.dart`, `grade_system_controller.dart`); `project_settings_store.dart` unversioned free-form JSON.
- **D2** `key_service.dart` v1 metadata branches, dead `_legacyStorageKey='db_passphrase'`, `IntegrityManifest` has no version, `_defaultIterations` never upgraded, `bootstrapSecurity(includeRecoveryKey:false)` no caller.
- **D3** `cipher_opener.dart:12` `PRAGMA legacy = 4` (SQLCipher 3.x on-disk).
- **D4** `library_backup_service.dart` `_backupFormatVersion = 1` exact check, all `?`-optional attribution/revision fields, `_readMetaSidecar` swallows errors, "fail open on missing revision" carve-out, package-vs-bare-file restore branch, non-atomic `.classi-sync.lock`.
- **D5** `database_path_service.dart` bare-file `.classi` format branches everywhere; `containerParentPathFor` dead if/else.
- **D6** Riverpod 3 legacy APIs: `app_providers.dart:5` `legacy.dart` `ChangeNotifierProvider` (×5), `student_detail_screen.dart` `StateProvider`; no `@riverpod` codegen.
- **D7** God objects: `app_providers.dart` 390 lines/~50 providers; `app_session_controller.dart` 1515 lines/~30 fields/60+ methods; `group_detail_screen.dart` 3155; `student_detail_screen.dart` 2398; `settings_screen.dart` 1305; plus `weekly_timetable_screen.dart` 971, `lesson_mode_screen.dart` 947, `lesson_sections.dart` 909.
- **D8** `lesson_mode_screen.dart:465` grade-entry session-label fallback → `grade_repository.getPreferredSessionLabel` (majority-vote reconstruction).
- **D9** notes/list_items dual student-link write.
- **D10** Platform divergence expressed three different ways: `isDesktopPlatform` (`app_updater.dart:20`, also consumed by `main.dart`, `app.dart`, `settings_screen.dart`), `Platform.isAndroid` (`database_path_service.dart:24`), and an ad-hoc probe in `biometric_service.dart`. Consolidated into `PlatformCapabilities` in WS6.
- **D11** Group cloning (`groups_screen.dart:301`) is the only cross-year affordance and it duplicates students rather than re-enrolling people — superseded by rollover (§2.5).

### E. Why there is no web build (investigated, dropped)

Kept so this is re-opened only by new upstream facts, not by optimism. Verified
against `drift 2.34.3` / `sqlite3 3.5.2` as vendored in this repo:

1. **Encryption cannot reach the database.** On web, drift opens the database in
   a worker. `WasmDatabase.open`'s `localSetup` is documented (`drift/lib/wasm.dart:140`)
   as called *only* if the database opens in the current JS context — "It is
   likely that the database will actually be opened in a web worker… `localSetup`
   would not be called in that case." The worker-side hook,
   `WasmDatabase.workerMainForOpen({WasmDatabaseSetup? setupAllDatabases})`, takes
   `typedef WasmDatabaseSetup = void Function(CommonDatabase)` — **synchronous,
   parameterless, compiled into the worker**. There is no supported channel for a
   passphrase typed in the main context to reach the `PRAGMA key` that must run
   in the worker. Classi's whole security model is encryption-at-rest, so an
   unencrypted web tier is not a lesser version of the product, it is a different
   product.
2. **Upstream support is experimental.** `sqlite3` CHANGELOG: "__Experimentally__
   support encryption on the web through SQLite Multiple Ciphers."
3. **The good storage mode is Firefox-only.** `WasmStorageImplementation.opfsShared`
   needs a shared worker to spawn a nested dedicated worker — per drift's own
   docs, unimplemented in Chrome (crbug 1088481) and Safari. Chrome and Safari
   fall to `opfsLocks`, which *requires* cross-origin isolation (COOP/COEP)
   headers; without them the fallback is `unsafeIndexedDb`, which drift documents
   as unable to "prevent data races if your app is opened in multiple tabs".
   Given §7's "no fallback copy of the data", a two-tab race is total loss.
4. **Half the plugin set has no web implementation**: `window_manager`,
   `local_auth`, `updat`, `webdav_client`, `path_provider`.
5. **No product story survived contact.** With WebDAV CORS-blocked and OPFS
   evictable by the browser, the only sync path is manual backup export/import —
   acceptable for a demo, poor for the teacher's primary device, and the demo
   case does not justify the engineering.

**Re-open only if**: drift ships an async or parameterised worker setup hook
(the fix for point 1), *and* Chrome ships nested workers in shared workers or
COOP/COEP hosting is a given. Points 4 and 5 are then ordinary work.
