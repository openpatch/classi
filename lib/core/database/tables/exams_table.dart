import 'package:drift/drift.dart';

import 'groups_table.dart';

/// A written exam of one group, graded per expectation.
///
/// The structure (expectations) lives in `exam_expectations_table`; task
/// groups, elective groups and titles are small and always read together with
/// the exam, so they are kept as JSON in [structureJson].
@DataClassName('Exam')
class ExamsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get title => text().withLength(min: 1, max: 200)();

  DateTimeColumn get date => dateTime()();

  /// Grade category the resulting grade entries are filed under.
  TextColumn get categoryId => text()();

  TextColumn get categoryName => text()();

  /// `manual` or `typst`. A Typst-linked exam takes its structure and grade
  /// scale from the document; both are read-only in the app.
  TextColumn get source => text().withDefault(const Constant('manual'))();

  /// Snapshot of the grading scheme: thresholds from percent to grade label.
  /// Copied from a template (manual) or derived from the Typst scale.
  TextColumn get gradeSchemeJson => text()();

  /// Task groups, elective groups (with counted tasks) and task titles.
  TextColumn get structureJson => text().withDefault(const Constant('{}'))();

  /// Typst grade label -> grade label of the group's grade scale.
  TextColumn get gradeLabelMappingJson => text().nullable()();

  /// Hash of the last accepted assessio manifest, to notice document changes.
  TextColumn get manifestSha256 => text().nullable()();

  IntColumn get assessioFormat => integer().nullable()();

  DateTimeColumn get lastImportedAt => dateTime().nullable()();

  /// Content hashes of the stored PDFs (files in the library's documents
  /// folder, not in the database).
  TextColumn get taskSheetSha256 => text().nullable()();

  TextColumn get rubricSha256 => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this row was last modified. Used by the three-way sync merge to
  /// resolve concurrent edits to the same row (last-write-wins per row).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
