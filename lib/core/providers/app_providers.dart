import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../../features/attendance/attendance_repository.dart';
import '../../features/grades/grade_repository.dart';
import '../../features/groups/group_repository.dart';
import '../../features/homework/homework_repository.dart';
import '../../features/lists/list_repository.dart';
import '../../features/lessons/lesson_repository.dart';
import '../../features/material_tracking/material_repository.dart';
import '../../features/notes/note_repository.dart';
import '../../features/seating_plan/seating_plan_repository.dart';
import '../../features/settings/grade_system_controller.dart';
import '../../features/settings/student_sort_controller.dart';
import '../../features/settings/theme_controller.dart';
import '../../features/students/student_repository.dart';
import '../../features/students/student_sorting.dart';
import '../database/app_database.dart';
import '../security/biometric_service.dart';
import '../security/key_service.dart';
import '../security/security_preferences_service.dart';
import '../session/app_session_controller.dart';
import '../storage/database_path_service.dart';
import '../storage/library_backup_preferences_service.dart';
import '../storage/library_backup_service.dart';

final keyServiceProvider = Provider<KeyService>((ref) => KeyService());

final databasePathServiceProvider = Provider<DatabasePathService>(
  (ref) => DatabasePathService(),
);

final securityPreferencesServiceProvider = Provider<SecurityPreferencesService>(
  (ref) => SecurityPreferencesService(),
);

final libraryBackupPreferencesServiceProvider =
    Provider<LibraryBackupPreferencesService>(
      (ref) => LibraryBackupPreferencesService(),
    );

final libraryBackupServiceProvider = Provider<LibraryBackupService>(
  (ref) => LibraryBackupService(),
);

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(),
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
  );
  unawaited(controller.initialize());
  return controller;
});

final studentSortControllerProvider =
    ChangeNotifierProvider<StudentSortController>((ref) {
      final controller = StudentSortController();
      unawaited(controller.initialize());
      return controller;
    });

final studentSortFieldProvider = Provider<StudentSortField>(
  (ref) => ref.watch(studentSortControllerProvider).sortField,
);

final themeControllerProvider =
    ChangeNotifierProvider<ThemeController>((ref) {
      final controller = ThemeController();
      unawaited(controller.initialize());
      return controller;
    });

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(themeControllerProvider).themeMode,
);

final gradeSystemControllerProvider =
    ChangeNotifierProvider<GradeSystemController>((ref) {
      final controller = GradeSystemController();
      unawaited(controller.initialize());
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

final groupSeatingPlansProvider = StreamProvider.autoDispose
    .family<List<SeatingPlan>, int>(
      (ref, groupId) => ref
          .watch(seatingPlanRepositoryProvider)
          .watchPlansForGroup(groupId),
    );

final seatingPlanPositionsProvider = StreamProvider.autoDispose
    .family<Map<int, Offset>, int>(
      (ref, planId) => ref
          .watch(seatingPlanRepositoryProvider)
          .watchPositionsForPlan(planId),
    );
