import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/storage/project_settings_store.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:classi/features/school_years/active_school_year_controller.dart';
import 'package:classi/features/school_years/school_year_repository.dart';
import 'package:classi/shared/utils/formatting.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory stand-in for the library settings sidecar.
class _InMemorySettingsStore implements ProjectSettingsStore {
  Map<String, dynamic> _settings = <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> read() async => _settings;

  @override
  Future<void> write(Map<String, dynamic> settings) async {
    _settings = settings;
  }

  @override
  Future<void> update(
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  ) async {
    _settings = transform(await read());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late AppDatabase database;
  late SchoolYearRepository schoolYears;
  late GroupRepository groups;
  late _InMemorySettingsStore settings;

  ActiveSchoolYearController controller() => ActiveSchoolYearController(
    projectSettingsStore: settings,
    schoolYearRepository: schoolYears,
  );

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    schoolYears = SchoolYearRepository(database);
    groups = GroupRepository(database);
    settings = _InMemorySettingsStore();
  });

  tearDown(() async {
    await database.close();
  });

  /// Clears the school year the schema seeds, so each test controls the set.
  Future<void> removeSeededYears() async {
    for (final year in await schoolYears.allSchoolYears()) {
      await schoolYears.deleteSchoolYear(year.id);
    }
  }

  Future<int> addYear(String label, DateTime start, DateTime end) {
    return schoolYears.createSchoolYear(
      label: label,
      startDate: start,
      endDate: end,
    );
  }

  test('picks the year containing today when nothing is stored', () async {
    await removeSeededYears();
    final now = DateTime.now();
    await addYear('past', DateTime(now.year - 3, 8), DateTime(now.year - 2, 7));
    final current = await addYear(
      'current',
      now.subtract(const Duration(days: 30)),
      now.add(const Duration(days: 30)),
    );

    final active = controller();
    await active.initialize();

    expect(active.activeSchoolYearId, current);
  });

  test('prefers the stored choice over the year containing today', () async {
    await removeSeededYears();
    final now = DateTime.now();
    final past = await addYear(
      'past',
      DateTime(now.year - 3, 8),
      DateTime(now.year - 2, 7),
    );
    await addYear(
      'current',
      now.subtract(const Duration(days: 30)),
      now.add(const Duration(days: 30)),
    );

    final first = controller();
    await first.initialize();
    await first.select(past);

    final second = controller();
    await second.initialize();

    expect(second.activeSchoolYearId, past);
  });

  test('falls back when the stored year no longer exists', () async {
    await removeSeededYears();
    final now = DateTime.now();
    final doomed = await addYear(
      'doomed',
      DateTime(now.year - 3, 8),
      DateTime(now.year - 2, 7),
    );
    final survivor = await addYear(
      'current',
      now.subtract(const Duration(days: 30)),
      now.add(const Duration(days: 30)),
    );

    final first = controller();
    await first.initialize();
    await first.select(doomed);
    await schoolYears.deleteSchoolYear(doomed);

    final second = controller();
    await second.initialize();

    expect(second.activeSchoolYearId, survivor);
  });

  test('an archived year stays selected but is flagged read-only', () async {
    await removeSeededYears();
    final now = DateTime.now();
    final archived = await addYear(
      'archived',
      DateTime(now.year - 3, 8),
      DateTime(now.year - 2, 7),
    );
    await addYear(
      'current',
      now.subtract(const Duration(days: 30)),
      now.add(const Duration(days: 30)),
    );

    final active = controller();
    await active.initialize();
    await active.select(archived);
    await schoolYears.archiveSchoolYear(archived);
    await active.refresh();

    expect(active.activeSchoolYearId, archived);
    expect(active.isViewingArchivedYear, isTrue);
  });

  test('groups are listed for the selected year only', () async {
    await removeSeededYears();
    final yearA = await addYear('A', DateTime(2024, 8), DateTime(2025, 7));
    final yearB = await addYear('B', DateTime(2025, 8), DateTime(2026, 7));

    await groups.createGroup(
      name: 'in A',
      gradeScale: defaultGradeScaleEntries,
      schoolYearId: yearA,
    );
    await groups.createGroup(
      name: 'in B',
      gradeScale: defaultGradeScaleEntries,
      schoolYearId: yearB,
    );

    final inA = await groups.watchActiveGroups(schoolYearId: yearA).first;
    expect(inA.map((group) => group.name), ['in A']);

    final all = await groups.watchActiveGroups().first;
    expect(all, hasLength(2));
  });

  test('a group without a school year shows up in every year', () async {
    await removeSeededYears();
    final yearA = await addYear('A', DateTime(2024, 8), DateTime(2025, 7));
    final yearB = await addYear('B', DateTime(2025, 8), DateTime(2026, 7));

    await groups.createGroup(
      name: 'unassigned',
      gradeScale: defaultGradeScaleEntries,
    );

    // Legacy groups predate the year becoming the app's frame; hiding one
    // behind a filter the teacher never set would look like data loss.
    expect(
      (await groups.watchActiveGroups(schoolYearId: yearA).first).single.name,
      'unassigned',
    );
    expect(
      (await groups.watchActiveGroups(schoolYearId: yearB).first).single.name,
      'unassigned',
    );
  });
}
