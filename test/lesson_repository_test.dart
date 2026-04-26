import 'package:clari/core/database/app_database.dart';
import 'package:clari/features/attendance/attendance_repository.dart';
import 'package:clari/features/grades/grade_repository.dart';
import 'package:clari/features/groups/group_repository.dart';
import 'package:clari/features/homework/homework_repository.dart';
import 'package:clari/features/lessons/lesson_repository.dart';
import 'package:clari/features/material_tracking/material_repository.dart';
import 'package:clari/features/notes/note_repository.dart';
import 'package:clari/features/students/student_repository.dart';
import 'package:clari/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GroupRepository groupRepository;
  late StudentRepository studentRepository;
  late GradeRepository gradeRepository;
  late MaterialRepository materialRepository;
  late HomeworkRepository homeworkRepository;
  late AttendanceRepository attendanceRepository;
  late NoteRepository noteRepository;
  late LessonRepository lessonRepository;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    groupRepository = GroupRepository(database);
    studentRepository = StudentRepository(database);
    gradeRepository = GradeRepository(database);
    materialRepository = MaterialRepository(database);
    homeworkRepository = HomeworkRepository(database);
    attendanceRepository = AttendanceRepository(database);
    noteRepository = NoteRepository(database);
    lessonRepository = LessonRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('group lesson entry dates merge lesson data sources', () async {
    final groupId = await groupRepository.createGroup(
      name: '10A',
      gradeScale: defaultGradeScaleEntries,
    );
    final studentId = await studentRepository.addStudent(
      groupId: groupId,
      firstName: 'Ada',
      lastName: 'Lovelace',
    );

    await attendanceRepository.markAbsent(
      studentId: studentId,
      date: DateTime(2026, 5, 5),
    );
    await homeworkRepository.saveLog(
      studentId: studentId,
      date: DateTime(2026, 5, 6),
      hadHomework: true,
    );
    await materialRepository.saveLog(
      studentId: studentId,
      date: DateTime(2026, 5, 7),
      hadMaterial: true,
    );
    await gradeRepository.saveEntry(
      studentId: studentId,
      date: DateTime(2026, 5, 8),
      sessionLabel: 'Mitarbeit',
      value: '2',
    );
    await noteRepository.saveNote(
      body: 'Lesson note',
      groupId: groupId,
      studentIds: [studentId],
      isTodo: false,
      createdAt: DateTime(2026, 5, 9, 13, 45),
    );

    final entryDates = await lessonRepository
        .watchGroupEntryDates(groupId)
        .first;

    expect(entryDates, {
      DateTime(2026, 5, 5),
      DateTime(2026, 5, 6),
      DateTime(2026, 5, 7),
      DateTime(2026, 5, 8),
      DateTime(2026, 5, 9),
    });
  });
}
