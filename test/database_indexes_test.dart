import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/database/database_indexes.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The index names the app expects to exist, parsed out of the DDL so the two
/// can never disagree.
Set<String> _expectedIndexNames() {
  final pattern = RegExp(r'CREATE INDEX IF NOT EXISTS (\w+)');
  return {
    for (final statement in databaseIndexStatements)
      pattern.firstMatch(statement)!.group(1)!,
  };
}

Future<Set<String>> _indexNames(AppDatabase database) async {
  final rows = await database
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name LIKE 'idx_%'",
      )
      .get();
  return {for (final row in rows) row.read<String>('name')};
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('a fresh library has every index', () async {
    // Force the schema to be created.
    await database.customSelect('SELECT 1').getSingle();

    expect(await _indexNames(database), _expectedIndexNames());
  });

  test('every index statement names a table that exists', () async {
    await database.customSelect('SELECT 1').getSingle();

    final tables =
        (await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'table'",
                )
                .get())
            .map((row) => row.read<String>('name'))
            .toSet();

    final pattern = RegExp(r'ON (\w+) \(');
    for (final statement in databaseIndexStatements) {
      final table = pattern.firstMatch(statement)!.group(1)!;
      expect(
        tables,
        contains(table),
        reason: 'Index statement targets a missing table: $statement',
      );
    }
  });

  test('index creation is idempotent', () async {
    await database.customSelect('SELECT 1').getSingle();

    for (final statement in databaseIndexStatements) {
      await database.customStatement(statement);
    }

    expect(await _indexNames(database), _expectedIndexNames());
  });
}
