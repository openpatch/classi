import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../utils/grade_categories.dart';
import '../utils/formatting.dart';
import 'student_avatar.dart';

Future<List<int>?> showStudentSelectionSheet({
  required BuildContext context,
  required List<Group> groups,
  required List<Student> students,
  required Set<int> selectedStudentIds,
  int? preferredGroupId,
  bool allowSelectAll = false,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _StudentSelectionSheet(
      groups: groups,
      students: students,
      selectedStudentIds: selectedStudentIds,
      preferredGroupId: preferredGroupId,
      allowSelectAll: allowSelectAll,
    ),
  );
}

class _StudentSelectionSheet extends StatefulWidget {
  const _StudentSelectionSheet({
    required this.groups,
    required this.students,
    required this.selectedStudentIds,
    required this.allowSelectAll,
    this.preferredGroupId,
  });

  final List<Group> groups;
  final List<Student> students;
  final Set<int> selectedStudentIds;
  final int? preferredGroupId;
  final bool allowSelectAll;

  @override
  State<_StudentSelectionSheet> createState() => _StudentSelectionSheetState();
}

class _StudentSelectionSheetState extends State<_StudentSelectionSheet> {
  late final TextEditingController _searchController;
  late final Set<int> _selectedStudentIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    final validStudentIds =
        widget.students.map((student) => student.id).toSet();
    _selectedStudentIds =
        widget.selectedStudentIds.intersection(validStudentIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + keyboardInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'link_to_students'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.allowSelectAll && widget.students.isNotEmpty)
                  TextButton(
                    onPressed:
                        _selectedStudentIds.length == widget.students.length
                        ? _clearSelection
                        : _selectAllStudents,
                    child: Text(
                      _selectedStudentIds.length == widget.students.length
                          ? 'clear_selection'.tr()
                          : 'select_all_students'.tr(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                labelText: 'search_students'.tr(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedStudentIds.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final student in widget.students)
                    if (_selectedStudentIds.contains(student.id))
                      InputChip(
                        avatar: StudentAvatar(student: student, size: 24),
                        label: Text(
                          studentDisplayName(
                            firstName: student.firstName,
                            lastName: student.lastName,
                          ),
                        ),
                        onDeleted: () => _toggleStudent(student.id, false),
                      ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: sections.isEmpty
                  ? Center(child: Text('no_students_found'.tr()))
                  : ListView.separated(
                      itemCount: sections.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (section.color != null)
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: section.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    if (section.color != null)
                                      const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        section.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                for (final student in section.students)
                                  CheckboxListTile(
                                    value: _selectedStudentIds.contains(
                                      student.id,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    secondary: StudentAvatar(
                                      student: student,
                                      size: 32,
                                    ),
                                    title: Text(
                                      studentDisplayName(
                                        firstName: student.firstName,
                                        lastName: student.lastName,
                                      ),
                                    ),
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                    onChanged: (value) => _toggleStudent(
                                      student.id,
                                      value ?? false,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_selectedStudentIds.toList(growable: false)),
                  child: Text('save'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<_StudentSelectionSection> get _sections {
    final groupsById = {for (final group in widget.groups) group.id: group};
    final studentsByGroupId = <int?, List<Student>>{};
    for (final student in widget.students) {
      studentsByGroupId.putIfAbsent(student.groupId, () => []).add(student);
    }

    final orderedGroupIds =
        [
          ...{
            ...widget.groups.map((group) => group.id),
            ...studentsByGroupId.keys.whereType<int>(),
          },
        ]..sort((left, right) {
          final leftPreferred = left == widget.preferredGroupId;
          final rightPreferred = right == widget.preferredGroupId;
          if (leftPreferred != rightPreferred) {
            return leftPreferred ? -1 : 1;
          }
          final leftGroup = groupsById[left];
          final rightGroup = groupsById[right];
          if (leftGroup == null && rightGroup == null) {
            return left.compareTo(right);
          }
          if (leftGroup == null) {
            return 1;
          }
          if (rightGroup == null) {
            return -1;
          }
          return leftGroup.name.compareTo(rightGroup.name);
        });

    final normalizedQuery = _query.toLowerCase();
    final sections = <_StudentSelectionSection>[];

    for (final groupId in orderedGroupIds) {
      final group = groupsById[groupId];
      final students = [...?studentsByGroupId[groupId]]
        ..sort((left, right) {
          final leftSelected = _selectedStudentIds.contains(left.id);
          final rightSelected = _selectedStudentIds.contains(right.id);
          if (leftSelected != rightSelected) {
            return leftSelected ? -1 : 1;
          }
          final lastNameCompare = left.lastName.compareTo(right.lastName);
          if (lastNameCompare != 0) {
            return lastNameCompare;
          }
          return left.firstName.compareTo(right.firstName);
        });

      final visibleStudents = [
        for (final student in students)
          if (normalizedQuery.isEmpty ||
              student.firstName.toLowerCase().contains(normalizedQuery) ||
              student.lastName.toLowerCase().contains(normalizedQuery) ||
              (group?.name.toLowerCase().contains(normalizedQuery) ?? false))
            student,
      ];
      if (visibleStudents.isEmpty) {
        continue;
      }

      sections.add(
        _StudentSelectionSection(
          title: group?.name ?? 'unknown_group'.tr(),
          color: group == null ? null : colorFromHex(group.colorHex),
          students: visibleStudents,
        ),
      );
    }

    return sections;
  }

  void _toggleStudent(int studentId, bool selected) {
    setState(() {
      if (selected) {
        _selectedStudentIds.add(studentId);
      } else {
        _selectedStudentIds.remove(studentId);
      }
    });
  }

  void _selectAllStudents() {
    setState(() {
      _selectedStudentIds
        ..clear()
        ..addAll(widget.students.map((student) => student.id));
    });
  }

  void _clearSelection() {
    setState(_selectedStudentIds.clear);
  }
}

class _StudentSelectionSection {
  const _StudentSelectionSection({
    required this.title,
    required this.students,
    this.color,
  });

  final String title;
  final Color? color;
  final List<Student> students;
}
