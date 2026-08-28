import 'package:flutter/foundation.dart';

import '../../core/storage/project_settings_store.dart';
import 'school_year_repository.dart';

/// The school year the app is currently showing.
///
/// Classi is a per-year tool: a teacher works in one school year at a time, and
/// last year's groups, timetable and lessons are history rather than clutter.
/// Holding the choice here — rather than as a filter each screen re-applies —
/// means switching the year re-scopes the whole app at once.
///
/// The choice is stored per library (in the library's settings sidecar), so
/// opening a different library does not drag the previous library's year along.
class ActiveSchoolYearController extends ChangeNotifier {
  ActiveSchoolYearController({
    required ProjectSettingsStore projectSettingsStore,
    required SchoolYearRepository schoolYearRepository,
  }) : _projectSettingsStore = projectSettingsStore,
       _schoolYearRepository = schoolYearRepository;

  static const List<String> _settingsPath = ['schoolYears', 'activeId'];

  final ProjectSettingsStore _projectSettingsStore;
  final SchoolYearRepository _schoolYearRepository;

  SchoolYear? _activeSchoolYear;
  List<SchoolYear> _schoolYears = const [];
  bool _isLoaded = false;

  SchoolYear? get activeSchoolYear => _activeSchoolYear;
  int? get activeSchoolYearId => _activeSchoolYear?.id;
  List<SchoolYear> get schoolYears => _schoolYears;
  bool get isLoaded => _isLoaded;

  /// Whether the active year is archived, i.e. the app is looking at history.
  ///
  /// Screens use this to hold back actions that would write into a year the
  /// teacher has already wrapped up.
  bool get isViewingArchivedYear => _activeSchoolYear?.archivedAt != null;

  /// Resolves which year to show, preferring the teacher's stored choice.
  ///
  /// Falls back in the order that matches what someone opening the app would
  /// expect: their stored choice, the year containing today, then the most
  /// recently started year. A library always has at least one school year (the
  /// schema seeds one), so `null` only happens if every year was deleted.
  Future<void> initialize() async {
    _schoolYears = await _schoolYearRepository.allSchoolYears();

    final settings = await _projectSettingsStore.read();
    final storedId = ProjectSettingsStore.intAt(settings, _settingsPath);

    _activeSchoolYear = _resolve(storedId);
    _isLoaded = true;
    notifyListeners();

    // Write back a resolved fallback so the next launch is stable, but only
    // when it actually differs — this runs on every open.
    if (_activeSchoolYear != null && _activeSchoolYear!.id != storedId) {
      await _persist(_activeSchoolYear!.id);
    }
  }

  /// Re-reads the year list without changing the selection where possible.
  ///
  /// Called after years are created, archived or deleted so the switcher and
  /// the scoped screens agree with the database again.
  Future<void> refresh() async {
    _schoolYears = await _schoolYearRepository.allSchoolYears();
    _activeSchoolYear = _resolve(_activeSchoolYear?.id);
    notifyListeners();
  }

  Future<void> select(int schoolYearId) async {
    final match = _schoolYears
        .where((year) => year.id == schoolYearId)
        .firstOrNull;
    if (match == null || match.id == _activeSchoolYear?.id) return;

    _activeSchoolYear = match;
    notifyListeners();
    await _persist(match.id);
  }

  SchoolYear? _resolve(int? preferredId) {
    if (_schoolYears.isEmpty) return null;

    if (preferredId != null) {
      final stored = _schoolYears
          .where((year) => year.id == preferredId)
          .firstOrNull;
      // An archived year stays selectable — a teacher may have deliberately
      // switched to one to look something up, and being thrown out of it on
      // every launch would be worse than the read-only banner.
      if (stored != null) return stored;
    }

    final now = DateTime.now();
    final containingToday = _schoolYears
        .where(
          (year) =>
              !year.startDate.isAfter(now) &&
              !year.endDate.isBefore(now) &&
              year.archivedAt == null,
        )
        .firstOrNull;
    if (containingToday != null) return containingToday;

    final newestActive = _schoolYears
        .where((year) => year.archivedAt == null)
        .firstOrNull;

    // allSchoolYears() is ordered by start date descending, so "first" is the
    // most recently started.
    return newestActive ?? _schoolYears.first;
  }

  Future<void> _persist(int schoolYearId) async {
    await _projectSettingsStore.update((settings) {
      ProjectSettingsStore.setPath(settings, _settingsPath, schoolYearId);
      return settings;
    });
  }
}
