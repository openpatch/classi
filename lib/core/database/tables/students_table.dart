import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'groups_table.dart';

class StudentsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get firstName => text().withLength(min: 1, max: 100)();

  TextColumn get lastName => text().withLength(min: 1, max: 100)();

  TextColumn get groupId =>
      text().references(GroupsTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get originNote => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get avatarJson => text().nullable()();

  IntColumn get seatIndex => integer().nullable()();
}
