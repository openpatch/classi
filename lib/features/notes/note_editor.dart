import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/student_avatar.dart';

typedef NoteEditorResult = ({
  DateTime createdAt,
  String body,
  String? groupId,
  List<String> studentIds,
  bool isTodo,
});

Future<NoteEditorResult?> showNoteEditorSheet({
  required BuildContext context,
  required List<Group> groups,
  required List<Student> students,
  String? initialGroupId,
  String? initialStudentId,
  List<String>? initialStudentIds,
  String? initialBody,
  bool? initialIsTodo,
  DateTime? initialCreatedAt,
  String? title,
}) {
  return showModalBottomSheet<NoteEditorResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _NoteEditorSheet(
      groups: groups,
      students: students,
      initialGroupId: initialGroupId,
      initialStudentId: initialStudentId,
      initialStudentIds: initialStudentIds,
      initialBody: initialBody,
      initialIsTodo: initialIsTodo,
      initialCreatedAt: initialCreatedAt,
      title: title,
    ),
  );
}

class _NoteEditorSheet extends ConsumerStatefulWidget {
  const _NoteEditorSheet({
    required this.groups,
    required this.students,
    this.initialGroupId,
    this.initialStudentId,
    this.initialStudentIds,
    this.initialBody,
    this.initialIsTodo,
    this.initialCreatedAt,
    this.title,
  });

  final List<Group> groups;
  final List<Student> students;
  final String? initialGroupId;
  final String? initialStudentId;
  final List<String>? initialStudentIds;
  final String? initialBody;
  final bool? initialIsTodo;
  final DateTime? initialCreatedAt;
  final String? title;

  @override
  ConsumerState<_NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends ConsumerState<_NoteEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bodyController;
  bool _isTodo = false;
  String? _groupId;
  late final Set<String> _studentIds;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.initialBody);
    _groupId = widget.initialGroupId;
    _studentIds = {
      ...?widget.initialStudentIds,
      if (widget.initialStudentId != null) widget.initialStudentId!,
    };
    _isTodo = widget.initialIsTodo ?? false;
    _selectedDate = DateUtils.dateOnly(
      widget.initialCreatedAt ?? DateTime.now(),
    );
  }

  @override
  void dispose() {
    _bodyController.dispose();
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
              Text(
                widget.title ?? 'new_note'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    decoration: InputDecoration(labelText: 'note_body'.tr()),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'note_body'.tr()
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
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _groupId,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('link_to_group'.tr()),
                          ),
                          for (final group in widget.groups)
                            DropdownMenuItem<String?>(
                              value: group.id,
                              child: _GroupOptionLabel(group: group),
                            ),
                        ],
                        onChanged: (value) => setState(() => _groupId = value),
                        decoration: InputDecoration(
                          labelText: 'link_to_group'.tr(),
                        ),
                      ),
                      if (_studentIds.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                                  onDeleted: () => _toggleStudentSelection(
                                    student.id,
                                    false,
                                  ),
                                ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
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
              Card(
                child: Column(
                  children: [
                    ListTile(
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
                    SwitchListTile(
                      value: _isTodo,
                      onChanged: (value) => setState(() => _isTodo = value),
                      title: Text('mark_as_todo'.tr()),
                    ),
                  ],
                ),
              ),
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

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final baseDate = widget.initialCreatedAt ?? DateTime.now();
    Navigator.of(context).pop((
      createdAt: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        baseDate.hour,
        baseDate.minute,
        baseDate.second,
        baseDate.millisecond,
        baseDate.microsecond,
      ),
      body: _bodyController.text.trim(),
      groupId: _groupId,
      studentIds: _studentIds.toList(growable: false),
      isTodo: _isTodo,
    ));
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

  void _toggleStudentSelection(String studentId, bool selected) {
    setState(() {
      if (selected) {
        _studentIds.add(studentId);
      } else {
        _studentIds.remove(studentId);
      }
    });
  }

  Future<void> _pickStudents() async {
    final selectedStudentIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _StudentSelectionSheet(
        groups: widget.groups,
        students: widget.students,
        selectedStudentIds: _studentIds,
        preferredGroupId: _groupId,
      ),
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
}

class _GroupOptionLabel extends StatelessWidget {
  const _GroupOptionLabel({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final groupColor = colorFromHex(group.colorHex);
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: groupColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(group.name, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _StudentSelectionSheet extends ConsumerStatefulWidget {
  const _StudentSelectionSheet({
    required this.groups,
    required this.students,
    required this.selectedStudentIds,
    this.preferredGroupId,
  });

  final List<Group> groups;
  final List<Student> students;
  final Set<String> selectedStudentIds;
  final String? preferredGroupId;

  @override
  ConsumerState<_StudentSelectionSheet> createState() =>
      _StudentSelectionSheetState();
}

class _StudentSelectionSheetState
    extends ConsumerState<_StudentSelectionSheet> {
  late final TextEditingController _searchController;
  late final Set<String> _selectedStudentIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedStudentIds = {...widget.selectedStudentIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final sections = _sections;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'link_to_students'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
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
                            sortField: sortField,
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
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colorFromHex(
                                          section.group.colorHex,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        section.group.name,
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
                                        sortField: sortField,
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

  List<_StudentGroupSection> get _sections {
    final normalizedQuery = _query.toLowerCase();
    final sections = <_StudentGroupSection>[];

    for (final group in _orderedGroups) {
      final students =
          [
            for (final student in widget.students)
              if (student.groupId == group.id)
                if (normalizedQuery.isEmpty ||
                    student.firstName.toLowerCase().contains(normalizedQuery) ||
                    student.lastName.toLowerCase().contains(normalizedQuery) ||
                    group.name.toLowerCase().contains(normalizedQuery))
                  student,
          ]..sort((left, right) {
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

      if (students.isNotEmpty) {
        sections.add(_StudentGroupSection(group: group, students: students));
      }
    }

    return sections;
  }

  List<Group> get _orderedGroups {
    final groups = [...widget.groups];
    groups.sort((left, right) {
      final leftPreferred = left.id == widget.preferredGroupId;
      final rightPreferred = right.id == widget.preferredGroupId;
      if (leftPreferred != rightPreferred) {
        return leftPreferred ? -1 : 1;
      }
      return left.name.compareTo(right.name);
    });
    return groups;
  }

  void _toggleStudent(String studentId, bool selected) {
    setState(() {
      if (selected) {
        _selectedStudentIds.add(studentId);
      } else {
        _selectedStudentIds.remove(studentId);
      }
    });
  }
}

class _StudentGroupSection {
  const _StudentGroupSection({required this.group, required this.students});

  final Group group;
  final List<Student> students;
}
