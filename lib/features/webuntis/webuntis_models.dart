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
    );
  }

  final int id;
  final int lessonId;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<WebUntisPeriodElement> elements;

  /// The classes this lesson is held for.
  Set<int> get klasseIds => {
    for (final element in elements)
      if (element.type == WebUntisElementType.klasse) element.id,
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

/// The class register data of one lesson.
class WebUntisPeriodData {
  const WebUntisPeriodData({
    required this.ttId,
    required this.absenceChecked,
    required this.studentIds,
    required this.absences,
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
    );
  }

  final int ttId;
  final bool absenceChecked;
  final List<int> studentIds;
  final List<WebUntisAbsence> absences;
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
