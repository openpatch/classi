import 'package:flutter_riverpod/legacy.dart' show ChangeNotifierProvider;

import '../../../core/providers/app_providers.dart';
import '../lesson_support.dart';
import 'student_picker_controller.dart';

/// Controller for the random student picker wheel, per group and lesson date.
///
/// Stores the memory mode (off / lesson / school year) and the set of already
/// picked student ids, persisted via the project settings sidecar.
final studentPickerControllerProvider = ChangeNotifierProvider.autoDispose
    .family<StudentPickerController, (int, DateTime)>(
      (ref, args) => StudentPickerController(
        projectSettingsStore: ref.watch(projectSettingsStoreProvider),
        groupId: args.$1,
        lessonDate: normalizeLessonDate(args.$2),
      ),
    );
