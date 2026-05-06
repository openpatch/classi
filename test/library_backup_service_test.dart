import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:classi/core/storage/library_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Directory sourceLibraryDirectory;
  late LibraryBackupService service;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('classi-backup-test');
    sourceLibraryDirectory = Directory('${tempDirectory.path}/source.classi');
    await sourceLibraryDirectory.create(recursive: true);
    service = LibraryBackupService();

    await File('${sourceLibraryDirectory.path}/data.db').writeAsString('db');
    await File(
      '${sourceLibraryDirectory.path}/data.db-wal',
    ).writeAsString('wal');
    await File(
      '${sourceLibraryDirectory.path}/data.db-shm',
    ).writeAsString('shm');
    await File(
      '${sourceLibraryDirectory.path}/data.db.security.json',
    ).writeAsString('security');
    await File(
      '${sourceLibraryDirectory.path}/data.db.integrity.json',
    ).writeAsString('integrity');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('buildBackupArchive creates a portable archive', () async {
    final archiveBytes = await service.buildBackupArchive(
      sourceLibraryDirectory.path,
    );

    expect(archiveBytes, isNotEmpty);
  });

  test(
    'restoreBackupFromBytes restores database artifacts into a package folder',
    () async {
      final archiveBytes = await service.buildBackupArchive(
        sourceLibraryDirectory.path,
      );

      final importedPath = '${tempDirectory.path}/imported.classi';
      await service.restoreBackupFromBytes(
        bytes: archiveBytes,
        destinationDatabasePath: importedPath,
      );

      expect(await File('$importedPath/data.db').readAsString(), 'db');
      expect(await File('$importedPath/data.db-wal').readAsString(), 'wal');
      expect(await File('$importedPath/data.db-shm').readAsString(), 'shm');
      expect(
        await File('$importedPath/data.db.security.json').readAsString(),
        'security',
      );
      expect(
        await File('$importedPath/data.db.integrity.json').readAsString(),
        'integrity',
      );
    },
  );
}
