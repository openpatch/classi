import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/student_avatar.dart';
import '../../students/student_sorting.dart';
import '../lesson_support.dart';
import 'random_student_groups.dart';

class StudentGroupBuilderSheet extends ConsumerWidget {
  const StudentGroupBuilderSheet({
    required this.groupId,
    required this.date,
    this.periodStart = 0,
    super.key,
  });

  final int groupId;
  final DateTime date;
  final int periodStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsValue = ref.watch(lessonStudentsProvider(groupId));
    final absencesValue = ref.watch(
      lessonAbsenceSelectionsProvider((groupId, date, periodStart)),
    );
    final sortField = ref.watch(studentSortFieldProvider);

    return Scaffold(
      appBar: AppBar(title: Text('group_builder'.tr())),
      body: SafeArea(
        child: studentsValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              AppErrorState(error: error, stackTrace: stackTrace),
          data: (students) => absencesValue.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                AppErrorState(error: error, stackTrace: stackTrace),
            data: (absentIds) {
              if (students.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  title: 'empty_students'.tr(),
                );
              }
              if (students.every((student) => absentIds.contains(student.id))) {
                return EmptyState(
                  icon: Icons.person_off_outlined,
                  title: 'picker_all_absent'.tr(),
                );
              }
              return _GroupBuilder(
                students: students,
                absentStudentIds: absentIds,
                sortField: sortField,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GroupBuilder extends StatefulWidget {
  const _GroupBuilder({
    required this.students,
    required this.absentStudentIds,
    required this.sortField,
  });

  final List<Student> students;
  final Set<int> absentStudentIds;
  final StudentSortField sortField;

  Set<int> get presentIds => {
    for (final student in students)
      if (!absentStudentIds.contains(student.id)) student.id,
  };

  @override
  State<_GroupBuilder> createState() => _GroupBuilderState();
}

class _GroupBuilderState extends State<_GroupBuilder> {
  int _studentsPerGroup = 3;
  List<List<int>> _groups = const [];
  bool _rosterChanged = false;

  @override
  void didUpdateWidget(covariant _GroupBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(oldWidget.presentIds, widget.presentIds)) {
      _rosterChanged = _rosterChanged || _groups.isNotEmpty;
      _groups = const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentCount = widget.presentIds.length;
    final absentCount = widget.students.length - presentCount;
    final studentsPerGroup = min(_studentsPerGroup, presentCount);
    final groupCount = (presentCount / studentsPerGroup).ceil();
    final studentsById = {
      for (final student in widget.students) student.id: student,
    };

    return ContentConstraints(
      child: SingleChildScrollView(
        padding: appScreenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: appCardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'group_builder_hint'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    DropdownButtonFormField<int>(
                      key: ValueKey(studentsPerGroup),
                      initialValue: studentsPerGroup,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'students_per_group'.tr(),
                      ),
                      items: [
                        for (var size = 1; size <= presentCount; size++)
                          DropdownMenuItem(value: size, child: Text('$size')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _studentsPerGroup = value;
                          _groups = const [];
                          _rosterChanged = false;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      'group_builder_summary'.tr(
                        namedArgs: {
                          'students': '$presentCount',
                          'groups': '$groupCount',
                        },
                      ),
                    ),
                    if (absentCount > 0) ...[
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'group_builder_absent_excluded'.tr(
                          namedArgs: {'count': '$absentCount'},
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (_rosterChanged) ...[
                      const SizedBox(height: AppSpacing.small),
                      Text('group_builder_roster_changed'.tr()),
                    ],
                    const SizedBox(height: AppSpacing.large),
                    FilledButton.icon(
                      onPressed: () => setState(() {
                        _groups = [
                          for (final group in buildRandomStudentGroups(
                            students: widget.students,
                            absentStudentIds: widget.absentStudentIds,
                            studentsPerGroup: studentsPerGroup,
                          ))
                            [for (final student in group) student.id],
                        ];
                        _rosterChanged = false;
                      }),
                      icon: const Icon(Icons.shuffle),
                      label: Text(
                        (_groups.isEmpty
                                ? 'generate_groups'
                                : 'reshuffle_groups')
                            .tr(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_groups.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.large),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600 ? 2 : 1;
                  final width =
                      (constraints.maxWidth -
                          AppSpacing.medium * (columns - 1)) /
                      columns;
                  return Wrap(
                    spacing: AppSpacing.medium,
                    runSpacing: AppSpacing.medium,
                    children: [
                      for (var index = 0; index < _groups.length; index++)
                        SizedBox(
                          width: width,
                          child: _RandomGroupCard(
                            number: index + 1,
                            students: [
                              for (final id in _groups[index])
                                studentsById[id]!,
                            ],
                            sortField: widget.sortField,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RandomGroupCard extends StatelessWidget {
  const _RandomGroupCard({
    required this.number,
    required this.students,
    required this.sortField,
  });

  final int number;
  final List<Student> students;
  final StudentSortField sortField;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'random_group_number'.tr(namedArgs: {'number': '$number'}),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.small),
            for (final student in students)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xSmall,
                ),
                child: Row(
                  children: [
                    StudentAvatar(student: student, size: 32),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        studentDisplayName(
                          firstName: student.firstName,
                          lastName: student.lastName,
                          callName: student.callName,
                          sortField: sortField,
                        ),
                      ),
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
