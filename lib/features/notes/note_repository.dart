import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import 'note_links.dart';

enum NoteFilter { all, todos, done }

class NoteRepository {
  NoteRepository(this._database);

  final AppDatabase _database;

  Stream<List<TeacherNote>> watchNotes(NoteFilter filter) {
    final query = _database.select(_database.notesTable)
      ..where((table) => table.archivedAt.isNull())
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);

    switch (filter) {
      case NoteFilter.all:
        break;
      case NoteFilter.todos:
        query
          ..where((table) => table.isTodo.equals(true))
          ..where((table) => table.todoDone.equals(false));
        break;
      case NoteFilter.done:
        query.where((table) => table.todoDone.equals(true));
        break;
    }

    return query.watch();
  }

  Stream<List<TeacherNote>> watchNotesForStudent(int studentId) {
    final query = _database.select(_database.notesTable)
      ..where((table) => table.archivedAt.isNull())
      ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]);
    return query.watch().map(
      (notes) => [
        for (final note in notes)
          if (noteStudentIds(note).contains(studentId)) note,
      ],
    );
  }

  Stream<List<TeacherNote>> watchNotesForGroup(int groupId) {
    return (_database.select(_database.notesTable)
          ..where((table) => table.groupId.equals(groupId))
          ..where((table) => table.archivedAt.isNull())
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .watch();
  }

  Stream<List<TeacherNote>> watchArchivedNotesForGroup(int groupId) {
    return (_database.select(_database.notesTable)
          ..where((table) => table.groupId.equals(groupId))
          ..where((table) => table.archivedAt.isNotNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.archivedAt),
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .watch();
  }

  Stream<List<TeacherNote>> watchArchivedNotes() {
    return (_database.select(_database.notesTable)
          ..where((table) => table.archivedAt.isNotNull())
          ..orderBy([
            (table) => OrderingTerm.desc(table.archivedAt),
            (table) => OrderingTerm.desc(table.createdAt),
          ]))
        .watch();
  }

  Future<void> saveNote({
    required String body,
    int? groupId,
    List<int> studentIds = const [],
    required bool isTodo,
    DateTime? createdAt,
  }) {
    final normalizedStudentIds = normalizeNoteStudentIds(studentIds);
    return _database
        .into(_database.notesTable)
        .insert(
          NotesTableCompanion.insert(
            body: body.trim(),
            groupId: Value(groupId),
            studentId: Value(
              normalizedStudentIds.isEmpty ? null : normalizedStudentIds.first,
            ),
            studentIdsJson: Value(encodeNoteStudentIds(normalizedStudentIds)),
            isTodo: Value(isTodo),
            createdAt: Value(createdAt ?? DateTime.now()),
          ),
        );
  }

  Future<void> updateNote({
    required TeacherNote note,
    required String body,
    int? groupId,
    List<int> studentIds = const [],
    required bool isTodo,
    required DateTime createdAt,
  }) {
    final keepTodoState = note.isTodo && isTodo;
    final normalizedStudentIds = normalizeNoteStudentIds(studentIds);

    return (_database.update(
      _database.notesTable,
    )..where((table) => table.id.equals(note.id))).write(
      NotesTableCompanion(
        body: Value(body.trim()),
        groupId: Value(groupId),
        studentId: Value(
          normalizedStudentIds.isEmpty ? null : normalizedStudentIds.first,
        ),
        studentIdsJson: Value(encodeNoteStudentIds(normalizedStudentIds)),
        isTodo: Value(isTodo),
        createdAt: Value(createdAt),
        todoDone: Value(keepTodoState ? note.todoDone : false),
        todoDoneAt: Value(
          keepTodoState && note.todoDone ? note.todoDoneAt : null,
        ),
      ),
    );
  }

  Future<void> toggleTodo(TeacherNote note, bool done) {
    return (_database.update(
      _database.notesTable,
    )..where((table) => table.id.equals(note.id))).write(
      NotesTableCompanion(
        todoDone: Value(done),
        todoDoneAt: Value(done ? DateTime.now() : null),
      ),
    );
  }

  Future<void> deleteNote(int id) {
    return (_database.delete(
      _database.notesTable,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> archiveNote(int id) {
    return (_database.update(_database.notesTable)
          ..where((table) => table.id.equals(id)))
        .write(NotesTableCompanion(archivedAt: Value(DateTime.now())));
  }

  Future<void> unarchiveNote(int id) {
    return (_database.update(_database.notesTable)
          ..where((table) => table.id.equals(id)))
        .write(const NotesTableCompanion(archivedAt: Value(null)));
  }
}
