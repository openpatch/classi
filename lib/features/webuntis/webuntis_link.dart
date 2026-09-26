import '../../core/database/app_database.dart';
import 'webuntis_models.dart';

/// What a group stands for in WebUntis: one of the teacher's courses, or a
/// whole class.
///
/// A course is the better link whenever the group is not simply a class: a
/// course held for half of 10a, or a Q1 course drawing students from four
/// classes. Its class register lists exactly its own students, where a class
/// link would pull in the whole class. A course wins when a group has both.
class WebUntisGroupLink {
  const WebUntisGroupLink.course(this.lessonIds) : klasseId = null;

  const WebUntisGroupLink.klasse(int this.klasseId) : lessonIds = const {};

  /// The group's link, or `null` when it is not linked to WebUntis.
  static WebUntisGroupLink? ofGroup(Group group) {
    final lessonIds = decodeLessonIds(group.webuntisLessonIds);
    if (lessonIds.isNotEmpty) {
      return WebUntisGroupLink.course(lessonIds);
    }
    if (group.webuntisKlasseId case final klasseId?) {
      return WebUntisGroupLink.klasse(klasseId);
    }
    return null;
  }

  /// WebUntis lesson ids ("Unterricht") of the course. Empty for a class.
  final Set<int> lessonIds;

  /// The WebUntis class, or `null` for a course.
  final int? klasseId;

  bool get isCourse => lessonIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is WebUntisGroupLink &&
      other.klasseId == klasseId &&
      other.lessonIds.length == lessonIds.length &&
      other.lessonIds.containsAll(lessonIds);

  @override
  int get hashCode => Object.hash(klasseId, Object.hashAllUnordered(lessonIds));

  /// Whether [period] is one of this group's lessons.
  bool includes(WebUntisPeriod period) => isCourse
      ? lessonIds.contains(period.lessonId)
      : period.klasseIds.contains(klasseId);
}

/// Stores lesson ids the way `groups_table.webuntis_lesson_ids` holds them.
String? encodeLessonIds(Set<int> lessonIds) {
  if (lessonIds.isEmpty) return null;
  return (lessonIds.toList()..sort()).join(',');
}

Set<int> decodeLessonIds(String? value) {
  if (value == null || value.isEmpty) return const {};
  return {for (final part in value.split(',')) ?int.tryParse(part.trim())};
}

/// One of the teacher's courses, as read off their timetable.
class WebUntisCourse {
  const WebUntisCourse({
    required this.lessonIds,
    required this.subjectName,
    required this.klasseIds,
    required this.klassenNames,
    required this.slots,
  });

  final Set<int> lessonIds;
  final String subjectName;
  final Set<int> klasseIds;
  final List<String> klassenNames;

  /// When the course meets, one entry per weekday and start time, e.g.
  /// Monday 08:00, as the first date seen for it.
  final List<DateTime> slots;

  /// The name a new group gets, e.g. `M 10a` or `IF Q1a, Q1b`.
  String get displayName => [
    if (subjectName.isNotEmpty) subjectName,
    if (klassenNames.isNotEmpty) klassenNames.join(', '),
  ].join(' ');
}

/// Folds the teacher's periods into courses.
///
/// Untis gives a course one lesson id, but it may split a course's weekly
/// hours over several, so lessons with the same subject and the same classes
/// count as one course. The price is that two parallel courses of one teacher
/// with identical subject and classes would merge; that is rare enough to
/// accept, and the teacher can still link a group to a class instead.
List<WebUntisCourse> coursesFromTimetable(
  List<WebUntisPeriod> periods,
  WebUntisUserData userData,
) {
  final subjectNames = {
    for (final subject in userData.subjects) subject.id: subject.displayName,
  };
  final klassenNames = {
    for (final klasse in userData.klassen) klasse.id: klasse.displayName,
  };

  final byKey = <String, List<WebUntisPeriod>>{};
  for (final period in periods) {
    if (period.lessonId == 0) continue;
    final subjects = period.subjectIds.toList()..sort();
    final klassen = period.klasseIds.toList()..sort();
    // Periods with neither are duties, office hours and the like.
    if (subjects.isEmpty && klassen.isEmpty) continue;
    final key = '${subjects.join(',')}|${klassen.join(',')}';
    byKey.putIfAbsent(key, () => []).add(period);
  }

  final courses = <WebUntisCourse>[];
  for (final group in byKey.values) {
    final first = group.first;
    final klasseIds = first.klasseIds;
    final names = [for (final id in klasseIds) klassenNames[id] ?? '$id']
      ..sort();
    final subjectName = [
      for (final id in first.subjectIds) subjectNames[id] ?? '',
    ].where((name) => name.isNotEmpty).join('/');

    final sorted = [...group]
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    final slots = <DateTime>[];
    final seen = <String>{};
    for (final period in sorted) {
      final start = period.startDateTime;
      if (seen.add('${start.weekday}-${start.hour}-${start.minute}')) {
        slots.add(start);
      }
    }
    slots.sort((a, b) {
      final byDay = a.weekday.compareTo(b.weekday);
      if (byDay != 0) return byDay;
      return (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
    });

    courses.add(
      WebUntisCourse(
        lessonIds: {for (final period in group) period.lessonId},
        subjectName: subjectName,
        klasseIds: klasseIds,
        klassenNames: names,
        slots: slots,
      ),
    );
  }

  courses.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return courses;
}
