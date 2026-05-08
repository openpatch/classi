import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'seating_plan_form.dart';

/// Shows a modal bottom sheet that lists all seating plans for [groupId].
///
/// The currently active plan is indicated. The user can select a plan, create
/// a new one, rename one, or delete one.
///
/// Returns the selected [SeatingPlan], or `null` if cancelled.
Future<SeatingPlan?> showSeatingPlanSelectorSheet({
  required BuildContext context,
  required int groupId,
  SeatingPlan? activePlan,
}) {
  return showModalBottomSheet<SeatingPlan>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SeatingPlanSelectorSheet(
      groupId: groupId,
      activePlan: activePlan,
    ),
  );
}

class _SeatingPlanSelectorSheet extends ConsumerWidget {
  const _SeatingPlanSelectorSheet({
    required this.groupId,
    this.activePlan,
  });

  final int groupId;
  final SeatingPlan? activePlan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansValue = ref.watch(groupSeatingPlansProvider(groupId));

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'seating_plans'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _createPlan(context, ref),
                icon: const Icon(Icons.add),
                label: Text('add_seating_plan'.tr()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          plansValue.when(
            data: (plans) {
              if (plans.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.large,
                  ),
                  child: Text(
                    'empty_seating_plans'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final plan in plans)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.grid_view_outlined),
                      title: Text(plan.name),
                      selected: plan.id == activePlan?.id,
                      selectedColor:
                          Theme.of(context).colorScheme.primary,
                      onTap: () => Navigator.of(context).pop(plan),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              plan.isDefault
                                  ? Icons.star
                                  : Icons.star_border,
                              color: plan.isDefault
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            tooltip: 'set_as_default'.tr(),
                            visualDensity: VisualDensity.compact,
                            onPressed: plan.isDefault
                                ? null
                                : () => ref
                                      .read(seatingPlanRepositoryProvider)
                                      .setDefaultPlan(groupId, plan.id),
                          ),
                          _PlanActions(
                            plan: plan,
                            onRename: () => _renamePlan(context, ref, plan),
                            onDelete: () => _deletePlan(context, ref, plan),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
            error: (_, _) => const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Future<void> _createPlan(BuildContext context, WidgetRef ref) async {
    final result = await showSeatingPlanForm(context: context);
    if (result == null || !context.mounted) return;

    final repo = ref.read(seatingPlanRepositoryProvider);
    final id = await repo.createPlan(
      groupId: groupId,
      name: result.name,
      columns: result.columns,
    );

    // Automatically select the newly created plan and close the sheet.
    final plans = await repo.watchPlansForGroup(groupId).first;
    final created = plans.where((p) => p.id == id).firstOrNull;
    if (created != null && context.mounted) {
      Navigator.of(context).pop(created);
    }
  }

  Future<void> _renamePlan(
    BuildContext context,
    WidgetRef ref,
    SeatingPlan plan,
  ) async {
    final result = await showSeatingPlanForm(
      context: context,
      initialName: plan.name,
      initialColumns: plan.columns,
    );
    if (result == null) return;
    await ref
        .read(seatingPlanRepositoryProvider)
        .updatePlan(plan.id, name: result.name, columns: result.columns);
  }

  Future<void> _deletePlan(
    BuildContext context,
    WidgetRef ref,
    SeatingPlan plan,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete'.tr(namedArgs: {'name': plan.name}),
      body: 'confirm_delete_seating_plan_body'.tr(),
    );
    if (!confirmed) return;

    await ref.read(seatingPlanRepositoryProvider).deletePlan(plan.id);

    // If the deleted plan was active, close the sheet with no selection.
    if (activePlan?.id == plan.id && context.mounted) {
      Navigator.of(context).pop(null);
    }
  }
}

class _PlanActions extends StatelessWidget {
  const _PlanActions({
    required this.plan,
    required this.onRename,
    required this.onDelete,
  });

  final SeatingPlan plan;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: onRename,
          child: Text('rename_seating_plan'.tr()),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: onDelete,
          child: Text(
            'delete'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
      builder: (_, controller, _) => IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: controller.isOpen ? controller.close : controller.open,
        tooltip: 'edit'.tr(),
      ),
    );
  }
}
