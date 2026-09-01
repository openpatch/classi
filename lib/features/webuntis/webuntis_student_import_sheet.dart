import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/empty_state.dart';
import '../students/student_draft.dart';
import 'webuntis_api.dart';
import 'webuntis_models.dart';

/// Imports the students of a WebUntis class into [groupId].
///
/// Returns the import result, or `null` when the teacher backed out.
Future<WebUntisRosterImportResult?> showWebUntisStudentImportSheet({
  required BuildContext context,
  required int groupId,
  required int klasseId,
}) {
  return showModalBottomSheet<WebUntisRosterImportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) =>
        _WebUntisStudentImportSheet(groupId: groupId, klasseId: klasseId),
  );
}

class _WebUntisStudentImportSheet extends ConsumerStatefulWidget {
  const _WebUntisStudentImportSheet({
    required this.groupId,
    required this.klasseId,
  });

  final int groupId;
  final int klasseId;

  @override
  ConsumerState<_WebUntisStudentImportSheet> createState() =>
      _WebUntisStudentImportSheetState();
}

class _WebUntisStudentImportSheetState
    extends ConsumerState<_WebUntisStudentImportSheet> {
  final _selected = <int>{};

  bool _loading = true;
  bool _importing = false;
  String? _error;
  WebUntisRoster? _roster;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final roster = await ref
          .read(webUntisServiceProvider)
          .loadRoster(klasseId: widget.klasseId);
      if (!mounted) {
        return;
      }
      setState(() {
        _roster = roster;
        _selected
          ..clear()
          ..addAll(roster.students.map((student) => student.id));
        _loading = false;
      });
    } on WebUntisException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.translationKey.tr();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xxLarge,
        right: AppSpacing.xxLarge,
        top: AppSpacing.xxLarge,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xxLarge,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'webuntis_import_students'.tr(),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'webuntis_import_students_hint'.tr(),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.large),
            Expanded(child: _buildBody()),
            const SizedBox(height: AppSpacing.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _importing
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                const SizedBox(width: AppSpacing.medium),
                FilledButton(
                  onPressed: _selected.isEmpty || _importing ? null : _import,
                  child: _importing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'webuntis_import_selected'.tr(
                            namedArgs: {'count': _selected.length.toString()},
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error case final message?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.large),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr()),
            ),
          ],
        ),
      );
    }

    final roster = _roster;
    if (roster == null || roster.isEmpty) {
      return EmptyState(
        icon: Icons.person_search_outlined,
        // A class with no lessons in the searched window is a different
        // problem from a register the account may not open, and a teacher can
        // only act on the right one.
        title: (roster?.inspectedPeriods ?? 0) == 0
            ? 'webuntis_roster_no_lessons'.tr()
            : 'webuntis_roster_empty'.tr(),
        body: (roster?.inspectedPeriods ?? 0) == 0
            ? 'webuntis_roster_no_lessons_hint'.tr()
            : 'webuntis_roster_empty_hint'.tr(),
        action: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text('retry'.tr()),
        ),
      );
    }

    return ListView.builder(
      itemCount: roster.students.length,
      itemBuilder: (context, index) {
        final student = roster.students[index];
        return CheckboxListTile(
          value: _selected.contains(student.id),
          title: Text('${student.lastName}, ${student.firstName}'.trim()),
          onChanged: (checked) => setState(() {
            if (checked ?? false) {
              _selected.add(student.id);
            } else {
              _selected.remove(student.id);
            }
          }),
        );
      },
    );
  }

  Future<void> _import() async {
    final roster = _roster;
    if (roster == null) {
      return;
    }

    setState(() => _importing = true);

    try {
      final result = await ref
          .read(studentRepositoryProvider)
          .importWebUntisStudents(
            groupId: widget.groupId,
            students: [
              for (final student in roster.students)
                if (_selected.contains(student.id))
                  (
                    firstName: student.firstName,
                    lastName: student.lastName,
                    webuntisStudentId: student.id,
                  ),
            ],
          );

      await ref.read(webUntisServiceProvider).markSynced();

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }
}
