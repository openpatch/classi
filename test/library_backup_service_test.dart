import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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

  test('buildBackupArchive embeds device attribution in the manifest', () async {
    final archiveBytes = await service.buildBackupArchive(
      sourceLibraryDirectory.path,
      deviceId: 'device-123',
      deviceName: 'Kitchen iPad',
    );

    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final manifestFile = archive.findFile('backup.json')!;
    final manifestJson =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;

    expect(manifestJson['deviceId'], 'device-123');
    expect(manifestJson['deviceName'], 'Kitchen iPad');
  });

  test(
    'buildBackupArchive omits device attribution when not provided',
    () async {
      final archiveBytes = await service.buildBackupArchive(
        sourceLibraryDirectory.path,
      );

      final archive = ZipDecoder().decodeBytes(archiveBytes);
      final manifestFile = archive.findFile('backup.json')!;
      final manifestJson =
          jsonDecode(utf8.decode(manifestFile.content as List<int>))
              as Map<String, dynamic>;

      expect(manifestJson.containsKey('deviceId'), isFalse);
      expect(manifestJson.containsKey('deviceName'), isFalse);
    },
  );

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

  test('isSyncLockExpired is false for a freshly acquired lock', () {
    final now = DateTime.utc(2026, 5, 7, 8, 0);
    final acquiredAt = now.subtract(const Duration(seconds: 5));

    expect(
      LibraryBackupService.isSyncLockExpired(acquiredAt, now: now),
      isFalse,
    );
  });

  test('isSyncLockExpired is true once the lease has passed', () {
    final now = DateTime.utc(2026, 5, 7, 8, 0);
    final acquiredAt = now.subtract(const Duration(minutes: 3));

    expect(
      LibraryBackupService.isSyncLockExpired(acquiredAt, now: now),
      isTrue,
    );
  });
}
