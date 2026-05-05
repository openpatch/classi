import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/student_avatar.dart';

final groupTrackingGroupProvider = StreamProvider.family<Group?, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final groupTrackingStudentsProvider = StreamProvider.family<List<Student>, String>(
  (ref, groupId) => ref
      .watch(studentRepositoryProvider)
      .watchByGroup(groupId, sortField: ref.watch(studentSortFieldProvider)),
);

final groupMaterialSelectionsProvider =
    StreamProvider.family<Map<String, bool>, (String, DateTime)>(
      (ref, args) => ref
          .watch(materialRepositoryProvider)
          .watchGroupSelections(groupId: args.$1, date: args.$2),
    );

final groupHomeworkSelectionsProvider =
    StreamProvider.family<Map<String, bool>, (String, DateTime)>(
      (ref, args) => ref
          .watch(homeworkRepositoryProvider)
          .watchGroupSelections(groupId: args.$1, date: args.$2),
    );

final groupAbsenceSelectionsProvider =
    StreamProvider.family<Set<String>, (String, DateTime)>(
      (ref, args) => ref
          .watch(attendanceRepositoryProvider)
          .watchGroupSelections(groupId: args.$1, date: args.$2),
    );

class GroupTrackingScreen extends ConsumerStatefulWidget {
  const GroupTrackingScreen({required this.groupId, super.key});

  final String groupId;

  @override
  ConsumerState<GroupTrackingScreen> createState() =>
      _GroupTrackingScreenState();
}

class _GroupTrackingScreenState extends ConsumerState<GroupTrackingScreen> {
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final groupValue = ref.watch(groupTrackingGroupProvider(widget.groupId));
    final studentsValue = ref.watch(
      groupTrackingStudentsProvider(widget.groupId),
    );
    final materialSelectionsValue = ref.watch(
      groupMaterialSelectionsProvider((widget.groupId, _selectedDate)),
    );
    final homeworkSelectionsValue = ref.watch(
      groupHomeworkSelectionsProvider((widget.groupId, _selectedDate)),
    );
    final absenceSelectionsValue = ref.watch(
      groupAbsenceSelectionsProvider((widget.groupId, _selectedDate)),
    );

    return groupValue.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colorFromHex(group.colorHex),
            foregroundColor: onColorForBackground(colorFromHex(group.colorHex)),
            title: AppBarTitle(
              title: 'batch_tracking'.tr(),
              subtitle: group.name,
            ),
          ),
          body: studentsValue.when(
            data: (students) {
              final materialSelections =
                  materialSelectionsValue.value ?? const <String, bool>{};
              final homeworkSelections =
                  homeworkSelectionsValue.value ?? const <String, bool>{};
              final absentStudents =
                  absenceSelectionsValue.value ?? const <String>{};

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('date'.tr()),
                            subtitle: Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_selectedDate),
                            ),
                            trailing: IconButton(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'batch_tracking_hint'.tr(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3.4),
                        1: FlexColumnWidth(1.2),
                        2: FlexColumnWidth(1.6),
                        3: FlexColumnWidth(1.2),
                      },
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          children: [
                            _TrackingHeaderCell(label: 'name'.tr()),
                            _TrackingHeaderCell(label: 'material'.tr()),
                            _TrackingHeaderCell(label: 'homework'.tr()),
                            _TrackingHeaderCell(label: 'absent'.tr()),
                          ],
                        ),
                        for (final student in students)
                          TableRow(
                            decoration: BoxDecoration(
                              color: absentStudents.contains(student.id)
                                  ? Theme.of(context).colorScheme.errorContainer
                                        .withValues(alpha: 0.24)
                                  : null,
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    StudentAvatar(student: student, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        studentDisplayName(
                                          firstName: student.firstName,
                                          lastName: student.lastName,
                                          sortField: sortField,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _TrackingCheckboxCell(
                                value: materialSelections[student.id],
                                enabled: !absentStudents.contains(student.id),
                                onChanged: (value) => _setMaterialValue(
                                  studentId: student.id,
                                  value: value,
                                ),
                              ),
                              _TrackingCheckboxCell(
                                value: homeworkSelections[student.id],
                                enabled: !absentStudents.contains(student.id),
                                onChanged: (value) => _setHomeworkValue(
                                  studentId: student.id,
                                  value: value,
                                ),
                              ),
                              _TrackingBinaryCheckboxCell(
                                value: absentStudents.contains(student.id),
                                onChanged: (value) => _setAbsent(
                                  studentId: student.id,
                                  absent: value,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
            error: (error, _) => const AppErrorState(),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        );
      },
      error: (error, _) => const AppErrorScaffold(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }

    setState(() => _selectedDate = DateUtils.dateOnly(selected));
  }

  Future<void> _setMaterialValue({
    required String studentId,
    required bool? value,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .clearAbsence(studentId: studentId, date: _selectedDate);
    if (value == null) {
      await _clearMaterial(studentId);
      return;
    }

    await _saveMaterial(studentId: studentId, hadMaterial: value);
  }

  Future<void> _setHomeworkValue({
    required String studentId,
    required bool? value,
  }) async {
    await ref
        .read(attendanceRepositoryProvider)
        .clearAbsence(studentId: studentId, date: _selectedDate);
    if (value == null) {
      await _clearHomework(studentId);
      return;
    }

    await _saveHomework(studentId: studentId, hadHomework: value);
  }

  Future<void> _setAbsent({required String studentId, required bool absent}) {
    if (absent) {
      return ref
          .read(attendanceRepositoryProvider)
          .markAbsent(studentId: studentId, date: _selectedDate);
    }

    return ref
        .read(attendanceRepositoryProvider)
        .clearAbsence(studentId: studentId, date: _selectedDate);
  }

  Future<void> _saveMaterial({
    required String studentId,
    required bool hadMaterial,
  }) {
    return ref
        .read(materialRepositoryProvider)
        .saveLog(
          studentId: studentId,
          date: _selectedDate,
          hadMaterial: hadMaterial,
        );
  }

  Future<void> _clearMaterial(String studentId) {
    return ref
        .read(materialRepositoryProvider)
        .clearLog(studentId: studentId, date: _selectedDate);
  }

  Future<void> _saveHomework({
    required String studentId,
    required bool hadHomework,
  }) {
    return ref
        .read(homeworkRepositoryProvider)
        .saveLog(
          studentId: studentId,
          date: _selectedDate,
          hadHomework: hadHomework,
        );
  }

  Future<void> _clearHomework(int studentId) {
    return ref
        .read(homeworkRepositoryProvider)
        .clearLog(studentId: studentId, date: _selectedDate);
  }
}

class _TrackingHeaderCell extends StatelessWidget {
  const _TrackingHeaderCell({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TrackingCheckboxCell extends StatelessWidget {
  const _TrackingCheckboxCell({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool? value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Checkbox(
        tristate: true,
        value: value,
        onChanged: enabled ? (_) => onChanged(_nextValue(value)) : null,
      ),
    );
  }

  bool? _nextValue(bool? currentValue) {
    if (currentValue == null) {
      return true;
    }
    if (currentValue) {
      return false;
    }
    return null;
  }
}

class _TrackingBinaryCheckboxCell extends StatelessWidget {
  const _TrackingBinaryCheckboxCell({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Checkbox(value: value, onChanged: (value) => onChanged(value!)),
    );
  }
}
