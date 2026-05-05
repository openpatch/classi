import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/widgets/student_selection_sheet.dart';

typedef ListItemEditorResult = ({String label, List<String> studentIds});

Future<ListItemEditorResult?> showListItemEditorSheet({
  required BuildContext context,
  required List<Group> groups,
  required List<Student> students,
  required String title,
  String? initialLabel,
  List<String>? initialStudentIds,
  String? preferredGroupId,
  bool allowSelectAllStudents = false,
}) {
  return showModalBottomSheet<ListItemEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _ListItemEditorSheet(
      groups: groups,
      students: students,
      title: title,
      initialLabel: initialLabel,
      initialStudentIds: initialStudentIds,
      preferredGroupId: preferredGroupId,
      allowSelectAllStudents: allowSelectAllStudents,
    ),
  );
}

class _ListItemEditorSheet extends ConsumerStatefulWidget {
  const _ListItemEditorSheet({
    required this.groups,
    required this.students,
    required this.title,
    required this.allowSelectAllStudents,
    this.initialLabel,
    this.initialStudentIds,
    this.preferredGroupId,
  });

  final List<Group> groups;
  final List<Student> students;
  final String title;
  final String? initialLabel;
  final List<String>? initialStudentIds;
  final String? preferredGroupId;
  final bool allowSelectAllStudents;

  @override
  ConsumerState<_ListItemEditorSheet> createState() =>
      _ListItemEditorSheetState();
}

class _ListItemEditorSheetState extends ConsumerState<_ListItemEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelController;
  late final Set<String> _studentIds;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    final validStudentIds = {for (final student in widget.students) student.id};
    _studentIds = {
      for (final studentId in widget.initialStudentIds ?? const <String>[])
        if (validStudentIds.contains(studentId)) studentId,
    };
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _labelController,
                    decoration: InputDecoration(labelText: 'label'.tr()),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'label'.tr()
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_studentIds.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final student in widget.students)
                              if (_studentIds.contains(student.id))
                                InputChip(
                                  avatar: StudentAvatar(
                                    student: student,
                                    size: 24,
                                  ),
                                  label: Text(
                                    studentDisplayName(
                                      firstName: student.firstName,
                                      lastName: student.lastName,
                                      sortField: sortField,
                                    ),
                                  ),
                                  onDeleted: () => setState(
                                    () => _studentIds.remove(student.id),
                                  ),
                                ),
                          ],
                        ),
                      if (_studentIds.isNotEmpty) const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.people_outline),
                        title: Text('link_to_students'.tr()),
                        subtitle: Text(
                          'selected_students'.tr(
                            namedArgs: {'count': '${_studentIds.length}'},
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _pickStudents,
                      ),
                    ],
                  ),
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
                  FilledButton(onPressed: _save, child: Text('save'.tr())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStudents() async {
    final selectedStudentIds = await showStudentSelectionSheet(
      context: context,
      groups: widget.groups,
      students: widget.students,
      selectedStudentIds: _studentIds,
      preferredGroupId: widget.preferredGroupId,
      allowSelectAll: widget.allowSelectAllStudents,
    );
    if (selectedStudentIds == null) {
      return;
    }

    setState(() {
      _studentIds
        ..clear()
        ..addAll(selectedStudentIds);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop((
      label: _labelController.text.trim(),
      studentIds: _studentIds.toList(growable: false),
    ));
  }
}
