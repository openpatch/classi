import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';

final lessonGroupProvider = StreamProvider.family<Group?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final lessonStudentsProvider = StreamProvider.family<List<Student>, String>(
  (ref, groupId) => ref
      .watch(studentRepositoryProvider)
      .watchByGroup(groupId, sortField: ref.watch(studentSortFieldProvider)),
);

final lessonMaterialSelectionsProvider =
    StreamProvider.family<Map<String, bool>, (String, DateTime)>(
      (ref, args) => ref
          .watch(materialRepositoryProvider)
          .watchGroupSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
          ),
    );

final lessonHomeworkSelectionsProvider =
    StreamProvider.family<Map<String, bool>, (String, DateTime)>(
      (ref, args) => ref
          .watch(homeworkRepositoryProvider)
          .watchGroupSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
          ),
    );

final lessonAbsenceSelectionsProvider =
    StreamProvider.family<Set<String>, (String, DateTime)>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchGroupSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
          ),
    );

final lessonNotesProvider = StreamProvider.family<List<TeacherNote>, String>(
  (ref, groupId) =>
      ref.watch(noteRepositoryProvider).watchNotesForGroup(groupId),
);

final lessonEntryDatesProvider = StreamProvider.family<Set<DateTime>, String>(
  (ref, groupId) =>
      ref.watch(lessonRepositoryProvider).watchGroupEntryDates(groupId),
);

final lessonGradeSelectionsProvider =
    FutureProvider.family<Map<String, String>, (String, DateTime, String, String)>(
      (ref, args) => ref
          .watch(gradeRepositoryProvider)
          .getSessionSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            sessionLabel: args.$3,
            categoryId: args.$4,
          ),
    );

DateTime normalizeLessonDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

String encodeLessonDate(DateTime date) {
  final normalized = normalizeLessonDate(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

DateTime parseLessonDateOrToday(String? rawDate) {
  final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
  return normalizeLessonDate(parsed ?? DateTime.now());
}

List<TeacherNote> notesForLessonDate(List<TeacherNote> notes, DateTime date) {
  final normalizedDate = normalizeLessonDate(date);
  final filteredNotes = [
    for (final note in notes)
      if (normalizeLessonDate(note.createdAt) == normalizedDate) note,
  ];
  filteredNotes.sort(
    (left, right) => right.createdAt.compareTo(left.createdAt),
  );
  return filteredNotes;
}
