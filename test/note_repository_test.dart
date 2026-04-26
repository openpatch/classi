import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/notes/note_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late NoteRepository repository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    repository = NoteRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('todo notes can be completed', () async {
    await repository.saveNote(body: 'Prepare grade review', isTodo: true);

    final openTodos = await repository.watchNotes(NoteFilter.todos).first;
    expect(openTodos, hasLength(1));
    expect(openTodos.single.todoDone, isFalse);

    await repository.toggleTodo(openTodos.single, true);

    final doneTodos = await repository.watchNotes(NoteFilter.done).first;
    expect(doneTodos, hasLength(1));
    expect(doneTodos.single.todoDone, isTrue);
    expect(doneTodos.single.todoDoneAt, isNotNull);
  });

  test('notes can be deleted', () async {
    await repository.saveNote(body: 'Call parent', isTodo: false);

    final notes = await repository.watchNotes(NoteFilter.all).first;
    expect(notes, hasLength(1));

    await repository.deleteNote(notes.single.id);

    final remainingNotes = await repository.watchNotes(NoteFilter.all).first;
    expect(remainingNotes, isEmpty);
  });

  test('notes can be edited including date and type', () async {
    await repository.saveNote(
      body: 'Prepare parent meeting',
      isTodo: false,
      createdAt: DateTime(2026, 4, 20, 9),
    );

    final note = (await repository.watchNotes(NoteFilter.all).first).single;
    await repository.updateNote(
      note: note,
      body: 'Prepare report card meeting',
      isTodo: true,
      createdAt: DateTime(2026, 4, 21, 9),
    );

    final updatedNote =
        (await repository.watchNotes(NoteFilter.all).first).single;
    expect(updatedNote.body, 'Prepare report card meeting');
    expect(updatedNote.isTodo, isTrue);
    expect(updatedNote.todoDone, isFalse);
    expect(updatedNote.createdAt, DateTime(2026, 4, 21, 9));
  });

  test('notes can be archived and unarchived', () async {
    await repository.saveNote(body: 'Archive me', isTodo: false);

    final note = (await repository.watchNotes(NoteFilter.all).first).single;
    await repository.archiveNote(note.id);

    expect(await repository.watchNotes(NoteFilter.all).first, isEmpty);
    final archivedNote = await (database.select(
      database.notesTable,
    )..where((table) => table.id.equals(note.id))).getSingle();
    expect(archivedNote.archivedAt, isNotNull);

    await repository.unarchiveNote(note.id);

    final notes = await repository.watchNotes(NoteFilter.all).first;
    expect(notes, hasLength(1));
    expect(notes.single.archivedAt, isNull);
  });

  test('notes can link multiple students', () async {
    final groupId = await groupRepository.createGroup(
      name: '10A',
      gradeScale: defaultGradeScaleEntries,
    );
    final firstStudentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Max',
      lastName: 'Mustermann',
    );
    final secondStudentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Erika',
      lastName: 'Musterfrau',
    );

    await repository.saveNote(
      body: 'Presentation team',
      groupId: groupId,
      studentIds: [firstStudentId, secondStudentId],
      isTodo: false,
    );

    final firstStudentNotes = await repository
        .watchNotesForStudent(firstStudentId)
        .first;
    final secondStudentNotes = await repository
        .watchNotesForStudent(secondStudentId)
        .first;

    expect(firstStudentNotes, hasLength(1));
    expect(secondStudentNotes, hasLength(1));
    expect(firstStudentNotes.single.studentId, firstStudentId);
    expect(
      firstStudentNotes.single.studentIdsJson,
      '[$firstStudentId,$secondStudentId]',
    );
  });
}
