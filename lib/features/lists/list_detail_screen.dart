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

final checklistProvider = StreamProvider.family<Checklist?, int>(
  (ref, listId) => ref.watch(listRepositoryProvider).watchList(listId),
);

final checklistItemsProvider = StreamProvider.family<List<ChecklistItem>, int>(
  (ref, listId) => ref.watch(listRepositoryProvider).watchItems(listId),
);

final listDetailGroupProvider = StreamProvider.family<Group?, int>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final listDetailStudentsProvider = StreamProvider.family<List<Student>, int>(
  (ref, groupId) => ref
      .watch(studentRepositoryProvider)
      .watchByGroup(groupId, sortField: ref.watch(studentSortFieldProvider)),
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

        final groupValue = ref.watch(listDetailGroupProvider(list.groupId));
        final studentsValue = ref.watch(
          listDetailStudentsProvider(list.groupId),
        );
        final group = groupValue.value;
        final appBarColor = group == null ? null : colorFromHex(group.colorHex);
        final appBarForeground = appBarColor == null
            ? null
            : onColorForBackground(appBarColor);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            foregroundColor: appBarForeground,
            title: AppBarTitle(title: list.name, subtitle: group?.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _renameList(context, list),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addItem(context),
            icon: const Icon(Icons.add),
            label: Text('add_item'.tr()),
          ),
          body: itemsValue.when(
            data: (items) {
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
                          if (items.isEmpty)
                            OutlinedButton(
                              onPressed: () => ref
                                  .read(listRepositoryProvider)
                                  .populateFromGroup(
                                    listId: list.id,
                                    groupId: list.groupId,
                                  ),
                              child: Text('populate_from_group'.tr()),
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
                        student: item.studentId == null
                            ? null
                            : studentsById[item.studentId],
                        onChanged: (checked) => ref
                            .read(listRepositoryProvider)
                            .toggleItem(itemId: item.id, checked: checked),
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

  Future<void> _addItem(BuildContext context) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_item'.tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'add_item'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text('add'.tr()),
          ),
        ],
      ),
    );

    controller.dispose();
    if (label == null || label.isEmpty) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .addItem(listId: widget.listId, label: label);
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.student,
    required this.onChanged,
    required this.onDelete,
  });

  final ChecklistItem item;
  final Student? student;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final checked = item.checkedAt != null;
    final title = student == null
        ? item.label
        : studentDisplayName(
            firstName: student!.firstName,
            lastName: student!.lastName,
          );

    return Card(
      child: ListTile(
        onTap: () => onChanged(!checked),
        leading: student == null
            ? null
            : StudentAvatar(student: student!, size: 36),
        title: Text(title),
        subtitle: item.checkedAt == null
            ? null
            : Text(
                MaterialLocalizations.of(
                  context,
                ).formatMediumDate(item.checkedAt!),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: checked,
              onChanged: (value) => onChanged(value ?? false),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
