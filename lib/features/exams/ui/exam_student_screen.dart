import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../../../shared/utils/formatting.dart';
import '../../../shared/widgets/app_bar_title.dart';
import '../../../shared/widgets/content_constraints.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../groups/group_detail_screen.dart'
    show groupProvider, groupStudentsProvider;
import '../domain/exam_structure.dart';
import '../exam_providers.dart';
import 'exam_actions.dart';
import 'exam_format.dart';
import 'exam_screen.dart';

/// Points of one student, one expectation at a time: the way a stack of
/// exams is corrected. Works on phones and desktops alike.
class ExamStudentScreen extends ConsumerWidget {
  const ExamStudentScreen({
    required this.groupId,
    required this.examId,
    required this.studentId,
    super.key,
  });

  final int groupId;
  final int examId;
  final int studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(examSnapshotProvider(examId)).value;
    final group = ref.watch(groupProvider(groupId)).value;
    final students =
        ref.watch(groupStudentsProvider(groupId)).value ?? const <Student>[];
    final index = students.indexWhere((s) => s.id == studentId);
    if (snapshot == null || group == null || index < 0) {
      return Scaffold(
        appBar: AppBar(),
        body: snapshot == null || group == null
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.person_off_outlined,
                title: 'exam_student_missing'.tr(),
              ),
      );
    }
    final student = students[index];
    final row = StudentRow(student: student, snapshot: snapshot);
    final result = row.result;
    final scores = snapshot.scoresOf(student.id);
    final theme = Theme.of(context);
    final groups = groupByTask([
      for (final i in snapshot.items)
        if (i.id != null) i,
    ]);

    void goTo(int target) => context.replace(
      examStudentLocation(groupId, examId, students[target].id),
    );

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          title: studentName(student),
          subtitle: snapshot.exam.title,
        ),
        actions: [
          if (snapshot.exam.rubricSha256 != null)
            IconButton(
              tooltip: 'exam_rubric'.tr(),
              icon: const Icon(Icons.fact_check_outlined),
              onPressed: () => openExamDocument(
                context,
                ref,
                sha256: snapshot.exam.rubricSha256,
                title: 'exam_rubric'.tr(),
                subtitle: snapshot.exam.title,
              ),
            ),
          IconButton(
            tooltip: 'exam_participation'.tr(),
            icon: const Icon(Icons.how_to_reg_outlined),
            onPressed: () => showParticipantDialog(
              context,
              ref,
              snapshot: snapshot,
              student: student,
              scale: parseGradeScaleEntries(group.gradeScaleJson),
            ),
          ),
        ],
      ),
      body: ContentConstraints(
        child: ListView(
          padding: appScreenPadding,
          children: [
            if (!row.present || row.participant?.gradeOverride != null)
              Card(
                color: theme.colorScheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(iconForStatus(row.status)),
                  title: Text(labelForStatus(row.status)),
                  subtitle: row.participant?.overrideReason == null
                      ? null
                      : Text(row.participant!.overrideReason!),
                ),
              ),
            for (final group in groups) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  4,
                  AppSpacing.large,
                  4,
                  AppSpacing.small,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        taskHeading(group.items.first, snapshot.meta),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (result.tasks[group.taskKey] case final task?)
                      Text(
                        '${formatPoints(context, task.points)} / ${formatPoints(context, task.maxPoints)}'
                        '${task.counted ? '' : ' · ${'exam_not_counted'.tr()}'}',
                        style: theme.textTheme.titleSmall,
                      ),
                  ],
                ),
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, item) in group.items.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _ExpectationEntry(
                        // Rebuild the field when the stored value changes elsewhere.
                        key: ValueKey('${item.id}-${scores[item.id]}'),
                        item: item,
                        value: scores[item.id],
                        onChanged: (points) => ref
                            .read(examRepositoryProvider)
                            .setScore(
                              examId: examId,
                              expectationId: item.id!,
                              studentId: student.id,
                              points: points,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 96),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          elevation: 3,
          color: theme.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.small,
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'exam_previous_student'.tr(),
                  onPressed: index > 0 ? () => goTo(index - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${formatPoints(context, result.total)} / ${formatPoints(context, result.maxPoints)} · '
                        '${formatPercent(context, result.percent)} %',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        row.finalGrade != null
                            ? '${'grade'.tr()}: ${row.finalGrade}'
                            : 'exam_missing_count'.tr(
                                    namedArgs: {'count': '${result.missing}'},
                                  ) +
                                  (result.grade == null
                                      ? ''
                                      : ' · (${result.grade})'),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'exam_next_student'.tr(),
                  onPressed: index < students.length - 1
                      ? () => goTo(index + 1)
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpectationEntry extends StatefulWidget {
  const _ExpectationEntry({
    required this.item,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ExamItem item;
  final double? value;
  final Future<void> Function(double? points) onChanged;

  @override
  State<_ExpectationEntry> createState() => _ExpectationEntryState();
}

class _ExpectationEntryState extends State<_ExpectationEntry> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  bool _invalid = false;

  static const double _step = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commitText();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.text.isEmpty && widget.value != null) {
      _controller.text = formatPoints(context, widget.value!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _set(double? points) async {
    setState(() {
      _invalid = false;
      _controller.text = points == null ? '' : formatPoints(context, points);
    });
    if (points != widget.value) await widget.onChanged(points);
  }

  Future<void> _commitText() async {
    final text = _controller.text;
    final value = parsePoints(text);
    final valid =
        text.trim().isEmpty ||
        (value != null && value >= 0 && value <= widget.item.maxPoints + 1e-9);
    if (!valid) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    if (value != widget.value) await widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final alternative = item.kind == ExpectationKind.alternative;
    final value = widget.value;
    final max = item.maxPoints;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.large,
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.part != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.small),
                  child: Text(
                    '${item.part})',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              Expanded(
                child: Text(
                  item.description.isEmpty ? '–' : item.description,
                  style: alternative
                      ? theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        )
                      : null,
                ),
              ),
              if (item.label != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.small),
                  child: Text(item.label!, style: theme.textTheme.labelSmall),
                ),
            ],
          ),
          if (!alternative) ...[
            const SizedBox(height: AppSpacing.small),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xSmall,
              children: [
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  tooltip: '−$_step',
                  onPressed: value == null || value <= 0
                      ? null
                      : () => _set((value - _step).clamp(0, max).toDouble()),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onSubmitted: (_) => _commitText(),
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      errorText: _invalid ? '' : null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                    ),
                  ),
                ),
                IconButton.outlined(
                  visualDensity: VisualDensity.compact,
                  tooltip: '+$_step',
                  onPressed: value != null && value >= max
                      ? null
                      : () => _set(
                          ((value ?? 0) + _step).clamp(0, max).toDouble(),
                        ),
                  icon: const Icon(Icons.add),
                ),
                Text(
                  ' / ${formatPoints(context, max)}',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(width: AppSpacing.small),
                ActionChip(label: const Text('0'), onPressed: () => _set(0)),
                ActionChip(
                  label: Text(formatPoints(context, max)),
                  onPressed: () => _set(max),
                ),
                if (value != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'exam_clear_points'.tr(),
                    onPressed: () => _set(null),
                    icon: const Icon(Icons.backspace_outlined, size: 18),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
