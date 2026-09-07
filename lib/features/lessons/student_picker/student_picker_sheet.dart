import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../../students/student_sorting.dart';
import '../lesson_support.dart';
import 'spinning_wheel.dart';
import 'student_picker_controller.dart';
import 'student_picker_providers.dart';

/// Full-screen dialog with a spinning wheel that picks a random student.
///
/// Students marked absent for the lesson are left off the wheel. The wheel can
/// optionally remember who was already picked so everyone gets a turn before
/// anyone repeats; the memory scope is settable per group: off, lesson, or
/// school year.
class StudentPickerSheet extends ConsumerStatefulWidget {
  const StudentPickerSheet({
    required this.groupId,
    required this.date,
    super.key,
  });

  final int groupId;
  final DateTime date;

  @override
  ConsumerState<StudentPickerSheet> createState() => _StudentPickerSheetState();
}

class _StudentPickerSheetState extends ConsumerState<StudentPickerSheet> {
  final _wheelKey = GlobalKey<SpinningWheelState>();

  // The students the current round was started with. The wheel keeps showing
  // them after it stops, so the winner does not vanish from under the pointer
  // when the memory drops them from the eligible list.
  List<Student> _roundStudents = const [];
  Student? _result;
  bool _isSpinning = false;

  (int, DateTime) get _pickerArgs => (widget.groupId, widget.date);

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(studentPickerControllerProvider(_pickerArgs).notifier)
          .initialize(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final controller = ref.watch(studentPickerControllerProvider(_pickerArgs));
    final studentsValue = ref.watch(lessonStudentsProvider(widget.groupId));
    final absencesValue = ref.watch(
      lessonAbsenceSelectionsProvider(_pickerArgs),
    );

    if (!controller.isLoaded || !studentsValue.hasValue) {
      return Scaffold(
        appBar: AppBar(title: Text('random_student'.tr())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final students = studentsValue.value ?? const <Student>[];
    if (students.isEmpty) {
      return _message('empty_students'.tr());
    }

    final absentIds = absencesValue.value ?? const <int>{};
    final present = [
      for (final student in students)
        if (!absentIds.contains(student.id)) student,
    ];
    if (present.isEmpty) {
      return _message('picker_all_absent'.tr());
    }

    final absentCount = students.length - present.length;
    final wheelStudents = _roundStudents.isEmpty
        ? controller.eligibleStudents(present, (student) => student.id)
        : _roundStudents;
    final labels = [
      for (final student in wheelStudents) _nameOf(student, sortField),
    ];

    final pickedIds = controller.pickedStudentIds;
    final pickedCount = present
        .where((student) => pickedIds.contains(student.id))
        .length;
    final hasMemory = controller.memoryMode != StudentPickerMemoryMode.off;

    return Scaffold(
      appBar: AppBar(title: Text('random_student'.tr())),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_result != null) ...[
                    _ResultCard(student: _result!, sortField: sortField),
                    const SizedBox(height: AppSpacing.large),
                  ],
                  SpinningWheel(
                    key: _wheelKey,
                    segments: labels,
                    onComplete: _onSpinComplete,
                  ),
                  const SizedBox(height: AppSpacing.xLarge),
                  if (hasMemory) ...[
                    Text(
                      'picked_progress'.tr(
                        namedArgs: {
                          'picked': '$pickedCount',
                          'total': '${present.length}',
                        },
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  if (absentCount > 0) ...[
                    Text(
                      'picker_absent_excluded'.tr(
                        namedArgs: {'count': '$absentCount'},
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  FilledButton.icon(
                    onPressed: _isSpinning ? null : () => _spin(present),
                    icon: const Icon(Icons.casino_outlined),
                    label: Text('spin'.tr()),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _MemoryModeSelector(args: _pickerArgs, enabled: !_isSpinning),
                  const SizedBox(height: AppSpacing.medium),
                  // Offered whatever the scope is: the school year cannot be
                  // reached from here otherwise.
                  TextButton.icon(
                    onPressed: _isSpinning ? null : _resetMemory,
                    icon: const Icon(Icons.refresh),
                    label: Text('reset_memory'.tr()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _message(String text) => Scaffold(
    appBar: AppBar(title: Text('random_student'.tr())),
    body: Center(child: Text(text)),
  );

  String _nameOf(Student student, StudentSortField sortField) =>
      studentDisplayName(
        firstName: student.firstName,
        lastName: student.lastName,
        callName: student.callName,
        sortField: sortField,
      );

  Future<void> _spin(List<Student> present) async {
    if (_isSpinning) return;
    final controller = ref.read(
      studentPickerControllerProvider(_pickerArgs).notifier,
    );
    // Everyone had a turn? Then this spin opens a new round.
    await controller.startRound([for (final student in present) student.id]);
    if (!mounted) return;

    final round = controller.eligibleStudents(present, (student) => student.id);
    if (round.isEmpty) return;

    setState(() {
      _roundStudents = List<Student>.unmodifiable(round);
      _result = null;
      _isSpinning = true;
    });

    // The wheel needs a frame to pick up the new segments before it can aim at
    // one of them.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_wheelKey.currentState?.spin() != true) {
        setState(() => _isSpinning = false);
      }
    });
  }

  void _onSpinComplete(int index) {
    if (index < 0 || index >= _roundStudents.length) {
      setState(() => _isSpinning = false);
      return;
    }
    final picked = _roundStudents[index];
    ref
        .read(studentPickerControllerProvider(_pickerArgs).notifier)
        .markPicked(picked.id);
    setState(() {
      _result = picked;
      _isSpinning = false;
    });
  }

  Future<void> _resetMemory() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_reset_picker_memory'.tr(),
      body: 'confirm_reset_picker_memory_body'.tr(),
      confirmKey: 'reset',
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(studentPickerControllerProvider(_pickerArgs).notifier)
        .resetMemory();
    if (!mounted) return;
    setState(() {
      _result = null;
      _roundStudents = const [];
    });
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.student, required this.sortField});

  final Student student;
  final StudentSortField sortField;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Row(
          children: [
            StudentAvatar(student: student, size: 48),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'selected_student'.tr(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    studentDisplayName(
                      firstName: student.firstName,
                      lastName: student.lastName,
                      callName: student.callName,
                      sortField: sortField,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryModeSelector extends ConsumerWidget {
  const _MemoryModeSelector({required this.args, required this.enabled});

  final (int, DateTime) args;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(studentPickerControllerProvider(args));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'picker_memory'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.small),
        SegmentedButton<StudentPickerMemoryMode>(
          segments: [
            ButtonSegment(
              value: StudentPickerMemoryMode.off,
              label: Text('memory_off'.tr()),
            ),
            ButtonSegment(
              value: StudentPickerMemoryMode.lesson,
              label: Text('memory_lesson'.tr()),
            ),
            ButtonSegment(
              value: StudentPickerMemoryMode.schoolYear,
              label: Text('memory_school_year'.tr()),
            ),
          ],
          selected: {controller.memoryMode},
          onSelectionChanged: enabled
              ? (modes) => ref
                    .read(studentPickerControllerProvider(args).notifier)
                    .setMemoryMode(modes.first)
              : null,
          showSelectedIcon: false,
        ),
      ],
    );
  }
}
