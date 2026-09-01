import 'dart:developer' as developer;

import 'package:drift/drift.dart' show Value;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/empty_state.dart';
import '../webuntis/webuntis_class_import_sheet.dart';
import 'group_form.dart';

final activeGroupsProvider = StreamProvider.autoDispose<List<Group>>(
  (ref) => ref
      .watch(groupRepositoryProvider)
      .watchActiveGroups(schoolYearId: ref.watch(activeSchoolYearIdProvider)),
);

final archivedGroupsProvider = StreamProvider.autoDispose<List<Group>>(
  (ref) => ref
      .watch(groupRepositoryProvider)
      .watchArchivedGroups(schoolYearId: ref.watch(activeSchoolYearIdProvider)),
);

final groupStudentCountsProvider = StreamProvider.autoDispose<Map<int, int>>(
  (ref) => ref.watch(studentRepositoryProvider).watchGroupStudentCounts(),
);

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final newIndex = _tabController.index;
      if (newIndex != _tabIndex) {
        setState(() => _tabIndex = newIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('groups'.tr()),
        actions: [
          // Only offered once a WebUntis account is connected: without one the
          // action can do nothing but explain itself.
          if (ref.watch(webUntisConnectionProvider).value != null)
            IconButton(
              onPressed: _importFromWebUntis,
              icon: const Icon(Icons.cloud_download_outlined),
              tooltip: 'webuntis_import_classes'.tr(),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'active'.tr()),
            Tab(text: 'archived'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GroupsList(
            provider: activeGroupsProvider,
            emptyKey: 'empty_groups',
            archived: false,
          ),
          _GroupsList(
            provider: archivedGroupsProvider,
            emptyKey: 'empty_archived_groups',
            archived: true,
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _addGroup,
              icon: const Icon(Icons.add),
              label: Text('add_group'.tr()),
            )
          : null,
    );
  }

  Future<void> _importFromWebUntis() async {
    final created = await showWebUntisClassImportSheet(context: context);
    if (created == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'webuntis_classes_imported'.tr(
            namedArgs: {'count': created.toString()},
          ),
        ),
      ),
    );
  }

  Future<void> _addGroup() async {
    final gradeSystems = ref.read(gradeSystemControllerProvider).systems;
    if (gradeSystems.isEmpty) {
      return;
    }

    final schoolYearRepository = ref.read(schoolYearRepositoryProvider);
    final schoolYears = await schoolYearRepository.allSchoolYears();
    final currentSchoolYear = await schoolYearRepository.currentSchoolYear();
    if (!mounted) {
      return;
    }

    final result = await showGroupFormSheet(
      context: context,
      gradeSystems: gradeSystems,
      schoolYears: schoolYears,
      initialSchoolYearId: currentSchoolYear?.id,
    );
    if (result == null) {
      return;
    }

    try {
      await ref
          .read(groupRepositoryProvider)
          .createGroup(
            name: result.name,
            colorHex: result.colorHex,
            gradeScale: result.gradeScale,
            gradeCategories: result.gradeCategories,
            schoolYearId: result.schoolYearId,
          );
    } catch (e, st) {
      developer.log(
        'Failed to create group',
        name: 'classi.groups',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
    }
  }
}

class _GroupsList extends ConsumerWidget {
  const _GroupsList({
    required this.provider,
    required this.emptyKey,
    required this.archived,
  });

  final StreamProvider<List<Group>> provider;
  final String emptyKey;
  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsValue = ref.watch(provider);
    final studentCountsValue = ref.watch(groupStudentCountsProvider);

    return ContentConstraints(
      child: groupsValue.when(
        data: (groups) {
          if (groups.isEmpty) {
            return EmptyState(
              icon: archived ? Icons.archive_outlined : Icons.groups_outlined,
              title: emptyKey.tr(),
            );
          }
          final studentCounts = studentCountsValue.value ?? const <int, int>{};
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              mainAxisExtent: 76,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final groupColor = colorFromHex(group.colorHex);
              final studentCount = studentCounts[group.id] ?? 0;
              return Card(
                child: ListTile(
                  onTap: () => context.go('/groups/${group.id}'),
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: groupColor.withValues(alpha: 0.18),
                    child: CircleAvatar(radius: 5, backgroundColor: groupColor),
                  ),
                  title: Text('${group.name} ($studentCount)'),
                  trailing: PopupMenuButton<_GroupAction>(
                    onSelected: (action) => _handleAction(
                      context: context,
                      ref: ref,
                      group: group,
                      action: action,
                    ),
                    itemBuilder: (context) => [
                      if (!archived)
                        PopupMenuItem(
                          value: _GroupAction.edit,
                          child: Text('edit'.tr()),
                        ),
                      if (!archived)
                        PopupMenuItem(
                          value: _GroupAction.clone,
                          child: Text('clone_group'.tr()),
                        ),
                      PopupMenuItem(
                        value: archived
                            ? _GroupAction.unarchive
                            : _GroupAction.archive,
                        child: Text(
                          archived
                              ? 'unarchive_group'.tr()
                              : 'archive_group'.tr(),
                        ),
                      ),
                      PopupMenuItem(
                        value: _GroupAction.delete,
                        child: Text('delete'.tr()),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        error: (error, _) => const AppErrorState(),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _handleAction({
    required BuildContext context,
    required WidgetRef ref,
    required Group group,
    required _GroupAction action,
  }) async {
    final repository = ref.read(groupRepositoryProvider);

    switch (action) {
      case _GroupAction.edit:
        final systemsForEdit = ref.read(gradeSystemControllerProvider).systems;
        if (systemsForEdit.isEmpty) {
          return;
        }
        final schoolYearsForEdit = await ref
            .read(schoolYearRepositoryProvider)
            .allSchoolYears();
        if (!context.mounted) {
          return;
        }
        final result = await showGroupFormSheet(
          context: context,
          gradeSystems: systemsForEdit,
          schoolYears: schoolYearsForEdit,
          initialSchoolYearId: group.schoolYearId,
          initialName: group.name,
          initialGroupColorHex: group.colorHex,
          initialGradeScale: parseGradeScaleEntries(group.gradeScaleJson),
          initialGradeCategories: parseGradeCategories(
            group.gradeCategoriesJson,
          ),
          title: 'edit'.tr(),
        );
        if (result != null) {
          try {
            await repository.updateGroup(
              id: group.id,
              name: result.name,
              colorHex: result.colorHex,
              gradeScale: result.gradeScale,
              gradeCategories: result.gradeCategories,
              schoolYearId: Value(result.schoolYearId),
            );
          } catch (e, st) {
            developer.log(
              'Failed to update group',
              name: 'classi.groups',
              level: 1000,
              error: e,
              stackTrace: st,
            );
            if (context.mounted) {
              showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
            }
          }
        }
        return;
      case _GroupAction.clone:
        final systemsForClone = ref.read(gradeSystemControllerProvider).systems;
        if (systemsForClone.isEmpty) {
          return;
        }
        final schoolYearsForClone = await ref
            .read(schoolYearRepositoryProvider)
            .allSchoolYears();
        if (!context.mounted) {
          return;
        }
        final result = await showGroupFormSheet(
          context: context,
          gradeSystems: systemsForClone,
          schoolYears: schoolYearsForClone,
          initialSchoolYearId: group.schoolYearId,
          initialName: '${group.name} Copy',
          initialGroupColorHex: group.colorHex,
          initialGradeScale: parseGradeScaleEntries(group.gradeScaleJson),
          initialGradeCategories: parseGradeCategories(
            group.gradeCategoriesJson,
          ),
          title: 'clone_group'.tr(),
        );
        if (result != null) {
          try {
            await repository.cloneGroup(
              sourceGroupId: group.id,
              newName: result.name,
              colorHex: result.colorHex,
              gradeScale: result.gradeScale,
              gradeCategories: result.gradeCategories,
              schoolYearId: Value(result.schoolYearId),
            );
          } catch (e, st) {
            developer.log(
              'Failed to clone group',
              name: 'classi.groups',
              level: 1000,
              error: e,
              stackTrace: st,
            );
            if (context.mounted) {
              showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
            }
          }
        }
        return;
      case _GroupAction.archive:
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'confirm_archive_group'.tr(namedArgs: {'name': group.name}),
          body: 'confirm_archive_group_body'.tr(),
          confirmKey: 'archive_group',
        );
        if (confirmed) {
          try {
            await repository.archiveGroup(group.id);
          } catch (e, st) {
            developer.log(
              'Failed to archive group',
              name: 'classi.groups',
              level: 1000,
              error: e,
              stackTrace: st,
            );
            if (context.mounted) {
              showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
            }
          }
        }
        return;
      case _GroupAction.unarchive:
        try {
          await repository.unarchiveGroup(group.id);
        } catch (e, st) {
          developer.log(
            'Failed to unarchive group',
            name: 'classi.groups',
            level: 1000,
            error: e,
            stackTrace: st,
          );
          if (context.mounted) {
            showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
          }
        }
        return;
      case _GroupAction.delete:
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'confirm_delete'.tr(namedArgs: {'name': group.name}),
          body: 'confirm_delete_group_body'.tr(),
        );
        if (confirmed) {
          try {
            await repository.deleteGroup(group.id);
          } catch (e, st) {
            developer.log(
              'Failed to delete group',
              name: 'classi.groups',
              level: 1000,
              error: e,
              stackTrace: st,
            );
            if (context.mounted) {
              showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
            }
          }
        }
        return;
    }
  }
}

enum _GroupAction { edit, clone, archive, unarchive, delete }
