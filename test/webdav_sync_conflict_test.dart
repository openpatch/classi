import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'package:classi/core/storage/library_backup_service.dart';

/// An in-memory stand-in for a WebDAV server, so the export path — conflict
/// detection, conflict-copy naming, archiving and pruning — can be exercised
/// end to end without a network.
class _InMemoryWebDavClient extends webdav.Client {
  _InMemoryWebDavClient()
    : super(
        uri: 'memory://',
        c: webdav.WdDio(),
        auth: webdav.Auth(user: '', pwd: ''),
      );

  // dio's CancelToken is not a direct dependency of this package; the
  // overrides widen it to dynamic, which is a legal supertype here.
  final Map<String, Uint8List> files = {};
  final Map<String, DateTime> modified = {};

  /// Advanced by hand so archived copies get distinct timestamps without the
  /// test having to sleep.
  DateTime clock = DateTime.utc(2026, 5, 1, 12);

  List<String> get backupNames => [
    for (final path in files.keys)
      if (LibraryBackupService.isBackupFilePath(path)) p.basename(path),
  ]..sort();

  @override
  Future<void> mkdirAll(String path, [dynamic cancelToken]) async {}

  @override
  Future<List<webdav.File>> readDir(String path, [dynamic cancelToken]) async {
    final dir = path.endsWith('/') ? path : '$path/';
    return [
      for (final entry in files.entries)
        if (p.dirname(entry.key) == p.dirname('${dir}x'))
          webdav.File(
            path: entry.key,
            name: p.basename(entry.key),
            isDir: false,
            size: entry.value.length,
            mTime: modified[entry.key],
          ),
    ];
  }

  @override
  Future<webdav.File> readProps(String path, [dynamic cancelToken]) async {
    final bytes = files[path];
    if (bytes == null) throw StateError('404 $path');
    return webdav.File(
      path: path,
      name: p.basename(path),
      isDir: false,
      size: bytes.length,
      mTime: modified[path],
    );
  }

  @override
  Future<List<int>> read(
    String path, {
    void Function(int, int)? onProgress,
    dynamic cancelToken,
  }) async {
    final bytes = files[path];
    if (bytes == null) throw StateError('404 $path');
    return bytes;
  }

  @override
  Future<void> write(
    String path,
    Uint8List data, {
    void Function(int, int)? onProgress,
    dynamic cancelToken,
  }) async {
    files[path] = data;
    modified[path] = clock;
  }

  @override
  Future<void> rename(
    String oldPath,
    String newPath,
    bool overwrite, [
    dynamic cancelToken,
  ]) async {
    final bytes = files.remove(oldPath);
    if (bytes == null) throw StateError('404 $oldPath');
    files[newPath] = bytes;
    modified[newPath] = modified.remove(oldPath) ?? clock;
  }

  @override
  Future<void> remove(String path, [dynamic cancelToken]) async {
    files.remove(path);
    modified.remove(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;
  late Directory libraryDirectory;
  late LibraryBackupService service;
  late _InMemoryWebDavClient client;

  const serverPath = '/backups';

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('classi-sync-test');
    libraryDirectory = Directory('${tempDirectory.path}/class-8a.classi');
    await libraryDirectory.create(recursive: true);
    for (final entry in {
      'data.db': 'db',
      'data.db-wal': 'wal',
      'data.db-shm': 'shm',
      'data.db.security.json': 'security',
      'data.db.integrity.json': 'integrity',
    }.entries) {
      await File(
        '${libraryDirectory.path}/${entry.key}',
      ).writeAsString(entry.value);
    }
    service = LibraryBackupService();
    client = _InMemoryWebDavClient();
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<DateTime> export({
    required String deviceId,
    required String? parentRevision,
    int maxVersions = 3,
  }) => service.exportBackupToWebDav(
    client: client,
    sourceDatabasePath: libraryDirectory.path,
    serverPath: serverPath,
    maxVersions: maxVersions,
    deviceId: deviceId,
    deviceName: 'Device $deviceId',
    parentRevision: parentRevision,
  );

  Future<String?> canonicalRevision() async {
    final info = await service.getRemoteBackupDeviceInfo(
      client: client,
      remotePath: '$serverPath/class-8a.classi-backup',
    );
    return info.revision;
  }

  test('a device stuck in conflict refreshes one copy instead of leaving a new '
      'file behind on every sync', () async {
    // Device A publishes, device B publishes on top of it. A never saw B's
    // revision, so every A export from here on conflicts.
    await export(deviceId: 'device-a', parentRevision: null);
    final afterA = await canonicalRevision();
    client.clock = client.clock.add(const Duration(minutes: 1));
    await export(deviceId: 'device-b', parentRevision: afterA);

    for (var attempt = 0; attempt < 3; attempt++) {
      client.clock = client.clock.add(const Duration(minutes: 1));
      await expectLater(
        export(deviceId: 'device-a', parentRevision: afterA),
        throwsA(isA<WebDavSyncConflictException>()),
        reason: 'the conflict is unresolved, so it must keep being raised',
      );
    }

    final conflicts = [
      for (final name in client.backupNames)
        if (LibraryBackupService.isConflictBackupFileName(name)) name,
    ];
    expect(
      conflicts,
      ['class-8a_CONFLICT_device-a.classi-backup'],
      reason:
          'three conflicting syncs should refresh the one copy keyed on '
          'this device, not accumulate three timestamped files',
    );
  });

  test('a conflict reports where the changes were parked', () async {
    await export(deviceId: 'device-a', parentRevision: null);
    final afterA = await canonicalRevision();
    client.clock = client.clock.add(const Duration(minutes: 1));
    await export(deviceId: 'device-b', parentRevision: afterA);
    final afterB = await canonicalRevision();

    client.clock = client.clock.add(const Duration(minutes: 1));
    final error = await export(
      deviceId: 'device-a',
      parentRevision: afterA,
    ).then<Object?>((_) => null, onError: (Object e) => e);

    expect(error, isA<WebDavSyncConflictException>());
    final conflict = error! as WebDavSyncConflictException;
    expect(
      conflict.conflictRemotePath,
      '$serverPath/class-8a_CONFLICT_device-a.classi-backup',
    );
    expect(conflict.canonicalRevision, afterB);
    expect(conflict.conflictingDeviceName, 'Device device-b');
  });

  test('pruning keeps unresolved conflict copies', () async {
    await export(deviceId: 'device-a', parentRevision: null);
    final afterA = await canonicalRevision();

    // Device A parks its changes in a conflict copy...
    client.clock = client.clock.add(const Duration(minutes: 1));
    await export(deviceId: 'device-b', parentRevision: afterA);
    client.clock = client.clock.add(const Duration(minutes: 1));
    await expectLater(
      export(deviceId: 'device-a', parentRevision: afterA),
      throwsA(isA<WebDavSyncConflictException>()),
    );

    // ...and device B then syncs enough times to churn through the whole
    // archived-version budget.
    var parent = await canonicalRevision();
    for (var i = 0; i < 4; i++) {
      client.clock = client.clock.add(const Duration(minutes: 1));
      await export(deviceId: 'device-b', parentRevision: parent);
      parent = await canonicalRevision();
    }

    expect(
      client.backupNames,
      contains('class-8a_CONFLICT_device-a.classi-backup'),
      reason:
          'the conflict copy holds changes no other backup has, so pruning '
          'must not count it as superseded history',
    );
    final archived = [
      for (final name in client.backupNames)
        if (name != 'class-8a.classi-backup' &&
            !LibraryBackupService.isConflictBackupFileName(name))
          name,
    ];
    expect(
      archived.length,
      2,
      reason: 'maxVersions 3 keeps the canonical plus two archived copies',
    );
  });

  test(
    'listConflictCopyNames finds the other device\'s parked changes',
    () async {
      expect(
        await service.listConflictCopyNames(
          client: client,
          serverPath: serverPath,
          libraryName: 'class-8a',
        ),
        isEmpty,
      );

      await export(deviceId: 'device-a', parentRevision: null);
      final afterA = await canonicalRevision();
      client.clock = client.clock.add(const Duration(minutes: 1));
      await export(deviceId: 'device-b', parentRevision: afterA);
      client.clock = client.clock.add(const Duration(minutes: 1));
      await expectLater(
        export(deviceId: 'device-a', parentRevision: afterA),
        throwsA(isA<WebDavSyncConflictException>()),
      );

      // This is what device B runs on its own sync check: the canonical
      // backup is still B's own, so only this lookup can tell B that A's
      // newer changes are sitting unmerged next to it.
      expect(
        await service.listConflictCopyNames(
          client: client,
          serverPath: serverPath,
          libraryName: 'class-8a',
        ),
        ['class-8a_CONFLICT_device-a.classi-backup'],
      );
      expect(
        await service.listConflictCopyNames(
          client: client,
          serverPath: serverPath,
          libraryName: 'class-9b',
        ),
        isEmpty,
        reason: 'a conflict in one library must not flag another',
      );
    },
  );

  test(
    'archiving a resolved conflict clears it without discarding the content',
    () async {
      await export(deviceId: 'device-a', parentRevision: null);
      final afterA = await canonicalRevision();
      client.clock = client.clock.add(const Duration(minutes: 1));
      await export(deviceId: 'device-b', parentRevision: afterA);
      client.clock = client.clock.add(const Duration(minutes: 1));
      await expectLater(
        export(deviceId: 'device-a', parentRevision: afterA),
        throwsA(isA<WebDavSyncConflictException>()),
      );

      const conflictName = 'class-8a_CONFLICT_device-a.classi-backup';
      final parkedBytes = client.files['$serverPath/$conflictName']!;
      final parkedMeta = client.files['$serverPath/$conflictName.meta.json']!;

      await service.archiveResolvedConflictCopy(
        client: client,
        serverPath: serverPath,
        conflictFileName: conflictName,
        resolvedAt: DateTime.utc(2026, 5, 2, 9),
      );

      expect(
        await service.listConflictCopyNames(
          client: client,
          serverPath: serverPath,
          libraryName: 'class-8a',
        ),
        isEmpty,
        reason: 'both devices should stop reporting a resolved conflict',
      );
      const archivedName = 'class-8a_20260502T090000Z.classi-backup';
      expect(client.backupNames, contains(archivedName));
      expect(
        client.files['$serverPath/$archivedName'],
        parkedBytes,
        reason: 'resolving picks a side; it must not destroy the other one',
      );
      expect(
        jsonDecode(
          utf8.decode(client.files['$serverPath/$archivedName.meta.json']!),
        ),
        jsonDecode(utf8.decode(parkedMeta)),
        reason: 'the sidecar has to follow the backup it describes',
      );
    },
  );
}
