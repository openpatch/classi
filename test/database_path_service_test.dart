import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

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

  test('listLibraryPackages returns only .classi directories, sorted', () async {
    final tempDir = await Directory.systemTemp.createTemp('classi_libraries');
    addTearDown(() => tempDir.delete(recursive: true));

    await Directory(p.join(tempDir.path, 'beta.classi')).create();
    await Directory(p.join(tempDir.path, 'alpha.classi')).create();
    await Directory(p.join(tempDir.path, 'not-a-library')).create();
    await File(p.join(tempDir.path, 'stray.classi')).create();

    final service = _FixedLibrariesDirectoryService(tempDir.path);

    expect(await service.listLibraryPackages(), [
      p.join(tempDir.path, 'alpha.classi'),
      p.join(tempDir.path, 'beta.classi'),
    ]);
  });

  test('listLibraryPackages returns empty when directory is missing', () async {
    final service = _FixedLibrariesDirectoryService(
      p.join(Directory.systemTemp.path, 'classi_does_not_exist_${DateTime.now().microsecondsSinceEpoch}'),
    );
    expect(await service.listLibraryPackages(), isEmpty);
  });
}

class _FixedLibrariesDirectoryService extends DatabasePathService {
  _FixedLibrariesDirectoryService(this._directory);

  final String _directory;

  @override
  Future<String> defaultLibrariesDirectory() async => _directory;
}
