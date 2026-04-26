import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:classi/core/storage/library_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Directory sourceLibraryDirectory;
  late Directory exportDirectory;
  late LibraryBackupService service;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('classi-backup-test');
    sourceLibraryDirectory = Directory('${tempDirectory.path}/source.classi');
    exportDirectory = Directory('${tempDirectory.path}/exports');
    await sourceLibraryDirectory.create(recursive: true);
    await exportDirectory.create(recursive: true);
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

  test('exportBackup writes a portable archive file', () async {
    final exportedPath = await service.exportBackup(
      sourceDatabasePath: sourceLibraryDirectory.path,
      destinationFolderPath: exportDirectory.path,
    );

    expect(exportedPath, endsWith('source.classi-backup'));
    expect(await File(exportedPath).exists(), isTrue);
  });

  test(
    'importBackup restores database artifacts into a package folder',
    () async {
      final exportedPath = await service.exportBackup(
        sourceDatabasePath: sourceLibraryDirectory.path,
        destinationFolderPath: exportDirectory.path,
      );

      final importedPath = '${tempDirectory.path}/imported.classi';
      await service.importBackup(
        backupFilePath: exportedPath,
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
