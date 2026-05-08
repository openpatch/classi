import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/attendance/attendance_repository.dart';
import 'package:classi/features/grades/grade_repository.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/homework/homework_repository.dart';
import 'package:classi/features/lessons/lesson_repository.dart';
import 'package:classi/features/material_tracking/material_repository.dart';
import 'package:classi/features/notes/note_repository.dart';
import 'package:classi/features/students/student_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
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

  test(
    'group lesson entry categories map dates to saved grade categories',
    () async {
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
        categoryId: 'oral',
        categoryName: 'Oral',
      );
      await gradeRepository.saveEntry(
        studentId: studentId,
        date: DateTime(2026, 5, 8),
        sessionLabel: 'Quiz',
        value: '1',
        categoryId: 'quiz',
        categoryName: 'Quiz',
      );
      await gradeRepository.saveEntry(
        studentId: studentId,
        date: DateTime(2026, 5, 9),
        sessionLabel: 'Mitarbeit',
        value: '2',
        categoryId: 'oral',
        categoryName: 'Oral',
      );
      await noteRepository.saveNote(
        body: 'Lesson note',
        groupId: groupId,
        studentIds: [studentId],
        isTodo: false,
        createdAt: DateTime(2026, 5, 9, 13, 45),
      );

      final entryCategories = await lessonRepository
          .watchGroupEntryCategories(groupId)
          .first;

      expect(entryCategories, {
        DateTime(2026, 5, 8): {'oral', 'quiz'},
        DateTime(2026, 5, 9): {'oral'},
      });
    },
  );

  test(
    'preferred session label picks the populated session for a category',
    () async {
      final groupId = await groupRepository.createGroup(
        name: '10A',
        gradeScale: defaultGradeScaleEntries,
      );
      final adaId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Ada',
        lastName: 'Lovelace',
      );
      final graceId = await studentRepository.addStudent(
        groupId: groupId,
        firstName: 'Grace',
        lastName: 'Hopper',
      );

      await gradeRepository.saveEntry(
        studentId: adaId,
        date: DateTime(2026, 5, 8),
        sessionLabel: 'Quiz',
        value: '2',
        categoryId: 'oral',
        categoryName: 'Oral',
      );
      await gradeRepository.saveEntry(
        studentId: adaId,
        date: DateTime(2026, 5, 8),
        sessionLabel: 'Project',
        value: '1',
        categoryId: 'oral',
        categoryName: 'Oral',
      );
      await gradeRepository.saveEntry(
        studentId: graceId,
        date: DateTime(2026, 5, 8),
        sessionLabel: 'Project',
        value: '2',
        categoryId: 'oral',
        categoryName: 'Oral',
      );

      final sessionLabel = await gradeRepository.getPreferredSessionLabel(
        groupId: groupId,
        date: DateTime(2026, 5, 8),
        categoryId: 'oral',
      );

      expect(sessionLabel, 'Project');
    },
  );
}
