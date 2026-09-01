import '../../core/security/key_service.dart';
import '../../core/storage/database_path_service.dart';
import 'webuntis_api.dart';
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

  /// The students of one WebUntis class, read off its class register.
  ///
  /// WebUntis has no "students of class X" call. What it does have is a
  /// register per lesson, so this walks the class's recent lessons and unions
  /// the students enrolled in them. Lessons held for this class alone are
  /// preferred over lessons shared with another class, because a shared
  /// register would pull in students who are not in the group.
  Future<WebUntisRoster> loadRoster({
    required int klasseId,
    DateTime? reference,
    int? masterDataTimestamp,
  }) async {
    final session = await _requireSession();
    final api = _apiFactory(
      server: session.settings.server,
      school: session.settings.school,
    );

    try {
      final now = reference ?? DateTime.now();
      final windows = <({DateTime from, DateTime to})>[
        (from: now.subtract(_rosterLookBack), to: now.add(_rosterLookAhead)),
        (
          from: now.subtract(_rosterWideLookBack),
          to: now.subtract(_rosterLookBack + const Duration(days: 1)),
        ),
      ];

      for (final window in windows) {
        final periods = await api.fetchTimetable(
          username: session.settings.username,
          secret: session.secret,
          elementId: klasseId,
          elementType: WebUntisElementType.klasse,
          from: window.from,
          to: window.to,
          masterDataTimestamp: masterDataTimestamp ?? 0,
        );

        final candidates = selectRosterPeriods(
          periods,
          klasseId: klasseId,
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

        final students = studentsFromRegisters(periodData);
        if (students.isNotEmpty) {
          return WebUntisRoster(
            klasseId: klasseId,
            students: students,
            inspectedPeriods: candidates.length,
            from: window.from,
            to: window.to,
          );
        }

        // Lessons exist but their registers came back empty: the account is
        // very likely not allowed to read them. Say so instead of widening
        // the search and failing the same way again.
        return WebUntisRoster(
          klasseId: klasseId,
          students: const [],
          inspectedPeriods: candidates.length,
          from: window.from,
          to: window.to,
        );
      }

      return WebUntisRoster(
        klasseId: klasseId,
        students: const [],
        inspectedPeriods: 0,
        from: windows.last.from,
        to: windows.first.to,
      );
    } finally {
      api.dispose();
    }
  }

  /// Absences between [from] and [to], optionally narrowed to one class.
  Future<List<WebUntisAbsence>> loadAbsences({
    required DateTime from,
    required DateTime to,
    int? klasseId,
  }) async {
    final session = await _requireSession();
    final api = _apiFactory(
      server: session.settings.server,
      school: session.settings.school,
    );

    try {
      final absences = await api.fetchStudentAbsences(
        username: session.settings.username,
        secret: session.secret,
        from: from,
        to: to,
      );

      if (klasseId == null) {
        return absences;
      }
      return absences
          .where((absence) => absence.klasseId == klasseId)
          .toList(growable: false);
    } finally {
      api.dispose();
    }
  }

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
