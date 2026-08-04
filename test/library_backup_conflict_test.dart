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
