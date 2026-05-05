import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class GroupsTable extends Table {
  TextColumn get id => text().clientDefault(() => const Uuid().v4())();

  @override
  Set<Column> get primaryKey => {id};

  TextColumn get name => text().withLength(min: 1, max: 100)();

  TextColumn get colorHex => text().withDefault(const Constant('#FF1E88E5'))();

  TextColumn get gradeScaleJson =>
      text().withDefault(const Constant('["1","2","3","4","5","6"]'))();

  TextColumn get gradeCategoriesJson => text().withDefault(
    const Constant(
      '[{"id":"sonstige-mitarbeit","name":"Sonstige Mitarbeit","weight":1.0,"color":"#FF1E88E5"},{"id":"klassenarbeit","name":"Klassenarbeit","weight":3.0,"color":"#FF8E24AA"},{"id":"praesentation","name":"Präsentation","weight":2.0,"color":"#FF00897B"}]',
    ),
  )();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get archivedAt => dateTime().nullable()();
}
