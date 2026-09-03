import 'package:classi/core/storage/library_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical backups are not conflicts', () {
    const entry = WebDavBackupEntry(
      fileName: 'class-8a.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a.classi-backup',
    );
    expect(entry.isConflict, isFalse);
  });

  test('archived backups are not conflicts', () {
    const entry = WebDavBackupEntry(
      fileName: 'class-8a_20260506T143200Z.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_20260506T143200Z.classi-backup',
    );
    expect(entry.isConflict, isFalse);
  });

  test('conflict copies are recognized', () {
    const entry = WebDavBackupEntry(
      fileName: 'class-8a_CONFLICT_20260507T080000Z.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_CONFLICT_20260507T080000Z.classi-backup',
    );
    expect(entry.isConflict, isTrue);
  });

  test('conflict copies keyed on the uploading device are recognized', () {
    const entry = WebDavBackupEntry(
      fileName: 'class-8a_CONFLICT_a1b2c3d4e5f60718.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_CONFLICT_a1b2c3d4e5f60718.classi-backup',
    );
    expect(entry.isConflict, isTrue);
  });

  test('archived names written without a trailing Z still resolve', () {
    // Earlier versions dropped the `Z` when stamping archived copies, and
    // those files are still sitting on people's servers.
    expect(
      LibraryBackupService.libraryNameForBackupFile(
        'class-8a_20260506T143200.classi-backup',
      ),
      'class-8a',
    );
    const entry = WebDavBackupEntry(
      fileName: 'class-8a_20260506T143200.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_20260506T143200.classi-backup',
    );
    expect(entry.isConflict, isFalse);
  });

  test('pendingConflictPairs matches a conflict to its canonical', () {
    const canonical = WebDavBackupEntry(
      fileName: 'class-8a.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a.classi-backup',
    );
    const newerConflict = WebDavBackupEntry(
      fileName: 'class-8a_CONFLICT_device-a.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_CONFLICT_device-a.classi-backup',
    );
    const olderConflict = WebDavBackupEntry(
      fileName: 'class-8a_CONFLICT_20260101T000000Z.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_CONFLICT_20260101T000000Z.classi-backup',
    );
    const otherLibrary = WebDavBackupEntry(
      fileName: 'class-9b.classi-backup',
      libraryName: 'class-9b',
      remotePath: '/backups/class-9b.classi-backup',
    );

    // Newest first, as listRemoteBackups returns them.
    final pairs = LibraryBackupService.pendingConflictPairs([
      newerConflict,
      canonical,
      olderConflict,
      otherLibrary,
    ]);

    expect(pairs.length, 1, reason: 'newest conflict per library only');
    expect(pairs.single.canonical.fileName, canonical.fileName);
    expect(pairs.single.conflict.fileName, newerConflict.fileName);
  });

  test('pendingConflictPairs can be narrowed to one library', () {
    const entries = [
      WebDavBackupEntry(
        fileName: 'class-8a_CONFLICT_device-a.classi-backup',
        libraryName: 'class-8a',
        remotePath: '/backups/class-8a_CONFLICT_device-a.classi-backup',
      ),
      WebDavBackupEntry(
        fileName: 'class-8a.classi-backup',
        libraryName: 'class-8a',
        remotePath: '/backups/class-8a.classi-backup',
      ),
    ];

    expect(
      LibraryBackupService.pendingConflictPairs(
        entries,
        libraryName: 'class-9b',
      ),
      isEmpty,
      reason: 'a conflict in one library must not flag another',
    );
    expect(
      LibraryBackupService.pendingConflictPairs(
        entries,
        libraryName: 'class-8a',
      ),
      hasLength(1),
    );
  });

  test('a conflict with no canonical counterpart is not paired', () {
    const orphan = WebDavBackupEntry(
      fileName: 'class-8a_CONFLICT_device-a.classi-backup',
      libraryName: 'class-8a',
      remotePath: '/backups/class-8a_CONFLICT_device-a.classi-backup',
    );
    expect(LibraryBackupService.pendingConflictPairs([orphan]), isEmpty);
  });

  test('libraryNameForBackupFile strips conflict and archive suffixes', () {
    expect(
      LibraryBackupService.libraryNameForBackupFile(
        'class-8a_CONFLICT_20260507T080000Z.classi-backup',
      ),
      'class-8a',
    );
    expect(
      LibraryBackupService.libraryNameForBackupFile(
        'class-8a_20260506T143200Z.classi-backup',
      ),
      'class-8a',
    );
    expect(
      LibraryBackupService.libraryNameForBackupFile('class-8a.classi-backup'),
      'class-8a',
    );
  });
}
