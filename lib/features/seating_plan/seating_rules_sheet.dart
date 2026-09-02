import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'seating_fit.dart';

/// Shows the seating rules of [groupId]: the pairs of students that belong
/// together and the pairs that have to be kept apart.
///
/// Rules are written straight through to the database, so the sheet returns
/// nothing.
Future<void> showSeatingRulesSheet({
  required BuildContext context,
  required int groupId,
  required List<Student> students,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SeatingRulesSheet(groupId: groupId, students: students),
  );
}

class _SeatingRulesSheet extends ConsumerWidget {
  const _SeatingRulesSheet({required this.groupId, required this.students});

  final int groupId;
  final List<Student> students;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationsValue = ref.watch(groupStudentRelationsProvider(groupId));
    final sortField = ref.watch(studentSortFieldProvider);
    final nameById = {
      for (final student in students)
        student.id: studentDisplayName(
          firstName: student.firstName,
          lastName: student.lastName,
          callName: student.callName,
          sortField: sortField,
        ),
    };

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
                  'seating_rules'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: students.length < 2
                    ? null
                    : () => _editRule(context, ref),
                icon: const Icon(Icons.add),
                label: Text('add_seating_rule'.tr()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'seating_rules_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Flexible(
            child: relationsValue.when(
              data: (relations) {
                if (relations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.large,
                    ),
                    child: Text(
                      'empty_seating_rules'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  );
                }

                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final relation in relations)
                      _RuleTile(
                        relation: relation,
                        nameById: nameById,
                        onEdit: () => _editRule(context, ref, relation),
                        onDelete: () => _deleteRule(context, ref, relation),
                      ),
                  ],
                );
              },
              error: (_, _) => const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editRule(
    BuildContext context,
    WidgetRef ref, [
    StudentRelation? relation,
  ]) async {
    final result = await showSeatingRuleForm(
      context: context,
      students: students,
      relation: relation,
    );
    if (result == null) return;

    final repository = ref.read(studentRelationRepositoryProvider);
    // Editing a rule can repoint it at a different pair, which is a different
    // row: drop the old one so the pair is not left behind as a duplicate.
    if (relation != null &&
        (relation.studentAId != result.studentAId ||
            relation.studentBId != result.studentBId)) {
      await repository.deleteRelation(relation.id);
    }
    await repository.upsertRelation(
      studentAId: result.studentAId,
      studentBId: result.studentBId,
      isPositive: result.isPositive,
      comment: result.comment,
    );
  }

  Future<void> _deleteRule(
    BuildContext context,
    WidgetRef ref,
    StudentRelation relation,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete_seating_rule'.tr(),
      body: 'confirm_delete_seating_rule_body'.tr(),
    );
    if (!confirmed) return;
    await ref
        .read(studentRelationRepositoryProvider)
        .deleteRelation(relation.id);
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.relation,
    required this.nameById,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentRelation relation;
  final Map<int, String> nameById;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unknown = 'unknown_student'.tr();
    final color = seatingFitColor(context, relation.isPositive ? 1 : -1);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        child: Icon(
          relation.isPositive ? Icons.handshake_outlined : Icons.block,
          size: 20,
        ),
      ),
      title: Text(
        '${nameById[relation.studentAId] ?? unknown} · '
        '${nameById[relation.studentBId] ?? unknown}',
      ),
      subtitle: Text(
        relation.comment ??
            (relation.isPositive ? 'sit_together'.tr() : 'keep_apart'.tr()),
      ),
      onTap: onEdit,
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        tooltip: 'delete'.tr(),
        onPressed: onDelete,
      ),
    );
  }
}

/// The result of the seating rule form.
typedef SeatingRuleFormResult = ({
  int studentAId,
  int studentBId,
  bool isPositive,
  String? comment,
});

/// Shows a modal bottom sheet for creating or editing a single seating rule.
///
/// Returns the rule to write, or `null` if the user cancelled.
Future<SeatingRuleFormResult?> showSeatingRuleForm({
  required BuildContext context,
  required List<Student> students,
  StudentRelation? relation,
}) {
  return showModalBottomSheet<SeatingRuleFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _SeatingRuleFormSheet(students: students, relation: relation),
  );
}

class _SeatingRuleFormSheet extends ConsumerStatefulWidget {
  const _SeatingRuleFormSheet({required this.students, this.relation});

  final List<Student> students;
  final StudentRelation? relation;

  @override
  ConsumerState<_SeatingRuleFormSheet> createState() =>
      _SeatingRuleFormSheetState();
}

class _SeatingRuleFormSheetState extends ConsumerState<_SeatingRuleFormSheet> {
  late final TextEditingController _commentController;
  int? _studentAId;
  int? _studentBId;
  late bool _isPositive;

  @override
  void initState() {
    super.initState();
    final relation = widget.relation;
    _commentController = TextEditingController(text: relation?.comment);
    _studentAId = relation?.studentAId;
    _studentBId = relation?.studentBId;
    _isPositive = relation?.isPositive ?? true;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _studentAId != null && _studentBId != null && _studentAId != _studentBId;

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop((
      studentAId: _studentAId!,
      studentBId: _studentBId!,
      isPositive: _isPositive,
      comment: _commentController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final entries = [
      for (final student in widget.students)
        (
          id: student.id,
          name: studentDisplayName(
            firstName: student.firstName,
            lastName: student.lastName,
            callName: student.callName,
            sortField: sortField,
          ),
        ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xLarge,
        AppSpacing.small,
        AppSpacing.xLarge,
        AppSpacing.xxLarge + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.relation == null
                  ? 'add_seating_rule'.tr()
                  : 'edit_seating_rule'.tr(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.large),
            _StudentDropdown(
              label: 'first_student'.tr(),
              value: _studentAId,
              entries: entries,
              excludedId: _studentBId,
              onChanged: (value) => setState(() => _studentAId = value),
            ),
            const SizedBox(height: AppSpacing.medium),
            _StudentDropdown(
              label: 'second_student'.tr(),
              value: _studentBId,
              entries: entries,
              excludedId: _studentAId,
              onChanged: (value) => setState(() => _studentBId = value),
            ),
            const SizedBox(height: AppSpacing.large),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.handshake_outlined),
                  label: Text('sit_together'.tr()),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.block),
                  label: Text('keep_apart'.tr()),
                ),
              ],
              selected: {_isPositive},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _isPositive = selection.first),
            ),
            const SizedBox(height: AppSpacing.large),
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'seating_rule_comment'.tr(),
                border: const OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text('save'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDropdown extends StatelessWidget {
  const _StudentDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.excludedId,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<({int id, String name})> entries;

  /// The student already picked in the other field, which cannot be picked
  /// here as well.
  final int? excludedId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final entry in entries)
          if (entry.id != excludedId)
            DropdownMenuItem(
              value: entry.id,
              child: Text(entry.name, overflow: TextOverflow.ellipsis),
            ),
      ],
      onChanged: onChanged,
    );
  }
}
