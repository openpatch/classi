import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'groups_table.dart';
import 'students_table.dart';

@DataClassName('TeacherNote')
class NotesTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get body => text().withLength(min: 1, max: 5000)();

  TextColumn get groupId => text().nullable().references(
    GroupsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get studentId => text().nullable().references(
    StudentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  TextColumn get studentIdsJson => text().nullable()();

  BoolColumn get isTodo => boolean().withDefault(const Constant(false))();

  BoolColumn get todoDone => boolean().withDefault(const Constant(false))();

  DateTimeColumn get todoDoneAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();
}
