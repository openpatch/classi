import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/swipe_action_background.dart';
import 'list_editor.dart';
import 'list_repository.dart';

final listsProvider = StreamProvider.family<List<Checklist>, int>(
  (ref, groupId) => ref.watch(listRepositoryProvider).watchLists(groupId),
);

final allListsProvider = StreamProvider<List<Checklist>>(
  (ref) => ref.watch(listRepositoryProvider).watchAllLists(),
);

final archivedAllListsProvider = StreamProvider<List<Checklist>>(
  (ref) => ref.watch(listRepositoryProvider).watchArchivedAllLists(),
);

final listsGroupsProvider = FutureProvider<List<Group>>(
  (ref) => ref.watch(groupRepositoryProvider).allActiveGroups(),
);

final listsGroupProvider = StreamProvider.family<Group?, int>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final listProgressProvider =
    StreamProvider.family<Map<int, ListProgress>, int?>(
      (ref, groupId) =>
          ref.watch(listRepositoryProvider).watchListProgress(groupId: groupId),
    );

class ListsScreen extends ConsumerStatefulWidget {
  const ListsScreen({this.groupId, super.key});

  final int? groupId;

  @override
  ConsumerState<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends ConsumerState<ListsScreen> {
  bool get _isOverview => widget.groupId == null;

  @override
  Widget build(BuildContext context) {
    final listsValue = _isOverview
        ? ref.watch(allListsProvider)
        : ref.watch(listsProvider(widget.groupId!));
    final archivedListsValue = _isOverview
        ? ref.watch(archivedAllListsProvider)
        : null;
    final groupsValue = ref.watch(listsGroupsProvider);
    final groupValue = _isOverview
        ? null
        : ref.watch(listsGroupProvider(widget.groupId!));
    final progressValue = ref.watch(
      listProgressProvider(_isOverview ? null : widget.groupId),
    );
    final group = groupValue?.value;
    final appBarColor = group == null ? null : colorFromHex(group.colorHex);
    final appBarForeground = appBarColor == null
        ? null
        : onColorForBackground(appBarColor);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        foregroundColor: appBarForeground,
        title: Text('lists'.tr()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _createList(context, ref, groupsValue.value ?? const []),
        icon: const Icon(Icons.add),
        label: Text('new_list'.tr()),
      ),
      body: _isOverview
          ? DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: 'all'.tr()),
                      Tab(text: 'archived'.tr()),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ListsList(
                          listsValue: listsValue,
                          groupsValue: groupsValue,
                          progress:
                              progressValue.value ??
                              const <int, ListProgress>{},
                          listPathBuilder: (list) => '/lists/${list.id}',
                          onArchiveList: (list) => ref
                              .read(listRepositoryProvider)
                              .archiveList(list.id),
                          onUnarchiveList: (list) => ref
                              .read(listRepositoryProvider)
                              .unarchiveList(list.id),
                          onDeleteList: (list) =>
                              _deleteList(context, ref, list),
                          onDeleteListDirect: (list) => ref
                              .read(listRepositoryProvider)
                              .deleteList(list.id),
                        ),
                        _ListsList(
                          listsValue: archivedListsValue!,
                          groupsValue: groupsValue,
                          progress:
                              progressValue.value ??
                              const <int, ListProgress>{},
                          listPathBuilder: (list) => '/lists/${list.id}',
                          archived: true,
                          onArchiveList: (list) => ref
                              .read(listRepositoryProvider)
                              .archiveList(list.id),
                          onUnarchiveList: (list) => ref
                              .read(listRepositoryProvider)
                              .unarchiveList(list.id),
                          onDeleteList: (list) =>
                              _deleteList(context, ref, list),
                          onDeleteListDirect: (list) => ref
                              .read(listRepositoryProvider)
                              .deleteList(list.id),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : _ListsList(
              listsValue: listsValue,
              groupsValue: groupsValue,
              progress: progressValue.value ?? const <int, ListProgress>{},
              listPathBuilder: (list) =>
                  '/groups/${widget.groupId}/lists/${list.id}',
              onArchiveList: (list) =>
                  ref.read(listRepositoryProvider).archiveList(list.id),
              onUnarchiveList: (list) =>
                  ref.read(listRepositoryProvider).unarchiveList(list.id),
              onDeleteList: (list) => _deleteList(context, ref, list),
              onDeleteListDirect: (list) =>
                  ref.read(listRepositoryProvider).deleteList(list.id),
            ),
    );
  }

  Future<void> _createList(
    BuildContext context,
    WidgetRef ref,
    List<Group> groups,
  ) async {
    if (!_isOverview) {
      await _createListForGroup(context, ref, widget.groupId!);
      return;
    }

    final result = await showListEditorDialog(
      context: context,
      groups: groups,
      title: 'new_list'.tr(),
      actionLabel: 'add'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .createListWithOptions(
          groupId: result.groupId,
          name: result.name,
          populateFromGroupStudents: result.populateFromGroupStudents,
          sortField: ref.read(studentSortFieldProvider),
        );
  }

  Future<void> _createListForGroup(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final group = (await ref.read(listsGroupProvider(groupId).future))!;
    if (!context.mounted) {
      return;
    }
    final result = await showListEditorDialog(
      context: context,
      groups: [group],
      initialGroupId: groupId,
      allowGroupSelection: false,
      fixedGroupName: group.name,
      title: 'new_list'.tr(),
      actionLabel: 'add'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .createListWithOptions(
          groupId: groupId,
          name: result.name,
          populateFromGroupStudents: result.populateFromGroupStudents,
          sortField: ref.read(studentSortFieldProvider),
        );
  }

  Future<void> _deleteList(
    BuildContext context,
    WidgetRef ref,
    Checklist list,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete'.tr(namedArgs: {'name': list.name}),
      body: list.name,
    );
    if (confirmed) {
      await ref.read(listRepositoryProvider).deleteList(list.id);
    }
  }
}

class _ListsList extends StatelessWidget {
  const _ListsList({
    required this.listsValue,
    required this.groupsValue,
    required this.progress,
    required this.listPathBuilder,
    required this.onArchiveList,
    required this.onUnarchiveList,
    required this.onDeleteList,
    required this.onDeleteListDirect,
    this.archived = false,
  });

  final AsyncValue<List<Checklist>> listsValue;
  final AsyncValue<List<Group>> groupsValue;
  final Map<int, ListProgress> progress;
  final String Function(Checklist list) listPathBuilder;
  final ValueChanged<Checklist> onArchiveList;
  final ValueChanged<Checklist> onUnarchiveList;
  final ValueChanged<Checklist> onDeleteList;
  final ValueChanged<Checklist> onDeleteListDirect;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    return listsValue.when(
      data: (lists) {
        if (lists.isEmpty) {
          return EmptyState(
            icon: Icons.checklist_outlined,
            title: 'empty_lists'.tr(),
          );
        }

        final groups = {
          for (final group in groupsValue.value ?? const <Group>[])
            group.id: group,
        };

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: lists.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final list = lists[index];
            final groupId = list.groupId;
            final group = groupId != null ? groups[groupId] : null;
            final tile = Card(
              child: ListTile(
                onTap: () => context.push(listPathBuilder(list)),
                title: Text(
                  '${list.name} (${(progress[list.id]?.checked ?? 0)}/${(progress[list.id]?.total ?? 0)})',
                ),
                subtitle: group == null
                    ? const _GlobalListChip()
                    : _ListGroupChip(group: group),
                trailing: PopupMenuButton<_GlobalListAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _GlobalListAction.archive:
                        onArchiveList(list);
                        return;
                      case _GlobalListAction.unarchive:
                        onUnarchiveList(list);
                        return;
                      case _GlobalListAction.delete:
                        onDeleteList(list);
                        return;
                    }
                  },
                  itemBuilder: (_) => archived
                      ? [
                          PopupMenuItem(
                            value: _GlobalListAction.unarchive,
                            child: Text('unarchive'.tr()),
                          ),
                          PopupMenuItem(
                            value: _GlobalListAction.delete,
                            child: Text('delete'.tr()),
                          ),
                        ]
                      : [
                          PopupMenuItem(
                            value: _GlobalListAction.archive,
                            child: Text('archive'.tr()),
                          ),
                          PopupMenuItem(
                            value: _GlobalListAction.delete,
                            child: Text('delete'.tr()),
                          ),
                        ],
                ),
              ),
            );

            if (archived) {
              return tile;
            }

            return Dismissible(
              key: ValueKey('list-${list.id}'),
              direction: DismissDirection.horizontal,
              background: SwipeActionBackground(
                alignment: Alignment.centerLeft,
                icon: Icons.archive_outlined,
                label: 'archive'.tr(),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSecondaryContainer,
              ),
              secondaryBackground: SwipeActionBackground(
                alignment: Alignment.centerRight,
                icon: Icons.delete_outline,
                label: 'delete'.tr(),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              confirmDismiss: (direction) async {
                switch (direction) {
                  case DismissDirection.startToEnd:
                    return true;
                  case DismissDirection.endToStart:
                    return showConfirmDialog(
                      context: context,
                      title: 'confirm_delete'.tr(
                        namedArgs: {'name': list.name},
                      ),
                      body: list.name,
                    );
                  case DismissDirection.none:
                  case DismissDirection.down:
                  case DismissDirection.up:
                  case DismissDirection.horizontal:
                  case DismissDirection.vertical:
                    return false;
                }
              },
              onDismissed: (direction) {
                switch (direction) {
                  case DismissDirection.startToEnd:
                    onArchiveList(list);
                    return;
                  case DismissDirection.endToStart:
                    onDeleteListDirect(list);
                    return;
                  case DismissDirection.none:
                  case DismissDirection.down:
                  case DismissDirection.up:
                  case DismissDirection.horizontal:
                  case DismissDirection.vertical:
                    return;
                }
              },
              child: tile,
            );
          },
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

enum _GlobalListAction { archive, unarchive, delete }

class _GlobalListChip extends StatelessWidget {
  const _GlobalListChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: const Icon(Icons.public_outlined, size: 18),
        label: Text('global_list'.tr()),
      ),
    );
  }
}

class _ListGroupChip extends StatelessWidget {
  const _ListGroupChip({required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final groupColor = colorFromHex(group.colorHex);
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: groupColor, shape: BoxShape.circle),
        ),
        backgroundColor: groupColor.withValues(alpha: 0.16),
        side: BorderSide(color: groupColor.withValues(alpha: 0.4)),
        label: Text(group.name, style: TextStyle(color: groupColor)),
        onPressed: () => context.go('/groups/${group.id}'),
      ),
    );
  }
}
