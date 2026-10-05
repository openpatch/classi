import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import 'lesson_periods.dart';

/// One lesson of a group: its id, the day, and the period it starts in (0 for
/// a whole-day entry). Attendance, homework and material are kept per lesson.
typedef LessonKey = (int groupId, DateTime date, int periodStart);

final lessonGroupProvider = StreamProvider.autoDispose.family<Group?, int>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final lessonStudentsProvider = StreamProvider.autoDispose
    .family<List<Student>, int>(
      (ref, groupId) => ref
          .watch(studentRepositoryProvider)
          .watchByGroup(
            groupId,
            sortField: ref.watch(studentSortFieldProvider),
          ),
    );

final lessonMaterialSelectionsProvider = StreamProvider.autoDispose
    .family<Map<int, bool>, LessonKey>(
      (ref, args) => ref
          .watch(materialRepositoryProvider)
          .watchGroupSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonHomeworkSelectionsProvider = StreamProvider.autoDispose
    .family<Map<int, bool>, LessonKey>(
      (ref, args) => ref
          .watch(homeworkRepositoryProvider)
          .watchGroupSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonAbsenceSelectionsProvider = StreamProvider.autoDispose
    .family<Set<int>, LessonKey>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchGroupSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonExcusedSelectionsProvider = StreamProvider.autoDispose
    .family<Set<int>, LessonKey>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchExcusedSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonActivitySelectionsProvider = StreamProvider.autoDispose
    .family<Set<int>, LessonKey>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchActivitySelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonExamSelectionsProvider = StreamProvider.autoDispose
    .family<Set<int>, LessonKey>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchExamSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonLateSelectionsProvider = StreamProvider.autoDispose
    .family<Set<int>, LessonKey>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchLateSelections(
            groupId: args.$1,
            date: normalizeLessonDate(args.$2),
            periodStart: args.$3,
          ),
    );

final lessonNotesProvider = StreamProvider.autoDispose
    .family<List<TeacherNote>, int>(
      (ref, groupId) =>
          ref.watch(noteRepositoryProvider).watchNotesForGroup(groupId),
    );

final lessonEntryCategoriesProvider = StreamProvider.autoDispose
    .family<Map<DateTime, Set<String>>, int>(
      (ref, groupId) => ref
          .watch(lessonRepositoryProvider)
          .watchGroupEntryCategories(groupId),
    );

final lessonGradeSelectionsProvider = StreamProvider.autoDispose
    .family<Map<int, String>, (int, DateTime, String, String)>(
      (ref, args) => ref
          .watch(gradeRepositoryProvider)
          .watchSessionSelections(
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

/// The lessons a group holds on a day, from its weekly timetable and the
/// lessons already recorded, for lesson mode to choose between.
final lessonsOnDateProvider = FutureProvider.autoDispose
    .family<List<LessonPeriods>, (int, DateTime)>((ref, args) async {
      final (groupId, date) = args;
      final day = normalizeLessonDate(date);
      final slots = await ref.watch(lessonSlotRepositoryProvider).slots(groupId);
      final sessions = await ref
          .watch(sessionRepositoryProvider)
          .watchSessionsOnDate(groupId: groupId, date: day)
          .first;
      return lessonsOnDate(date: day, slots: slots, sessions: sessions);
    });
