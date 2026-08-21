import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../../features/attendance/attendance_repository.dart';
import '../../features/grades/grade_repository.dart';
import '../../features/groups/group_export_service.dart';
import '../../features/groups/group_repository.dart';
import '../../features/groups/timeframe_grade_repository.dart';
import '../../features/groups/timeframe_repository.dart';
import '../../features/school_years/school_year_repository.dart';
import '../../features/homework/homework_repository.dart';
import '../../features/lists/list_repository.dart';
import '../../features/lessons/lesson_repository.dart';
import '../../features/material_tracking/material_repository.dart';
import '../../features/notes/note_repository.dart';
import '../../features/seating_plan/seating_plan_repository.dart';
import '../../features/sessions/session_repository.dart';
import '../../features/settings/grade_system_controller.dart';
import '../../features/settings/student_sort_controller.dart';
import '../../features/settings/theme_controller.dart';
import '../../features/students/student_repository.dart';
import '../../features/students/student_sorting.dart';
import '../../features/today/today_repository.dart';
import '../database/app_database.dart';
import '../security/biometric_service.dart';
import '../security/key_service.dart';
import '../security/security_preferences_service.dart';
import '../session/app_session_controller.dart';
import '../storage/database_path_service.dart';
import '../storage/library_backup_preferences_service.dart';
import '../storage/library_backup_service.dart';
import '../storage/project_settings_store.dart';
import '../sync/device_identity_service.dart';
import '../update/app_update_controller.dart';

final keyServiceProvider = Provider<KeyService>((ref) => KeyService());

final databasePathServiceProvider = Provider<DatabasePathService>(
  (ref) => DatabasePathService(),
);

final projectSettingsStoreProvider = Provider<ProjectSettingsStore>(
  (ref) => ProjectSettingsStore(
    databasePathService: ref.watch(databasePathServiceProvider),
  ),
);

final securityPreferencesServiceProvider = Provider<SecurityPreferencesService>(
  (ref) => SecurityPreferencesService(
    projectSettingsStore: ref.watch(projectSettingsStoreProvider),
  ),
);

final libraryBackupPreferencesServiceProvider =
    Provider<LibraryBackupPreferencesService>(
      (ref) => LibraryBackupPreferencesService(
        projectSettingsStore: ref.watch(projectSettingsStoreProvider),
      ),
    );

final libraryBackupServiceProvider = Provider<LibraryBackupService>(
  (ref) => LibraryBackupService(),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
);

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>(
  (ref) => DeviceIdentityService(),
);

final appUpdateControllerProvider = ChangeNotifierProvider<AppUpdateController>(
  (ref) => AppUpdateController(),
);

final appSessionProvider = ChangeNotifierProvider<AppSessionController>((ref) {
  final controller = AppSessionController(
    keyService: ref.watch(keyServiceProvider),
    databasePathService: ref.watch(databasePathServiceProvider),
    securityPreferencesService: ref.watch(securityPreferencesServiceProvider),
    libraryBackupPreferencesService: ref.watch(
      libraryBackupPreferencesServiceProvider,
    ),
    libraryBackupService: ref.watch(libraryBackupServiceProvider),
    biometricService: ref.watch(biometricServiceProvider),
    deviceIdentityService: ref.watch(deviceIdentityServiceProvider),
  );
  unawaited(controller.initialize());
  return controller;
});

final selectedDatabasePathProvider = Provider<String?>(
  (ref) => ref.watch(appSessionProvider).databasePath,
);

final studentSortControllerProvider =
    ChangeNotifierProvider<StudentSortController>((ref) {
      final controller = StudentSortController(
        projectSettingsStore: ref.watch(projectSettingsStoreProvider),
      );
      unawaited(controller.initialize());
      ref.listen<String?>(selectedDatabasePathProvider, (previous, next) {
        if (previous != next) {
          unawaited(controller.initialize());
        }
      });
      return controller;
    });

final studentSortFieldProvider = Provider<StudentSortField>(
  (ref) => ref.watch(studentSortControllerProvider).sortField,
);

final themeControllerProvider = ChangeNotifierProvider<ThemeController>((ref) {
  final controller = ThemeController(
    projectSettingsStore: ref.watch(projectSettingsStoreProvider),
  );
  unawaited(controller.initialize());
  ref.listen<String?>(selectedDatabasePathProvider, (previous, next) {
    if (previous != next) {
      unawaited(controller.initialize());
    }
  });
  return controller;
});

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeControllerProvider).themeMode,
);

final gradeSystemControllerProvider =
    ChangeNotifierProvider<GradeSystemController>((ref) {
      final controller = GradeSystemController(
        projectSettingsStore: ref.watch(projectSettingsStoreProvider),
      );
      unawaited(controller.initialize());
      ref.listen<String?>(selectedDatabasePathProvider, (previous, next) {
        if (previous != next) {
          unawaited(controller.initialize());
        }
      });
      return controller;
    });

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = ref.watch(appSessionProvider).database;
  if (database == null) {
    throw StateError('Database is not ready.');
  }
  return database;
});

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(ref.watch(databaseProvider)),
);

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => StudentRepository(ref.watch(databaseProvider)),
);

final gradeRepositoryProvider = Provider<GradeRepository>(
  (ref) => GradeRepository(ref.watch(databaseProvider)),
);

final materialRepositoryProvider = Provider<MaterialRepository>(
  (ref) => MaterialRepository(ref.watch(databaseProvider)),
);

final homeworkRepositoryProvider = Provider<HomeworkRepository>(
  (ref) => HomeworkRepository(ref.watch(databaseProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(databaseProvider)),
);

final listRepositoryProvider = Provider<ListRepository>(
  (ref) => ListRepository(ref.watch(databaseProvider)),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepository(ref.watch(databaseProvider)),
);

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(ref.watch(databaseProvider)),
);

final seatingPlanRepositoryProvider = Provider<SeatingPlanRepository>(
  (ref) => SeatingPlanRepository(ref.watch(databaseProvider)),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.watch(databaseProvider)),
);

final groupExportServiceProvider = Provider<GroupExportService>(
  (ref) => GroupExportService(ref.watch(databaseProvider)),
);

final todayRepositoryProvider = Provider<TodayRepository>(
  (ref) => TodayRepository(ref.watch(databaseProvider)),
);

final todayOverviewProvider = StreamProvider.autoDispose
    .family<List<TodayGroupOverview>, DateTime>(
      (ref, date) =>
          ref.watch(todayRepositoryProvider).watchTodayOverview(date),
    );

final schoolYearRepositoryProvider = Provider<SchoolYearRepository>(
  (ref) => SchoolYearRepository(ref.watch(databaseProvider)),
);

final schoolYearsProvider = StreamProvider.autoDispose<List<SchoolYear>>(
  (ref) => ref.watch(schoolYearRepositoryProvider).watchSchoolYears(),
);

final activeSchoolYearsProvider = StreamProvider.autoDispose<List<SchoolYear>>(
  (ref) => ref.watch(schoolYearRepositoryProvider).watchActiveSchoolYears(),
);

/// The school year new groups default to.
final currentSchoolYearProvider = FutureProvider.autoDispose<SchoolYear?>(
  (ref) => ref.watch(schoolYearRepositoryProvider).currentSchoolYear(),
);

final schoolYearProvider = StreamProvider.autoDispose.family<SchoolYear?, int>(
  (ref, id) => ref.watch(schoolYearRepositoryProvider).watchSchoolYear(id),
);

/// Groups assigned to a school year, archived ones included.
final schoolYearGroupsProvider = StreamProvider.autoDispose
    .family<List<Group>, int>(
      (ref, id) => ref.watch(schoolYearRepositoryProvider).watchGroups(id),
    );

/// The timeframes of one school year, shared by every group in it.
final schoolYearTimeframesProvider = StreamProvider.autoDispose
    .family<List<Timeframe>, int>(
      (ref, schoolYearId) =>
          ref.watch(timeframeRepositoryProvider).watchTimeframes(schoolYearId),
    );

final timeframeRepositoryProvider = Provider<TimeframeRepository>(
  (ref) => TimeframeRepository(ref.watch(databaseProvider)),
);

final timeframeGradeRepositoryProvider = Provider<TimeframeGradeRepository>(
  (ref) => TimeframeGradeRepository(ref.watch(databaseProvider)),
);

final timeframeGradesProvider = StreamProvider.autoDispose
    .family<List<TimeframeGrade>, int>(
      (ref, timeframeId) => ref
          .watch(timeframeGradeRepositoryProvider)
          .watchGradesForTimeframe(timeframeId),
    );

// Stream of timeframe grades for a specific student
final studentTimeframeGradesProvider = StreamProvider.autoDispose
    .family<List<TimeframeGrade>, int>(
      (ref, studentId) => ref
          .watch(timeframeGradeRepositoryProvider)
          .watchGradesForStudent(studentId),
    );

// Stream of timeframes for the school year of a student's group
final studentTimeframesProvider = StreamProvider.autoDispose
    .family<List<Timeframe>, int>((ref, studentId) {
      final studentStream = ref
          .watch(studentRepositoryProvider)
          .watchStudent(studentId);
      return studentStream.asyncExpand((student) {
        if (student == null) return Stream.value(<Timeframe>[]);
        return _timeframesForGroup(ref, student.groupId);
      });
    });

/// The timeframes a group takes part in: those of its school year. Empty while
/// the group is not assigned to one.
final groupTimeframesProvider = StreamProvider.autoDispose
    .family<List<Timeframe>, int>(
      (ref, groupId) => _timeframesForGroup(ref, groupId),
    );

Stream<List<Timeframe>> _timeframesForGroup(Ref ref, int groupId) {
  return ref.watch(groupRepositoryProvider).watchGroup(groupId).asyncExpand((
    group,
  ) {
    final schoolYearId = group?.schoolYearId;
    if (schoolYearId == null) return Stream.value(<Timeframe>[]);
    return ref.watch(timeframeRepositoryProvider).watchTimeframes(schoolYearId);
  });
}

final timeframeCategoryAveragesProvider = StreamProvider.autoDispose
    .family<
      Map<int, Map<String, double>>,
      ({int groupId, DateTime startDate, DateTime endDate})
    >(
      (ref, params) => ref
          .watch(gradeRepositoryProvider)
          .watchGroupCategoryAveragesInDateRange(
            groupId: params.groupId,
            startDate: params.startDate,
            endDate: params.endDate,
          ),
    );

typedef _TimeframeParams = ({
  int groupId,
  DateTime startDate,
  DateTime endDate,
});

final timeframeAttendanceProvider = StreamProvider.autoDispose
    .family<Map<int, List<AttendanceLog>>, _TimeframeParams>(
      (ref, params) => ref
          .watch(attendanceRepositoryProvider)
          .watchAttendanceForGroupInDateRange(
            params.groupId,
            params.startDate,
            params.endDate,
          ),
    );

final timeframeMaterialProvider = StreamProvider.autoDispose
    .family<Map<int, List<MaterialLog>>, _TimeframeParams>(
      (ref, params) => ref
          .watch(materialRepositoryProvider)
          .watchMaterialForGroupInDateRange(
            params.groupId,
            params.startDate,
            params.endDate,
          ),
    );

final timeframeHomeworkProvider = StreamProvider.autoDispose
    .family<Map<int, List<HomeworkLog>>, _TimeframeParams>(
      (ref, params) => ref
          .watch(homeworkRepositoryProvider)
          .watchHomeworkForGroupInDateRange(
            params.groupId,
            params.startDate,
            params.endDate,
          ),
    );

final groupSeatingPlansProvider = StreamProvider.autoDispose
    .family<List<SeatingPlan>, int>(
      (ref, groupId) =>
          ref.watch(seatingPlanRepositoryProvider).watchPlansForGroup(groupId),
    );

final seatingPlanPositionsProvider = StreamProvider.autoDispose
    .family<Map<int, ({int col, int row})>, int>(
      (ref, planId) => ref
          .watch(seatingPlanRepositoryProvider)
          .watchPositionsForPlan(planId),
    );
