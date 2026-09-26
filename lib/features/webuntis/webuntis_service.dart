import '../../core/security/key_service.dart';
import '../../core/storage/database_path_service.dart';
import '../lessons/lesson_periods.dart';
import 'webuntis_api.dart';
import 'webuntis_link.dart';
import 'webuntis_models.dart';
import 'webuntis_roster.dart';
import 'webuntis_settings_service.dart';

/// A ready-to-use WebUntis connection: the settings plus the secret that
/// signs every request.
class WebUntisSession {
  const WebUntisSession({required this.settings, required this.secret});

  final WebUntisConnectionSettings settings;
  final String secret;
}

/// The teacher-facing operations Classi needs from WebUntis, on top of the raw
/// [WebUntisApi] calls: connecting, listing classes, resolving a class roster
/// and reading absences.
class WebUntisService {
  WebUntisService({
    required KeyService keyService,
    required DatabasePathService databasePathService,
    required WebUntisSettingsService settingsService,
    WebUntisApi Function({required String server, required String school})?
    apiFactory,
  }) : _keyService = keyService,
       _databasePathService = databasePathService,
       _settingsService = settingsService,
       _apiFactory = apiFactory ?? _defaultApiFactory;

  static WebUntisApi _defaultApiFactory({
    required String server,
    required String school,
  }) => WebUntisApi(server: server, school: school);

  /// How far back the roster search looks before giving up. A class always
  /// has lessons within a fortnight during term; the wider second pass is
  /// there for a group whose import happens over the holidays.
  static const Duration _rosterLookBack = Duration(days: 14);
  static const Duration _rosterLookAhead = Duration(days: 7);
  static const Duration _rosterWideLookBack = Duration(days: 56);

  /// Lessons whose registers are read to build a roster. Several are used
  /// because a single lesson can be a split group, and the most recent ones
  /// are used because a roster changes over a school year.
  static const int _maxPeriodsToInspect = 8;

  final KeyService _keyService;
  final DatabasePathService _databasePathService;
  final WebUntisSettingsService _settingsService;
  final WebUntisApi Function({required String server, required String school})
  _apiFactory;

  Future<WebUntisConnectionSettings?> connectionSettings() =>
      _settingsService.read();

  /// Whether this library has a usable WebUntis connection.
  Future<bool> isConnected() async {
    final settings = await _settingsService.read();
    if (settings == null || !settings.isComplete) {
      return false;
    }
    final secret = await _readSecret();
    return secret != null && secret.isNotEmpty;
  }

  /// Verifies the credentials, exchanges the password for an app shared
  /// secret and stores the connection.
  ///
  /// The password itself is never written anywhere: WebUntis hands out a
  /// secret in exchange for it, and that secret is what ends up in secure
  /// storage.
  Future<WebUntisUserData> connect({
    required String server,
    required String school,
    required String username,
    required String password,
  }) async {
    final host = WebUntisApi.normalizeServer(server);
    final api = _apiFactory(server: host, school: school.trim());
    try {
      final secret = await api.fetchAppSharedSecret(
        username: username.trim(),
        password: password,
      );
      final userData = await api.fetchUserData(
        username: username.trim(),
        secret: secret,
      );

      final dbFile = await _databasePathService.getDatabaseFile();
      await _keyService.setWebUntisSecret(dbFile, secret);
      await _rememberBellTimes(userData);
      await _settingsService.write(
        WebUntisConnectionSettings(
          server: host,
          school: school.trim(),
          username: username.trim(),
          displayName: userData.displayName.isEmpty
              ? null
              : userData.displayName,
        ),
      );

      return userData;
    } finally {
      api.dispose();
    }
  }

  /// Forgets the connection and the stored secret.
  Future<void> disconnect() async {
    final dbFile = await _databasePathService.getDatabaseFile();
    await _keyService.clearWebUntisSecret(dbFile);
    await _settingsService.clear();
  }

  /// The signed-in account and the school's classes.
  Future<WebUntisUserData> loadUserData() async {
    final session = await _requireSession();
    final api = _apiFactory(
      server: session.settings.server,
      school: session.settings.school,
    );
    try {
      return await api.fetchUserData(
        username: session.settings.username,
        secret: session.secret,
      );
    } finally {
      api.dispose();
    }
  }

  /// The teacher's courses, read off their own timetable.
  ///
  /// Looks at the weeks around [reference]; when that turns up nothing,
  /// during the holidays say, it looks further back. An account that is not
  /// a teacher has no courses.
  Future<List<WebUntisCourse>> loadCourses({DateTime? reference}) async {
    final session = await _requireSession();
    final api = _apiFactory(
      server: session.settings.server,
      school: session.settings.school,
    );

    try {
      final user = await api.fetchUserData(
        username: session.settings.username,
        secret: session.secret,
      );
      if (!_isTeacher(user)) {
        return const [];
      }

      final now = reference ?? DateTime.now();
      final windows = [
        // The last week and the next two: a full timetable cycle even at
        // schools that alternate A and B weeks.
        (
          from: now.subtract(const Duration(days: 7)),
          to: now.add(const Duration(days: 14)),
        ),
        (from: now.subtract(_rosterWideLookBack), to: now),
      ];
      for (final window in windows) {
        final periods = await api.fetchTimetable(
          username: session.settings.username,
          secret: session.secret,
          elementId: user.elementId,
          elementType: WebUntisElementType.teacher,
          from: window.from,
          to: window.to,
          masterDataTimestamp: user.masterDataTimestamp,
        );
        final courses = coursesFromTimetable(periods, user);
        if (courses.isNotEmpty) {
          return courses;
        }
      }
      return const [];
    } finally {
      api.dispose();
    }
  }

  /// The students of a linked group, read off its class registers.
  ///
  /// WebUntis has no "students of class X" call. What it does have is a
  /// register per lesson, so this walks the group's recent lessons and unions
  /// the students enrolled in them. A course is read from the teacher's own
  /// timetable, where its lessons are; a class from the class timetable.
  Future<WebUntisRoster> loadRoster({
    required WebUntisGroupLink link,
    DateTime? reference,
  }) async {
    final session = await _requireSession();
    final api = _apiFactory(
      server: session.settings.server,
      school: session.settings.school,
    );

    try {
      final user = await api.fetchUserData(
        username: session.settings.username,
        secret: session.secret,
      );
      final byTeacher = link.isCourse && _isTeacher(user);
      final elementId = byTeacher ? user.elementId : link.klasseId;
      final now = reference ?? DateTime.now();
      final windows = <({DateTime from, DateTime to})>[
        (from: now.subtract(_rosterLookBack), to: now.add(_rosterLookAhead)),
        (
          from: now.subtract(_rosterWideLookBack),
          to: now.subtract(_rosterLookBack + const Duration(days: 1)),
        ),
      ];

      WebUntisRoster emptyRoster(int inspected) => WebUntisRoster(
        klasseId: link.klasseId ?? 0,
        students: const [],
        inspectedPeriods: inspected,
        from: windows.last.from,
        to: windows.first.to,
      );

      if (elementId == null) {
        return emptyRoster(0);
      }

      for (final window in windows) {
        final periods = await api.fetchTimetable(
          username: session.settings.username,
          secret: session.secret,
          elementId: elementId,
          elementType: byTeacher
              ? WebUntisElementType.teacher
              : WebUntisElementType.klasse,
          from: window.from,
          to: window.to,
          masterDataTimestamp: user.masterDataTimestamp,
        );

        final candidates = selectRosterPeriods(
          periods,
          link: link,
          limit: _maxPeriodsToInspect,
        );
        if (candidates.isEmpty) {
          continue;
        }

        final periodData = await api.fetchPeriodData(
          username: session.settings.username,
          secret: session.secret,
          periodIds: candidates.map((period) => period.id),
        );

        // Lessons exist but their registers may come back empty: the account
        // is very likely not allowed to read them. Say so instead of widening
        // the search and failing the same way again.
        return WebUntisRoster(
          klasseId: link.klasseId ?? 0,
          students: studentsFromRegisters(periodData),
          inspectedPeriods: candidates.length,
          from: window.from,
          to: window.to,
        );
      }

      return emptyRoster(0);
    } finally {
      api.dispose();
    }
  }

  /// What the WebUntis class register says about a linked group's lessons on
  /// [date]: their topics and who was absent or late.
  ///
  /// Only lessons the signed-in teacher gives count, which is why the
  /// teacher's own timetable is read rather than the class's: the class's
  /// would bring in every colleague's lessons too. An account that is not a
  /// teacher falls back to the class timetable, and has nothing to show for
  /// a course.
  ///
  /// With [periods], only the lessons in those school periods count, matched
  /// through the school's time grid: a group seen in periods 1–2 and 5–6 on
  /// one day is two lessons to Classi, and each should see its own.
  Future<WebUntisLessonDay> loadLessonDay({
    required WebUntisGroupLink link,
    required DateTime date,
    LessonPeriods? periods,
  }) async {
    final session = await _requireSession();
    final api = _apiFactory(
      server: session.settings.server,
      school: session.settings.school,
    );
    try {
      return await _readLessonDay(api, session, link, date, periods);
    } finally {
      api.dispose();
    }
  }

  Future<WebUntisLessonDay> _readLessonDay(
    WebUntisApi api,
    WebUntisSession session,
    WebUntisGroupLink link,
    DateTime date,
    LessonPeriods? periods,
  ) async {
    final user = await api.fetchUserData(
      username: session.settings.username,
      secret: session.secret,
    );
    await _rememberBellTimes(user);
    final isTeacher = _isTeacher(user);
    final elementId = isTeacher ? user.elementId : link.klasseId;
    if (elementId == null) {
      return WebUntisLessonDay.empty;
    }
    final day = DateTime(date.year, date.month, date.day);

    final timetable = await api.fetchTimetable(
      username: session.settings.username,
      secret: session.secret,
      elementId: elementId,
      elementType: isTeacher
          ? WebUntisElementType.teacher
          : WebUntisElementType.klasse,
      from: day,
      to: day,
      masterDataTimestamp: user.masterDataTimestamp,
    );

    var lessons =
        timetable
            .where((period) => !period.cancelled && link.includes(period))
            .toList()
          ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    // Without a time grid there is nothing to match periods against, and the
    // whole day is the best that can be done.
    final matchPeriods = periods != null && !user.timeGrid.isEmpty;
    if (matchPeriods) {
      lessons = [
        for (final lesson in lessons)
          if (user.timeGrid.periodAt(lesson.startDateTime) case final number?
              when number >= periods.start && number <= periods.end)
            lesson,
      ];
    }
    if (lessons.isEmpty) {
      return WebUntisLessonDay.empty;
    }

    final data = await api.fetchPeriodData(
      username: session.settings.username,
      secret: session.secret,
      periodIds: lessons.map((period) => period.id),
    );

    final lessonDay = WebUntisLessonDay.fromRegisters(lessons, data.dataByTtId);
    return matchPeriods ? lessonDay.asMatched() : lessonDay;
  }

  /// Keeps the school's bell times in the library, so lesson mode can tell
  /// which lesson is running without asking WebUntis.
  Future<void> _rememberBellTimes(WebUntisUserData user) async {
    if (user.timeGrid.isEmpty) return;
    try {
      await _settingsService
          .writeBellTimes(user.timeGrid.unitsByWeekday)
          .timeout(const Duration(seconds: 2));
    } on Object {
      // Bell times are a convenience; failing to store them must not fail
      // the call that read them.
    }
  }

  static bool _isTeacher(WebUntisUserData user) =>
      user.elementType == WebUntisElementType.teacher && user.elementId != 0;

  Future<void> markSynced() => _settingsService.setLastSyncedAt(DateTime.now());

  Future<String?> _readSecret() async {
    final dbFile = await _databasePathService.getDatabaseFile();
    return _keyService.getWebUntisSecret(dbFile);
  }

  Future<WebUntisSession> _requireSession() async {
    final settings = await _settingsService.read();
    final secret = await _readSecret();
    if (settings == null ||
        !settings.isComplete ||
        secret == null ||
        secret.isEmpty) {
      throw const WebUntisException(WebUntisErrorCode.notConfigured);
    }
    return WebUntisSession(settings: settings, secret: secret);
  }
}
