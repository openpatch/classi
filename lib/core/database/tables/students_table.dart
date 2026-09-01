import 'package:drift/drift.dart';

import 'groups_table.dart';

class StudentsTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get firstName => text().withLength(min: 1, max: 100)();

  TextColumn get lastName => text().withLength(min: 1, max: 100)();

  /// Informal name a teacher actually calls the student by (German
  /// "Rufname"), shown instead of [firstName] wherever the surname is
  /// still displayed alongside it. `null` means "same as firstName".
  TextColumn get callName => text().nullable()();

  IntColumn get groupId =>
      integer().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get originNote => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get avatarJson => text().nullable()();

  IntColumn get seatIndex => integer().nullable()();

  /// The id this student has in WebUntis.
  ///
  /// This is what makes an attendance sync stable: absences come back keyed by
  /// WebUntis student id, and matching those on names alone would break on
  /// every marriage, umlaut and spelling correction. `null` for students that
  /// were not imported from WebUntis.
  IntColumn get webuntisStudentId => integer().nullable()();
}
