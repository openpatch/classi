import 'dart:convert';

import 'package:classi/core/storage/project_settings_store.dart';
import 'package:classi/features/lessons/student_picker/student_picker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// An in-memory stand-in for the library settings sidecar.
///
/// Encodes on write so a test notices if the controller ever stores something
/// the real JSON sidecar could not hold.
class _InMemorySettingsStore implements ProjectSettingsStore {
  Map<String, dynamic> _settings = <String, dynamic>{};

  Map<String, dynamic> get snapshot => _settings;

  @override
  Future<Map<String, dynamic>> read() async =>
      jsonDecode(jsonEncode(_settings)) as Map<String, dynamic>;

  @override
  Future<void> write(Map<String, dynamic> settings) async {
    _settings = jsonDecode(jsonEncode(settings)) as Map<String, dynamic>;
  }

  @override
  Future<void> update(
    Map<String, dynamic> Function(Map<String, dynamic> current) transform,
  ) async {
    await write(transform(await read()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late _InMemorySettingsStore settings;

  final monday = DateTime(2025, 3, 14);
  final tuesday = DateTime(2025, 3, 15);

  Future<StudentPickerController> controllerFor({
    int groupId = 1,
    DateTime? date,
  }) async {
    final controller = StudentPickerController(
      projectSettingsStore: settings,
      groupId: groupId,
      lessonDate: date ?? monday,
    );
    await controller.initialize();
    return controller;
  }

  setUp(() {
    settings = _InMemorySettingsStore();
  });

  group('student picker memory', () {
    test('defaults to no memory and keeps everyone eligible', () async {
      final controller = await controllerFor();

      expect(controller.isLoaded, isTrue);
      expect(controller.memoryMode, StudentPickerMemoryMode.off);

      await controller.markPicked(1);

      expect(controller.pickedStudentIds, isEmpty);
      expect(controller.eligibleStudents([1, 2, 3], (id) => id), [1, 2, 3]);
    });

    test('drops picked students from the eligible list', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);

      await controller.markPicked(2);

      expect(controller.pickedStudentIds, {2});
      expect(controller.eligibleStudents([1, 2, 3], (id) => id), [1, 3]);
    });

    test('restores the picked set of the same lesson', () async {
      final first = await controllerFor();
      await first.setMemoryMode(StudentPickerMemoryMode.lesson);
      await first.markPicked(2);

      final second = await controllerFor();

      expect(second.memoryMode, StudentPickerMemoryMode.lesson);
      expect(second.pickedStudentIds, {2});
    });

    test('starts the next lesson with an empty memory', () async {
      final first = await controllerFor();
      await first.setMemoryMode(StudentPickerMemoryMode.lesson);
      await first.markPicked(2);

      final second = await controllerFor(date: tuesday);

      expect(second.pickedStudentIds, isEmpty);
      expect(second.eligibleStudents([1, 2, 3], (id) => id), [1, 2, 3]);
    });

    test('keeps only the current lesson date in the sidecar', () async {
      final first = await controllerFor();
      await first.setMemoryMode(StudentPickerMemoryMode.lesson);
      await first.markPicked(2);

      final second = await controllerFor(date: tuesday);
      await second.markPicked(3);

      final byDate = ProjectSettingsStore.valueAt(settings.snapshot, [
        'studentPicker',
        'memory',
        'group_1',
        'byDate',
      ]);
      expect(byDate, {
        '2025-03-15': [3],
      });
    });

    test('keeps school year memory across lessons', () async {
      final first = await controllerFor();
      await first.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await first.markPicked(2);

      final second = await controllerFor(date: tuesday);

      expect(second.pickedStudentIds, {2});
    });

    test('keeps each group separate', () async {
      final first = await controllerFor();
      await first.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await first.markPicked(2);

      final other = await controllerFor(groupId: 2);

      expect(other.memoryMode, StudentPickerMemoryMode.off);
      expect(other.pickedStudentIds, isEmpty);
    });

    test('switching modes keeps both scopes intact', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await controller.markPicked(1);

      // A pick made today counts for this lesson whichever scope recorded it.
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      expect(controller.pickedStudentIds, {1});
      await controller.markPicked(2);

      // Picking within the lesson does not add to the year.
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      expect(controller.pickedStudentIds, {1});

      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      expect(controller.pickedStudentIds, {1, 2});
    });

    test('turning the memory off leaves the stored history alone', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await controller.markPicked(1);

      await controller.setMemoryMode(StudentPickerMemoryMode.off);
      expect(controller.pickedStudentIds, isEmpty);

      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      expect(controller.pickedStudentIds, {1});
    });

    test('startRound clears the memory once everyone had a turn', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      for (final id in [1, 2, 3]) {
        await controller.markPicked(id);
      }

      await controller.startRound([1, 2, 3]);

      expect(controller.pickedStudentIds, isEmpty);
      expect(controller.eligibleStudents([1, 2, 3], (id) => id), [1, 2, 3]);

      final reloaded = await controllerFor();
      expect(reloaded.pickedStudentIds, isEmpty);
    });

    test('startRound keeps a partial round running', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      await controller.markPicked(1);

      await controller.startRound([1, 2, 3]);

      expect(controller.pickedStudentIds, {1});
    });

    test('resetLesson takes today out of the school year', () async {
      final monday_ = await controllerFor();
      await monday_.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await monday_.markPicked(1);

      final today = await controllerFor(date: tuesday);
      await today.markPicked(2);
      expect(today.pickedStudentIds, {1, 2});
      expect(today.lessonPickedIds, {2});

      await today.resetLesson();

      expect(today.pickedStudentIds, {1});
      expect(today.lessonPickedIds, isEmpty);

      final reloaded = await controllerFor(date: tuesday);
      expect(reloaded.pickedStudentIds, {1});
      expect(reloaded.lessonPickedIds, isEmpty);
    });

    test('resetLesson clears the round in the lesson scope', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      await controller.markPicked(1);

      await controller.resetLesson();

      expect(controller.pickedStudentIds, isEmpty);
      final reloaded = await controllerFor();
      expect(reloaded.pickedStudentIds, isEmpty);
    });

    test('a lesson of another day is not forgotten', () async {
      final monday_ = await controllerFor();
      await monday_.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await monday_.markPicked(1);

      final today = await controllerFor(date: tuesday);
      await today.resetLesson();

      expect(today.pickedStudentIds, {1});
    });

    test('resetMemory clears every scope of the group', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await controller.markPicked(1);
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      await controller.markPicked(2);

      await controller.resetMemory();

      expect(controller.pickedStudentIds, isEmpty);
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      expect(controller.pickedStudentIds, isEmpty);

      final reloaded = await controllerFor();
      expect(reloaded.pickedStudentIds, isEmpty);
    });

    test('resetMemory reaches a scope the picker is not set to', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await controller.markPicked(1);
      await controller.setMemoryMode(StudentPickerMemoryMode.off);

      await controller.resetMemory();

      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      expect(controller.pickedStudentIds, isEmpty);
    });

    test('a completed round leaves the other scope alone', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      await controller.markPicked(1);
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      await controller.markPicked(1);

      await controller.startRound([1]);

      expect(controller.pickedStudentIds, isEmpty);
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);
      expect(controller.pickedStudentIds, {1});
    });

    test('picks fired back to back all reach the store', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.schoolYear);

      // The UI does not await markPicked, so the writes have to queue up
      // instead of racing over the same settings snapshot.
      final writes = [
        controller.markPicked(1),
        controller.markPicked(2),
        controller.markPicked(3),
      ];
      await Future.wait(writes);

      final reloaded = await controllerFor();
      expect(reloaded.pickedStudentIds, {1, 2, 3});
    });

    test('exposes an unmodifiable view of the picked ids', () async {
      final controller = await controllerFor();
      await controller.setMemoryMode(StudentPickerMemoryMode.lesson);
      await controller.markPicked(1);

      expect(() => controller.pickedStudentIds.add(2), throwsUnsupportedError);
    });
  });
}
