import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/storage/database_path_service.dart';
import '../../../core/storage/library_backup_service.dart';

/// Exam PDFs (task sheet, unfilled Erwartungshorizont) stored next to the
/// library, outside the encrypted database.
///
/// Files are named by their SHA-256, so they never change once written,
/// duplicates are free, and a damaged file is detectable. Neither contains
/// student data; filled Erwartungshorizonte are never stored here.
class ExamDocumentStore {
  ExamDocumentStore(this.databasePath);

  final String databasePath;

  Directory get directory =>
      Directory(DatabasePathService.documentsDirectoryFor(databasePath));

  File fileFor(String sha256) => File(p.join(directory.path, '$sha256.pdf'));

  /// Stores [source] and returns its hash. Writing is atomic: a partial file
  /// is never visible under the final name.
  Future<String> put(File source) async {
    final bytes = await source.readAsBytes();
    final hash = sha256.convert(bytes).toString();
    final target = fileFor(hash);
    if (await target.exists()) return hash;
    await directory.create(recursive: true);
    final temp = File('${target.path}.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target.path);
    return hash;
  }

  /// The stored file for [hash], or `null` when it is missing or damaged
  /// (for example not yet synced to this device).
  Future<File?> read(String? hash) async {
    if (hash == null) return null;
    final file = fileFor(hash);
    if (!await file.exists()) return null;
    final actual = sha256.convert(await file.readAsBytes()).toString();
    return actual == hash ? file : null;
  }

  /// Deletes stored documents no exam references any more.
  Future<int> collectGarbage(Set<String> referenced) async {
    if (!await directory.exists()) return 0;
    var removed = 0;
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name.endsWith('.tmp')) {
        await entity.delete();
        continue;
      }
      if (!isDocumentFileName(name)) continue;
      if (referenced.contains(p.basenameWithoutExtension(name))) continue;
      await entity.delete();
      removed++;
    }
    return removed;
  }
}
