import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:classi/core/storage/library_backup_service.dart';
import 'package:classi/features/exams/data/exam_document_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late String library;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('exam-documents');
    library = '${temp.path}/source.classi';
    await Directory(library).create();
    await File('$library/data.db').writeAsString('db');
    await File('$library/data.db.security.json').writeAsString('security');
  });

  tearDown(() => temp.delete(recursive: true));

  Future<File> pdf(String content) async {
    final file = File('${temp.path}/${content.hashCode}.pdf');
    await file.writeAsString(content);
    return file;
  }

  test('stores by content hash, verifies on read, collects garbage', () async {
    final store = ExamDocumentStore(library);
    final a = await store.put(await pdf('task sheet'));
    final again = await store.put(await pdf('task sheet'));
    final b = await store.put(await pdf('rubric'));
    expect(again, a);
    expect(store.fileFor(a).path, '$library/documents/$a.pdf');
    expect(await (await store.read(a))!.readAsString(), 'task sheet');

    await store.fileFor(b).writeAsString('tampered');
    expect(await store.read(b), isNull);
    expect(await store.read(null), isNull);

    expect(await store.collectGarbage({a}), 1);
    expect(await store.fileFor(a).exists(), isTrue);
    expect(await store.fileFor(b).exists(), isFalse);
  });

  test(
    'documents travel with a backup and nothing else is extracted',
    () async {
      final store = ExamDocumentStore(library);
      final hash = await store.put(await pdf('rubric'));
      await File('${store.directory.path}/notes.txt').writeAsString('ignored');

      final service = LibraryBackupService();
      final bytes = await service.buildBackupArchive(library);
      final names = ZipDecoder().decodeBytes(bytes).files.map((f) => f.name);
      expect(names, contains('documents/$hash.pdf'));
      expect(names, isNot(contains('documents/notes.txt')));

      // A crafted archive must not write outside the documents folder.
      final archive = ZipDecoder().decodeBytes(bytes);
      archive.addFile(
        ArchiveFile('documents/../../evil.pdf', 4, 'evil'.codeUnits),
      );
      final crafted = Uint8List.fromList(ZipEncoder().encode(archive));

      final restored = '${temp.path}/restored.classi';
      await service.restoreBackupFromBytes(
        bytes: crafted,
        destinationDatabasePath: restored,
      );
      final restoredStore = ExamDocumentStore(restored);
      expect(await (await restoredStore.read(hash))!.readAsString(), 'rubric');
      expect(await File('${temp.path}/evil.pdf').exists(), isFalse);
    },
  );

  test('a bare database file keeps documents next to it', () {
    final store = ExamDocumentStore('/libraries/school.db');
    expect(store.directory.path, '/libraries/school.db.documents');
  });
}
