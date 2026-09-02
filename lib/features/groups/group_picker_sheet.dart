import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../shared/theme/app_ui.dart';
import 'groups_screen.dart' show activeGroupsProvider;

/// Asks which group to work with, leaving [excludeGroupId] out of the list.
///
/// Used wherever one group borrows from another — the same class taught in a
/// second subject is a group of its own, and its students and seating plans
/// have to come from somewhere.
///
/// Returns the chosen group, or `null` if the sheet was dismissed.
Future<Group?> showGroupPickerSheet({
  required BuildContext context,
  required int excludeGroupId,
  required String title,
}) {
  return showModalBottomSheet<Group>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _GroupPickerSheet(
      excludeGroupId: excludeGroupId,
      title: title,
    ),
  );
}

class _GroupPickerSheet extends ConsumerWidget {
  const _GroupPickerSheet({required this.excludeGroupId, required this.title});

  final int excludeGroupId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsValue = ref.watch(activeGroupsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.small,
        AppSpacing.xLarge,
        AppSpacing.xxLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          groupsValue.when(
            data: (groups) {
              final others = groups
                  .where((group) => group.id != excludeGroupId)
                  .toList();
              if (others.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.large,
                  ),
                  child: Text(
                    'no_other_groups'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                );
              }

              return Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final group in others)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.groups_outlined),
                        title: Text(group.name),
                        onTap: () => Navigator.of(context).pop(group),
                      ),
                  ],
                ),
              );
            },
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
