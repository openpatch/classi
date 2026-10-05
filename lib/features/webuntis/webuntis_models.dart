/// Value types for the WebUntis mobile JSON-RPC API.
///
/// Field names follow the wire format so a response can be read against the
/// API by eye. Everything is tolerant of missing keys: WebUntis servers run
/// different versions and omit whole sections depending on the rights the
/// logged-in account has.
library;

/// The kind of element a timetable is requested for.
enum WebUntisElementType {
  klasse(1, 'CLASS'),
  teacher(2, 'TEACHER'),
  subject(3, 'SUBJECT'),
  room(4, 'ROOM'),
  student(5, 'STUDENT');

  const WebUntisElementType(this.id, this.wireName);

  final int id;
  final String wireName;

  static WebUntisElementType? fromWire(Object? value) {
    if (value is String) {
      for (final type in WebUntisElementType.values) {
        if (type.wireName == value) {
          return type;
        }
      }
      return null;
    }
    if (value is int) {
      for (final type in WebUntisElementType.values) {
        if (type.id == value) {
          return type;
        }
      }
    }
    return null;
  }
}

/// A school class ("Klasse") as WebUntis knows it.
class WebUntisKlasse {
  const WebUntisKlasse({
    required this.id,
    required this.name,
    required this.longName,
    required this.active,
    this.startDate,
    this.endDate,
  });

  factory WebUntisKlasse.fromJson(Map<String, dynamic> json) {
    return WebUntisKlasse(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']),
      longName: readString(json['longName']),
      active: json['active'] == true,
      startDate: readDate(json['startDate']),
      endDate: readDate(json['endDate']),
    );
  }

  final int id;
  final String name;
  final String longName;
  final bool active;
  final DateTime? startDate;
  final DateTime? endDate;

  /// The name a teacher recognises the class by, e.g. `10a`.
  String get displayName => name.isNotEmpty ? name : longName;

  /// Whether the class is running on [date], used to hide classes of past
  /// school years from the import picker.
  bool runsOn(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final start = startDate;
    final end = endDate;
    if (start != null && day.isBefore(start)) {
      return false;
    }
    if (end != null && day.isAfter(end)) {
      return false;
    }
    return true;
  }
}

/// A subject as WebUntis knows it, e.g. `M` for Mathematik.
class WebUntisSubject {
  const WebUntisSubject({
    required this.id,
    required this.name,
    required this.longName,
  });

  factory WebUntisSubject.fromJson(Map<String, dynamic> json) {
    return WebUntisSubject(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']),
      longName: readString(json['longName']),
    );
  }

  final int id;
  final String name;
  final String longName;

  String get displayName => name.isNotEmpty ? name : longName;
}

/// The school's bell times: which clock times make up period 1, 2, … on each
/// weekday. Classi numbers a lesson by its periods, WebUntis by its clock
/// times, and this is what matches the two.
class WebUntisTimeGrid {
  const WebUntisTimeGrid(this.unitsByWeekday);

  factory WebUntisTimeGrid.fromJson(Object? json) {
    final days = json is Map ? readList(json['days']) : const [];
    const weekdays = {
      'MON': DateTime.monday,
      'TUE': DateTime.tuesday,
      'WED': DateTime.wednesday,
      'THU': DateTime.thursday,
      'FRI': DateTime.friday,
      'SAT': DateTime.saturday,
      'SUN': DateTime.sunday,
    };
    final byWeekday = <int, List<({int start, int end})>>{};
    for (final day in days) {
      final weekday = weekdays[day['day']];
      if (weekday == null) continue;
      byWeekday[weekday] = [
        for (final unit in readList(day['units']))
          if ((_minutes(unit['startTime']), _minutes(unit['endTime'])) case (
            final start?,
            final end?,
          ))
            (start: start, end: end),
      ]..sort((a, b) => a.start.compareTo(b.start));
    }
    return WebUntisTimeGrid(byWeekday);
  }

  /// Periods per ISO weekday, in order, as minutes since midnight.
  final Map<int, List<({int start, int end})>> unitsByWeekday;

  bool get isEmpty => unitsByWeekday.values.every((units) => units.isEmpty);

  /// The 1-based period [time] falls into on its weekday, or `null` when it
  /// falls into none, such as a lesson outside the bell times.
  int? periodAt(DateTime time) {
    final units = unitsByWeekday[time.weekday];
    if (units == null) return null;
    final minutes = time.hour * 60 + time.minute;
    for (var index = 0; index < units.length; index++) {
      if (minutes >= units[index].start && minutes < units[index].end) {
        return index + 1;
      }
    }
    return null;
  }

  /// Reads `T08:00`, `08:00` or `0800` as minutes since midnight.
  static int? _minutes(Object? value) {
    if (value is int) return (value ~/ 100) * 60 + value % 100;
    if (value is! String) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3) return null;
    final hours = int.tryParse(digits.substring(0, digits.length - 2));
    final minutes = int.tryParse(digits.substring(digits.length - 2));
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }
}

/// A WebUntis school year, used to preselect the classes of the current year.
class WebUntisSchoolYear {
  const WebUntisSchoolYear({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  factory WebUntisSchoolYear.fromJson(Map<String, dynamic> json) {
    return WebUntisSchoolYear(
      id: readInt(json['id']) ?? 0,
      name: readString(json['name']),
      startDate: readDate(json['startDate']) ?? DateTime(1970),
      endDate: readDate(json['endDate']) ?? DateTime(1970),
    );
  }

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(startDate) && !day.isAfter(endDate);
  }
}

/// A person referenced by a lesson, i.e. a student on a class register.
class WebUntisPerson {
  const WebUntisPerson({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory WebUntisPerson.fromJson(Map<String, dynamic> json) {
    return WebUntisPerson(
      id: readInt(json['id']) ?? 0,
      firstName: readString(json['firstName']),
      lastName: readString(json['lastName']),
    );
  }

  final int id;
  final String firstName;
  final String lastName;

  String get fullName => '$firstName $lastName'.trim();
}

/// One element a lesson is held for: a class, teacher, subject or room.
class WebUntisPeriodElement {
  const WebUntisPeriodElement({required this.type, required this.id});

  factory WebUntisPeriodElement.fromJson(Map<String, dynamic> json) {
    return WebUntisPeriodElement(
      type: WebUntisElementType.fromWire(json['type']),
      id: readInt(json['id']) ?? 0,
    );
  }

  final WebUntisElementType? type;
  final int id;
}

/// A single lesson in the timetable.
class WebUntisPeriod {
  const WebUntisPeriod({
    required this.id,
    required this.lessonId,
    required this.startDateTime,
    required this.endDateTime,
    required this.elements,
    this.cancelled = false,
  });

  factory WebUntisPeriod.fromJson(Map<String, dynamic> json) {
    return WebUntisPeriod(
      id: readInt(json['id']) ?? 0,
      lessonId: readInt(json['lessonId']) ?? 0,
      startDateTime: readDateTime(json['startDateTime']) ?? DateTime(1970),
      endDateTime: readDateTime(json['endDateTime']) ?? DateTime(1970),
      elements: readList(
        json['elements'],
      ).map(WebUntisPeriodElement.fromJson).toList(growable: false),
      // `is` holds the period's states: REGULAR, IRREGULAR, CANCELLED, …
      cancelled: (json['is'] as List<dynamic>? ?? const []).contains(
        'CANCELLED',
      ),
    );
  }

  final int id;
  final int lessonId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<WebUntisPeriodElement> elements;

  /// Whether the lesson was cancelled. Its register holds neither a topic
  /// nor attendance worth reading.
  final bool cancelled;

  /// The classes this lesson is held for.
  Set<int> get klasseIds => {
    for (final element in elements)
      if (element.type == WebUntisElementType.klasse) element.id,
  };

  /// The subjects taught in this lesson, usually exactly one.
  Set<int> get subjectIds => {
    for (final element in elements)
      if (element.type == WebUntisElementType.subject) element.id,
  };
}

/// An absence recorded in the WebUntis class register.
class WebUntisAbsence {
  const WebUntisAbsence({
    required this.id,
    required this.studentId,
    required this.klasseId,
    required this.startDateTime,
    required this.endDateTime,
    required this.excused,
    required this.absenceReason,
    required this.text,
  });

  factory WebUntisAbsence.fromJson(Map<String, dynamic> json) {
    final excuse = json['excuse'];
    final excuseStatusId = excuse is Map<String, dynamic>
        ? readInt(excuse['excuseStatusId'])
        : null;
    return WebUntisAbsence(
      id: readInt(json['id']) ?? 0,
      studentId: readInt(json['studentId']) ?? 0,
      klasseId: readInt(json['klasseId']) ?? 0,
      startDateTime: readDateTime(json['startDateTime']) ?? DateTime(1970),
      endDateTime: readDateTime(json['endDateTime']) ?? DateTime(1970),
      // Older servers leave `excused` out and only carry an excuse object.
      excused:
          json['excused'] == true ||
          (json['excused'] == null &&
              excuseStatusId != null &&
              excuseStatusId > 0),
      absenceReason: readString(json['absenceReason']),
      text: readString(json['text']),
    );
  }

  final int id;
  final int studentId;
  final int klasseId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool excused;
  final String absenceReason;
  final String text;
}

/// A student taken out of a lesson by another school appointment: an
/// "Aktivität" in WebUntis (a trip, a contest) or an exam written elsewhere.
/// WebUntis keeps these apart from absences, under `prioritizedAttendances`,
/// and the student usually has no absence for the time at all. Classi
/// records both as an activity and keeps the exam apart by its label.
class WebUntisPrioritizedAttendance {
  const WebUntisPrioritizedAttendance({
    required this.studentId,
    required this.startDateTime,
    required this.endDateTime,
    this.isExam = false,
  });

  factory WebUntisPrioritizedAttendance.fromJson(Map<String, dynamic> json) {
    return WebUntisPrioritizedAttendance(
      studentId: readInt(json['studentId']) ?? 0,
      startDateTime: readDateTime(json['startDateTime']) ?? DateTime(1970),
      endDateTime: readDateTime(json['endDateTime']) ?? DateTime(1970),
      // `activityType` is ACTIVITY or EXAM; Untis Mobile reads anything else
      // as an activity.
      isExam: json['activityType'] == 'EXAM',
    );
  }

  final int studentId;
  final DateTime startDateTime;
  final DateTime endDateTime;

  /// An exam written elsewhere ("in anderer Prüfung") rather than an
  /// activity.
  final bool isExam;
}

/// The class register data of one lesson.
class WebUntisPeriodData {
  const WebUntisPeriodData({
    required this.ttId,
    required this.absenceChecked,
    required this.studentIds,
    required this.absences,
    this.topic,
    this.removedStudentIds = const {},
    this.prioritizedAttendances = const [],
  });

  factory WebUntisPeriodData.fromJson(Map<String, dynamic> json) {
    return WebUntisPeriodData(
      ttId: readInt(json['ttId']) ?? 0,
      absenceChecked: json['absenceChecked'] == true,
      studentIds: [
        for (final id in (json['studentIds'] as List<dynamic>? ?? const []))
          ?readInt(id),
      ],
      absences: readList(
        json['absences'],
      ).map(WebUntisAbsence.fromJson).toList(growable: false),
      topic: readWebUntisTopic(json),
      removedStudentIds: {
        for (final assignment in readList(json['studentAssignments']))
          if (assignment['assignmentType'] == 'REMOVED')
            ?readInt(assignment['studentId']),
      },
      prioritizedAttendances: readList(json['prioritizedAttendances'])
          .map(WebUntisPrioritizedAttendance.fromJson)
          .toList(growable: false),
    );
  }

  final int ttId;
  final bool absenceChecked;
  final List<int> studentIds;
  final List<WebUntisAbsence> absences;

  /// The lesson topic ("Lehrstoff") the teacher entered in the class
  /// register, or `null` when there is none.
  final String? topic;

  /// Students listed for the lesson but taken out of it, e.g. moved to
  /// another group for this one lesson. They are not part of the lesson.
  final Set<int> removedStudentIds;

  /// Students away at another school appointment during the lesson.
  final List<WebUntisPrioritizedAttendance> prioritizedAttendances;
}

/// Reads the lesson topic out of a `getPeriodData2017` entry.
///
/// Untis Mobile sends it as `topic: {text, periodId, teachingMethodId, …}`.
/// Blank text counts as no topic.
String? readWebUntisTopic(Map<String, dynamic> json) {
  final topic = json['topic'];
  final text = topic is Map ? topic['text'] : null;
  if (text is String && text.trim().isNotEmpty) {
    return text.trim();
  }
  return null;
}

/// What the class register holds for one class on one day, folded across
/// the teacher's lessons with that class.
///
/// Classi keeps one topic field and one absent/excused pair per student and
/// day, while WebUntis keeps both per lesson, so a day with a double lesson
/// has to be folded into one picture.
class WebUntisLessonDay {
  const WebUntisLessonDay({
    required this.lessonCount,
    required this.topics,
    required this.attendanceTaken,
    required this.absences,
    this.late = const {},
    this.activity = const {},
    this.exam = const {},
    this.lessons = const [],
    this.matchedPeriods = false,
  });

  /// Reads a day out of its [lessons] and their registers, keyed by period
  /// id, in lesson order.
  ///
  /// * Each distinct topic is kept once. A double lesson usually carries the
  ///   same topic twice.
  /// * WebUntis records lateness as an absence that starts with the lesson
  ///   and ends before it does. A student late in one lesson and absent in
  ///   none is late for the day. A register lists absences beyond its own
  ///   lesson, so each lesson only weighs the absences that overlap it.
  /// * A student absent in any lesson is absent for the day, which beats
  ///   late, and the day is excused only when every one of those absences
  ///   is. Calling a half excused day excused would quietly hide the
  ///   unexcused half.
  /// * A student WebUntis lists under an activity or an exam elsewhere in
  ///   any lesson is away at an activity for the day, unless they are absent too: an absence
  ///   beats an activity, which beats late. An activity counts as excused.
  ///   It is an exam only when everything WebUntis lists for the student
  ///   that day is an exam.
  /// * Attendance counts as taken once any lesson's register was checked;
  ///   before that, "nobody absent" only means nobody has looked yet.
  factory WebUntisLessonDay.fromRegisters(
    List<WebUntisPeriod> lessons,
    Map<int, WebUntisPeriodData> registers,
  ) {
    final topics = <String>[];
    final absences = <int, bool>{};
    final late = <int>{};
    final activity = <int>{};
    final notExam = <int>{};
    var taken = false;

    for (final lesson in lessons) {
      final register = registers[lesson.id];
      if (register == null) continue;
      final topic = register.topic;
      if (topic != null && !topics.contains(topic)) {
        topics.add(topic);
      }
      taken = taken || register.absenceChecked;
      for (final attendance in register.prioritizedAttendances) {
        if (attendance.studentId != 0 &&
            _overlaps(
              attendance.startDateTime,
              attendance.endDateTime,
              lesson,
            )) {
          activity.add(attendance.studentId);
          if (!attendance.isExam) notExam.add(attendance.studentId);
        }
      }
      for (final absence in register.absences) {
        if (absence.studentId == 0) {
          continue;
        }
        // A register lists the student's absences of the whole day, so a
        // lateness in the first lesson of a double lesson shows up in the
        // second one too. Only what touches this lesson counts for it.
        if (!touches(absence, lesson)) {
          continue;
        }
        if (isLateness(absence, lesson)) {
          late.add(absence.studentId);
          continue;
        }
        absences[absence.studentId] =
            (absences[absence.studentId] ?? true) && absence.excused;
      }
    }
    activity.removeAll(absences.keys);
    late.removeAll(absences.keys);
    late.removeAll(activity);
    for (final studentId in activity) {
      absences[studentId] = true;
    }

    return WebUntisLessonDay(
      lessonCount: lessons.length,
      topics: topics,
      // An absence on record means someone took attendance, checked flag or
      // not.
      attendanceTaken: taken || absences.isNotEmpty || late.isNotEmpty,
      absences: absences,
      late: late,
      activity: activity,
      exam: activity.difference(notExam),
      lessons: lessons,
    );
  }

  /// Whether [absence] overlaps [lesson]. An absence whose times could not
  /// be read counts as overlapping: better shown as absent than lost.
  static bool touches(WebUntisAbsence absence, WebUntisPeriod lesson) =>
      _overlaps(absence.startDateTime, absence.endDateTime, lesson);

  /// Whether the time from [start] to [end] overlaps [lesson]. Times that
  /// could not be read count as overlapping.
  static bool _overlaps(DateTime start, DateTime end, WebUntisPeriod lesson) {
    if (start.year == 1970 || end.year == 1970) {
      return true;
    }
    return start.isBefore(lesson.endDateTime) &&
        end.isAfter(lesson.startDateTime);
  }

  /// Whether [absence] is a lateness in [lesson]: it starts no later than the
  /// lesson and ends before the lesson does.
  static bool isLateness(WebUntisAbsence absence, WebUntisPeriod lesson) =>
      !absence.startDateTime.isAfter(lesson.startDateTime) &&
      absence.endDateTime.isAfter(lesson.startDateTime) &&
      absence.endDateTime.isBefore(lesson.endDateTime);

  static const empty = WebUntisLessonDay(
    lessonCount: 0,
    topics: [],
    attendanceTaken: false,
    absences: {},
  );

  /// How many of the teacher's lessons with the group fall on the day.
  final int lessonCount;

  /// The distinct topics, in lesson order. Empty when none was entered.
  final List<String> topics;

  /// Whether attendance was taken in WebUntis for any of the lessons.
  final bool attendanceTaken;

  /// Absent students by WebUntis student id, mapped to whether the day is
  /// excused for them.
  final Map<int, bool> absences;

  /// Students who came late, by WebUntis student id, and were not absent.
  final Set<int> late;

  /// Absent students, by WebUntis student id, who were away at a school
  /// activity. Each is in [absences] too, as excused.
  final Set<int> activity;

  /// Those of [activity] who were writing an exam elsewhere.
  final Set<int> exam;

  /// The teacher's lessons with the group that day, cancelled ones left out,
  /// in order.
  final List<WebUntisPeriod> lessons;

  /// Whether [lessons] were narrowed to the periods of one Classi lesson,
  /// rather than being every lesson with the group that day.
  final bool matchedPeriods;

  /// This day narrowed to the periods of one Classi lesson.
  WebUntisLessonDay asMatched() => WebUntisLessonDay(
    lessonCount: lessonCount,
    topics: topics,
    attendanceTaken: attendanceTaken,
    absences: absences,
    late: late,
    activity: activity,
    exam: exam,
    lessons: lessons,
    matchedPeriods: true,
  );
}

/// The response of `getPeriodData2017`: register data plus the students it
/// refers to, so a caller can turn student ids into names without a second
/// round trip.
class WebUntisPeriodDataResult {
  const WebUntisPeriodDataResult({
    required this.dataByTtId,
    required this.referencedStudents,
  });

  factory WebUntisPeriodDataResult.fromJson(Map<String, dynamic> json) {
    final raw = json['dataByTTId'];
    final byId = <int, WebUntisPeriodData>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = readInt(entry.key);
        final value = entry.value;
        if (key == null || value is! Map) {
          continue;
        }
        byId[key] = WebUntisPeriodData.fromJson(
          Map<String, dynamic>.from(value),
        );
      }
    }

    return WebUntisPeriodDataResult(
      dataByTtId: byId,
      referencedStudents: readList(
        json['referencedStudents'],
      ).map(WebUntisPerson.fromJson).toList(growable: false),
    );
  }

  final Map<int, WebUntisPeriodData> dataByTtId;
  final List<WebUntisPerson> referencedStudents;
}

/// Everything `getUserData2017` tells us about the signed-in account and the
/// school's master data.
class WebUntisUserData {
  const WebUntisUserData({
    required this.displayName,
    required this.schoolName,
    required this.elementId,
    required this.elementType,
    required this.klassenIds,
    required this.rights,
    required this.masterDataTimestamp,
    required this.klassen,
    required this.schoolYears,
    this.subjects = const [],
    this.timeGrid = const WebUntisTimeGrid({}),
  });

  factory WebUntisUserData.fromJson(Map<String, dynamic> json) {
    final userData = json['userData'];
    final masterData = json['masterData'];
    final user = userData is Map
        ? Map<String, dynamic>.from(userData)
        : <String, dynamic>{};
    final master = masterData is Map
        ? Map<String, dynamic>.from(masterData)
        : <String, dynamic>{};

    return WebUntisUserData(
      displayName: readString(user['displayName']),
      schoolName: readString(user['schoolName']),
      elementId: readInt(user['elemId']) ?? 0,
      elementType: WebUntisElementType.fromWire(user['elemType']),
      klassenIds: [
        for (final id in (user['klassenIds'] as List<dynamic>? ?? const []))
          ?readInt(id),
      ],
      rights: [
        for (final right in (user['rights'] as List<dynamic>? ?? const []))
          if (right is String) right,
      ],
      masterDataTimestamp: readInt(master['timeStamp']) ?? 0,
      klassen: readList(
        master['klassen'],
      ).map(WebUntisKlasse.fromJson).toList(growable: false),
      schoolYears: readList(
        master['schoolyears'],
      ).map(WebUntisSchoolYear.fromJson).toList(growable: false),
      subjects: readList(
        master['subjects'],
      ).map(WebUntisSubject.fromJson).toList(growable: false),
      timeGrid: WebUntisTimeGrid.fromJson(master['timeGrid']),
    );
  }

  final String displayName;
  final String schoolName;
  final int elementId;
  final WebUntisElementType? elementType;
  final List<int> klassenIds;
  final List<String> rights;
  final int masterDataTimestamp;
  final List<WebUntisKlasse> klassen;
  final List<WebUntisSchoolYear> schoolYears;
  final List<WebUntisSubject> subjects;
  final WebUntisTimeGrid timeGrid;

  /// The school year [date] falls into, or `null` when the server did not
  /// send any school years.
  WebUntisSchoolYear? schoolYearAt(DateTime date) {
    for (final year in schoolYears) {
      if (year.contains(date)) {
        return year;
      }
    }
    return null;
  }
}

/// The students of one class, resolved from the class register.
class WebUntisRoster {
  const WebUntisRoster({
    required this.klasseId,
    required this.students,
    required this.inspectedPeriods,
    required this.from,
    required this.to,
  });

  final int klasseId;
  final List<WebUntisPerson> students;

  /// How many lessons contributed to [students]. Zero means the class had no
  /// lessons in the searched window, which is a different problem from a
  /// lesson whose register the account may not read.
  final int inspectedPeriods;
  final DateTime from;
  final DateTime to;

  bool get isEmpty => students.isEmpty;
}

// --- wire helpers -----------------------------------------------------------

/// Reads an int that a WebUntis server may send as a number or a string.
int? readInt(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String readString(Object? value) => value is String ? value : '';

List<Map<String, dynamic>> readList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return [
    for (final entry in value)
      if (entry is Map) Map<String, dynamic>.from(entry),
  ];
}

/// Parses a WebUntis `yyyy-MM-dd` date.
DateTime? readDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  final parts = value.split('-');
  if (parts.length != 3) {
    return null;
  }
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    return null;
  }
  return DateTime(year, month, day);
}

/// Parses a WebUntis `yyyy-MM-ddTHH:mm[:ss][Z]` timestamp as local wall-clock
/// time.
///
/// The trailing `Z` some servers append is a lie: the value is the school's
/// local time, not UTC. Reading it as UTC would shift lessons across the day
/// boundary for teachers east or west of Greenwich, so the suffix is dropped.
DateTime? readDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  final normalized = value.endsWith('Z')
      ? value.substring(0, value.length - 1)
      : value;
  return DateTime.tryParse(normalized);
}

/// Formats a date the way the WebUntis mobile API expects it.
String formatWebUntisDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}
