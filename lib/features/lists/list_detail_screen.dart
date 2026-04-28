import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/widgets/student_link_chip.dart';
import 'list_item_editor.dart';
import 'list_item_links.dart';

final checklistProvider = StreamProvider.family<Checklist?, int>(
  (ref, listId) => ref.watch(listRepositoryProvider).watchList(listId),
);

final checklistItemsProvider = StreamProvider.family<List<ChecklistItem>, int>(
  (ref, listId) => ref.watch(listRepositoryProvider).watchItems(listId),
);

final listDetailGroupProvider = StreamProvider.family<Group?, int>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final listDetailGroupsProvider = StreamProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).watchActiveGroups(),
);

final listDetailStudentsProvider = StreamProvider.family<List<Student>, int>(
  (ref, groupId) => ref
      .watch(studentRepositoryProvider)
      .watchByGroup(groupId, sortField: ref.watch(studentSortFieldProvider)),
);

final listDetailAllStudentsProvider = StreamProvider<List<Student>>(
  (ref) => ref
      .watch(studentRepositoryProvider)
      .watchAllStudents(sortField: ref.watch(studentSortFieldProvider)),
);

class ListDetailScreen extends ConsumerStatefulWidget {
  const ListDetailScreen({required this.listId, super.key});

  final int listId;

  @override
  ConsumerState<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends ConsumerState<ListDetailScreen> {
  bool _showUncheckedOnly = false;

  @override
  Widget build(BuildContext context) {
    final listValue = ref.watch(checklistProvider(widget.listId));
    final itemsValue = ref.watch(checklistItemsProvider(widget.listId));

    return listValue.when(
      data: (list) {
        if (list == null) {
          return const Scaffold(body: SizedBox.shrink());
        }

        final groupsValue = ref.watch(listDetailGroupsProvider);
        final groupValue = list.groupId == null
            ? null
            : ref.watch(listDetailGroupProvider(list.groupId!));
        final studentsValue = list.groupId == null
            ? ref.watch(listDetailAllStudentsProvider)
            : ref.watch(listDetailStudentsProvider(list.groupId!));
        final group = groupValue?.value;
        final appBarColor = group == null ? null : colorFromHex(group.colorHex);
        final appBarForeground = appBarColor == null
            ? null
            : onColorForBackground(appBarColor);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            foregroundColor: appBarForeground,
            title: AppBarTitle(
              title: list.name,
              subtitle:
                  group?.name ??
                  (list.groupId == null ? 'global_list'.tr() : null),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _renameList(context, list),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addItem(
              context,
              list: list,
              groups: groupsValue.value ?? const <Group>[],
              students: studentsValue.value ?? const <Student>[],
            ),
            icon: const Icon(Icons.add),
            label: Text('add_item'.tr()),
          ),
          body: itemsValue.when(
            data: (items) {
              final groups = groupsValue.value ?? const <Group>[];
              final studentsById = {
                for (final student in studentsValue.value ?? const <Student>[])
                  student.id: student,
              };
              final checkedCount = items
                  .where((item) => item.checkedAt != null)
                  .length;
              final openCount = items.length - checkedCount;
              final visibleItems = _showUncheckedOnly
                  ? items.where((item) => item.checkedAt == null).toList()
                  : items;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            avatar: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                            label: Text(
                              'checked_progress'.tr(
                                namedArgs: {
                                  'checked': '$checkedCount',
                                  'total': '${items.length}',
                                },
                              ),
                            ),
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.radio_button_unchecked,
                              size: 18,
                            ),
                            label: Text(
                              'open_items'.tr(
                                namedArgs: {'count': '$openCount'},
                              ),
                            ),
                          ),
                          FilterChip(
                            selected: _showUncheckedOnly,
                            label: Text('show_unchecked_only'.tr()),
                            onSelected: (value) =>
                                setState(() => _showUncheckedOnly = value),
                          ),
                          if (items.isEmpty && list.groupId != null)
                            OutlinedButton(
                              onPressed: () => ref
                                  .read(listRepositoryProvider)
                                  .populateFromGroup(
                                    listId: list.id,
                                    groupId: list.groupId!,
                                  ),
                              child: Text(
                                'create_items_for_group_students'.tr(),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visibleItems.isEmpty)
                    EmptyState(
                      icon: Icons.checklist_outlined,
                      title: 'empty_list_items'.tr(),
                    )
                  else
                    for (final item in visibleItems)
                      _ChecklistItemTile(
                        item: item,
                        linkedStudents: [
                          for (final studentId in listItemStudentIds(item))
                            if (studentsById[studentId] != null)
                              studentsById[studentId]!,
                        ],
                        onChanged: (checked) => ref
                            .read(listRepositoryProvider)
                            .toggleItem(itemId: item.id, checked: checked),
                        onEdit: () => _editItem(
                          context,
                          list: list,
                          item: item,
                          groups: groups,
                          students: studentsValue.value ?? const <Student>[],
                        ),
                        onDelete: () => ref
                            .read(listRepositoryProvider)
                            .deleteItem(item.id),
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

  Future<void> _renameList(BuildContext context, Checklist list) async {
    final controller = TextEditingController(text: list.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('edit'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'new_list'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text('save'.tr()),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null || name.isEmpty) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .renameList(listId: list.id, name: name);
  }

  Future<void> _addItem(
    BuildContext context, {
    required Checklist list,
    required List<Group> groups,
    required List<Student> students,
  }) async {
    final result = await showListItemEditorSheet(
      context: context,
      groups: groups,
      students: students,
      preferredGroupId: list.groupId,
      allowSelectAllStudents: list.groupId == null,
      title: 'add_item'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .addItem(
          listId: widget.listId,
          label: result.label,
          studentIds: result.studentIds,
        );
  }

  Future<void> _editItem(
    BuildContext context, {
    required Checklist list,
    required ChecklistItem item,
    required List<Group> groups,
    required List<Student> students,
  }) async {
    final result = await showListItemEditorSheet(
      context: context,
      groups: groups,
      students: students,
      preferredGroupId: list.groupId,
      allowSelectAllStudents: list.groupId == null,
      title: 'edit'.tr(),
      initialLabel: item.label,
      initialStudentIds: listItemStudentIds(item),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .updateItem(
          item: item,
          label: result.label,
          studentIds: result.studentIds,
        );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.linkedStudents,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final ChecklistItem item;
  final List<Student> linkedStudents;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final checked = item.checkedAt != null;
    final singleLinkedStudent = linkedStudents.length == 1
        ? linkedStudents.single
        : null;
    final singleLinkedStudentName = singleLinkedStudent == null
        ? null
        : studentDisplayName(
            firstName: singleLinkedStudent.firstName,
            lastName: singleLinkedStudent.lastName,
          );
    final showLinkedStudents =
        linkedStudents.length > 1 ||
        (singleLinkedStudentName != null &&
            singleLinkedStudentName != item.label);
    final subtitleChildren = <Widget>[
      if (item.checkedAt != null)
        Text(
          MaterialLocalizations.of(context).formatMediumDate(item.checkedAt!),
        ),
      if (showLinkedStudents) ...[
        if (item.checkedAt != null) const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final student in linkedStudents)
              StudentLinkChip(student: student, avatarSize: 24),
          ],
        ),
      ],
    ];

    return Card(
      child: ListTile(
        onTap: () => onChanged(!checked),
        leading: singleLinkedStudent == null
            ? linkedStudents.length > 1
                  ? CircleAvatar(child: Text('${linkedStudents.length}'))
                  : null
            : StudentAvatar(student: singleLinkedStudent, size: 36),
        title: Text(item.label),
        subtitle: subtitleChildren.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: subtitleChildren,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: checked,
              onChanged: (value) => onChanged(value ?? false),
            ),
            PopupMenuButton<_ChecklistItemAction>(
              onSelected: (action) {
                switch (action) {
                  case _ChecklistItemAction.edit:
                    onEdit();
                    return;
                  case _ChecklistItemAction.delete:
                    onDelete();
                    return;
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: _ChecklistItemAction.edit,
                  child: Text('edit'.tr()),
                ),
                PopupMenuItem(
                  value: _ChecklistItemAction.delete,
                  child: Text('delete'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _ChecklistItemAction { edit, delete }
