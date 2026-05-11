import 'package:flutter_test/flutter_test.dart';

import 'package:classi/core/storage/database_path_service.dart';

void main() {
  test(
    'normalizeDatabasePackageName appends classi extension when missing',
    () {
      expect(
        DatabasePathService.normalizeDatabasePackageName('klasse-8a'),
        'klasse-8a.classi',
      );
    },
  );

  test('normalizeDatabasePackageName keeps existing classi extension', () {
    expect(
      DatabasePathService.normalizeDatabasePackageName('klasse-8a.classi'),
      'klasse-8a.classi',
    );
  });

  test('databaseFilePathFor resolves the internal database file', () {
    expect(
      DatabasePathService.databaseFilePathFor('/tmp/classi.classi'),
      '/tmp/classi.classi/data.db',
    );
  });

  test('artifactPathsFor includes package database and security sidecars', () {
    expect(DatabasePathService.artifactPathsFor('/tmp/classi.classi'), [
      '/tmp/classi.classi/data.db',
      '/tmp/classi.classi/data.db-wal',
      '/tmp/classi.classi/data.db-shm',
      '/tmp/classi.classi/data.db.settings.json',
      '/tmp/classi.classi/data.db.security.json',
      '/tmp/classi.classi/data.db.integrity.json',
    ]);
  });
}
