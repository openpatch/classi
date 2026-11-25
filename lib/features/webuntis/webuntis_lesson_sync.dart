import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../groups/group_repository.dart';
import '../lessons/lesson_support.dart';
import '../schedule/lesson_slot_repository.dart';
import '../sessions/session_repository.dart';
import '../attendance/attendance_repository.dart';
import 'webuntis_lesson_day.dart';
import 'webuntis_link.dart';
import 'webuntis_models.dart';
import 'webuntis_service.dart';
import 'webuntis_timetable.dart';

final webUntisLessonSyncProvider = Provider<WebUntisLessonSync>(
  (ref) => WebUntisLessonSync(
    service: ref.watch(webUntisServiceProvider),
    database: ref.watch(databaseProvider),
  ),
);

typedef WebUntisLessonImport = ({
  int groupId,
  String groupName,
  WebUntisScheduledLesson lesson,
  String categoryId,
  String categoryName,

  /// The lesson Classi already has in this slot, which a sync updates with
  /// the register's topic and attendance instead of creating a new one.
  Session? existing,

  /// The WebUntis periods behind [lesson], whose registers are read when an
  /// existing lesson is updated.
  List<WebUntisPeriod> periods,
});

extension WebUntisLessonImportState on WebUntisLessonImport {
  bool get alreadyExists => existing != null;
}

typedef WebUntisLessonSyncResult = ({int added, int updated, int skipped});

typedef WebUntisLessonPreview = ({
  List<WebUntisLessonImport> lessons,
  int unmapped,
  bool hasLinkedGroups,
});

class WebUntisLessonSync {
  WebUntisLessonSync({
    required WebUntisService service,
    required AppDatabase database,
  }) : _service = service,
       _database = database,
       _groups = GroupRepository(database),
       _slots = LessonSlotRepository(database),
       _sessions = SessionRepository(database),
       _attendance = AttendanceRepository(database);

  final WebUntisService _service;
  final AppDatabase _database;
  final GroupRepository _groups;
  final LessonSlotRepository _slots;
  final SessionRepository _sessions;
  final AttendanceRepository _attendance;

  Future<WebUntisLessonPreview> load({
    required DateTime start,
    required DateTime end,
    int? groupId,
    int? schoolYearId,
  }) async {
    final groups = groupId == null
        ? await _groups.watchActiveGroups(schoolYearId: schoolYearId).first
        : [?await _groups.watchGroup(groupId).first];
    final linked = <({Group group, WebUntisGroupLink link})>[
      for (final group in groups)
        if (group.archivedAt == null)
          if (WebUntisGroupLink.ofGroup(group) case final link?)
            (group: group, link: link),
    ];
    if (linked.isEmpty) {
      return (
        lessons: const <WebUntisLessonImport>[],
        unmapped: 0,
        hasLinkedGroups: false,
      );
    }

    final timetable = await _service.loadTimetable(
      start: start,
      end: end,
      link: linked.length == 1 ? linked.single.link : null,
    );
    final lessons = <WebUntisLessonImport>[];
    final existingByGroupAndDate = <(int, DateTime), List<Session>>{};
    final existing = await _sessions
        .watchSessionsInRange(start: start, end: end)
        .first;
    for (final session in existing) {
      existingByGroupAndDate
          .putIfAbsent((session.groupId, session.date), () => [])
          .add(session);
    }
    var unmapped = 0;
    for (final entry in linked) {
      final resolved = timetable.lessonsFor(
        link: entry.link,
        start: start,
        end: end,
      );
      unmapped += resolved.unmapped;
      final categories = gradableCategories(
        parseGradeCategories(entry.group.gradeCategoriesJson),
      );
      final fallback = categories.firstWhere(
        (category) => category.id == defaultGradeCategoryId,
        orElse: () => categories.first,
      );
      final slots = await _slots.slots(entry.group.id);
      for (final lesson in resolved.lessons) {
        final slot = slots
            .where(
              (slot) =>
                  slot.weekday == lesson.date.weekday &&
                  slot.periodStart <= lesson.periodEnd &&
                  lesson.periodStart <= slot.periodEnd,
            )
            .firstOrNull;
        final category =
            categories
                .where((category) => category.id == slot?.categoryId)
                .firstOrNull ??
            fallback;
        lessons.add((
          groupId: entry.group.id,
          groupName: entry.group.name,
          lesson: lesson,
          categoryId: category.id,
          categoryName: category.name,
          existing: existingByGroupAndDate[(entry.group.id, lesson.date)]
              ?.where(
                (session) =>
                    session.periodStart == 0 ||
                    (session.periodStart <= lesson.periodEnd &&
                        lesson.periodStart <= session.periodEnd),
              )
              .firstOrNull,
          periods: timetable.periodsOf(link: entry.link, lesson: lesson),
        ));
      }
    }
    lessons.sort((a, b) {
      final byDate = a.lesson.date.compareTo(b.lesson.date);
      if (byDate != 0) return byDate;
      final byPeriod = a.lesson.periodStart.compareTo(b.lesson.periodStart);
      if (byPeriod != 0) return byPeriod;
      return a.groupName.compareTo(b.groupName);
    });
    return (lessons: lessons, unmapped: unmapped, hasLinkedGroups: true);
  }

  /// Creates the new lessons among [lessons], then fills every lesson, new
  /// or existing, with what its WebUntis register says: the topic, when one
  /// was entered, and the attendance, once it was taken. Anything WebUntis
  /// has nothing for is left as it is.
  Future<WebUntisLessonSyncResult> importLessons(
    List<WebUntisLessonImport> lessons,
  ) async {
    final toCreate = <int, List<WebUntisLessonImport>>{};
    for (final lesson in lessons) {
      if (lesson.existing == null) {
        toCreate.putIfAbsent(lesson.groupId, () => []).add(lesson);
      }
    }

    // Read the registers before writing anything, so a failing request
    // leaves the library untouched.
    final registers = await _service.loadRegisters([
      for (final item in lessons)
        for (final period in item.periods) period.id,
    ]);

    var added = 0;
    var updated = 0;
    await _database.transaction(() async {
      for (final entry in toCreate.entries) {
        added += await _sessions.planLessons(
          groupId: entry.key,
          skipOverlapping: true,
          lessons: [
            for (final item in entry.value)
              (
                date: item.lesson.date,
                periodStart: item.lesson.periodStart,
                periodEnd: item.lesson.periodEnd,
                categoryId: item.categoryId,
                categoryName: item.categoryName,
                label: '',
              ),
          ],
        );
      }

      // Each item now has a lesson in Classi: the one it found, the one just
      // created, or one that already covered its periods. Several items can
      // share a lesson, such as two blocks on a day with a whole-day record.
      final targets =
          <int, ({Session session, List<WebUntisLessonImport> items})>{};
      for (final item in lessons) {
        final session = await _sessionFor(item);
        if (session == null) continue;
        (targets[session.id] ??= (session: session, items: [])).items.add(item);
      }

      final studentsByGroup = <int, List<Student>>{};
      for (final (:session, :items) in targets.values) {
        final periods =
            {
                for (final item in items)
                  for (final period in item.periods) period.id: period,
              }.values.toList()
              ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        if (periods.isEmpty) continue;
        final students = studentsByGroup[session.groupId] ??=
            await (_database.select(
              _database.studentsTable,
            )..where((t) => t.groupId.equals(session.groupId))).get();
        final changed = await _applyRegisters(
          session,
          WebUntisLessonDay.fromRegisters(periods, registers),
          students,
        );
        // A lesson just created counts as added, whatever it was filled with.
        if (changed) {
          updated += items.where((item) => item.existing != null).length;
        }
      }
    });
    await _service.markSynced();
    return (
      added: added,
      updated: updated,
      skipped: lessons.length - added - updated,
    );
  }

  /// The lesson in Classi that [item] stands for, read fresh: the same
  /// group and day, and a whole-day record or one overlapping its periods.
  Future<Session?> _sessionFor(WebUntisLessonImport item) async {
    if (item.existing case final existing?) {
      final current = await (_database.select(
        _database.sessionsTable,
      )..where((t) => t.id.equals(existing.id))).getSingleOrNull();
      if (current != null) return current;
    }
    final lesson = item.lesson;
    final candidates =
        await (_database.select(_database.sessionsTable)
              ..where((t) => t.groupId.equals(item.groupId))
              ..where((t) => t.date.equals(normalizeLessonDate(lesson.date)))
              ..orderBy([(t) => OrderingTerm.desc(t.periodStart)]))
            .get();
    return candidates
        .where(
          (session) =>
              session.periodStart == 0 ||
              (session.periodStart <= lesson.periodEnd &&
                  lesson.periodStart <= session.periodEnd),
        )
        .firstOrNull;
  }

  /// Takes [day]'s topic and attendance over into [session]; returns whether
  /// anything changed.
  Future<bool> _applyRegisters(
    Session session,
    WebUntisLessonDay day,
    List<Student> students,
  ) async {
    var changed = false;
    if (day.topics.isNotEmpty) {
      final topic = webUntisTopicAsLessonTopic(day.topics);
      if (topic.isNotEmpty && topic != session.label.trim()) {
        await _sessions.updateSession(
          id: session.id,
          label: topic,
          description: session.description,
        );
        changed = true;
      }
    }

    if (!day.attendanceTaken) return changed;
    final attendance = webUntisAttendanceForGroup(day, students);
    if (attendance.linkedStudentIds.isEmpty) return changed;
    final logs =
        await (_database.select(_database.attendanceLogsTable)
              ..where((t) => t.studentId.isIn(attendance.linkedStudentIds))
              ..where((t) => t.date.equals(normalizeLessonDate(session.date)))
              ..where((t) => t.periodStart.equals(session.periodStart)))
            .get();
    final absent = {
      for (final log in logs)
        if (log.isAbsent) log.studentId,
    };
    if (webUntisAttendanceMatches(
      attendance,
      absentStudents: absent,
      excusedStudents: {
        for (final log in logs)
          if (log.isAbsent && log.isExcused) log.studentId,
      },
      lateStudents: {
        for (final log in logs)
          if (!log.isAbsent && log.isLate) log.studentId,
      },
      activityStudents: {
        for (final log in logs)
          if (log.isAbsent && log.isActivity) log.studentId,
      },
      examStudents: {
        for (final log in logs)
          if (log.isAbsent && log.isActivity && log.isExam) log.studentId,
      },
    )) {
      return changed;
    }
    await _attendance.applyAttendanceForDate(
      date: session.date,
      periodStart: session.periodStart,
      studentIds: attendance.linkedStudentIds,
      absences: attendance.absences,
      late: attendance.late,
      activity: attendance.activity,
      exam: attendance.exam,
    );
    return true;
  }
}
