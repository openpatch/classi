import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/widgets/student_avatar.dart';
import 'grade_distribution.dart';

/// What typing [typed] means on a grade scale with [labels].
///
/// [match] is the grade typed so far, if any. [complete] says no longer
/// grade starts with it, so it can be taken at once: on a 15–0 point scale
/// "1" could still become "10"–"15", while "7" is final.
typedef GradeInputMatch = ({String? match, bool complete, bool viable});

GradeInputMatch matchGradeInput(String typed, List<String> labels) {
  final needle = typed.trim().toLowerCase();
  if (needle.isEmpty) {
    return (match: null, complete: false, viable: true);
  }
  String? match;
  var longer = false;
  for (final label in labels) {
    final candidate = label.trim().toLowerCase();
    if (candidate == needle) {
      match = label;
    } else if (candidate.startsWith(needle)) {
      longer = true;
    }
  }
  return (
    match: match,
    complete: match != null && !longer,
    viable: match != null || longer,
  );
}

/// Grades a whole group one student after the other: pick a grade, and the
/// next student comes up. The quick way to enter a test or an oral round.
///
/// Saves through [onSave] and [onClear] as it goes, so leaving early keeps
/// what was entered.
class GradeRoundScreen extends ConsumerStatefulWidget {
  const GradeRoundScreen({
    required this.title,
    required this.students,
    required this.absentStudentIds,
    required this.initialSelections,
    required this.gradeScale,
    required this.onSave,
    required this.onClear,
    this.color,
    super.key,
  });

  final String title;
  final List<Student> students;
  final Set<int> absentStudentIds;
  final Map<int, String> initialSelections;
  final List<GradeScaleEntry> gradeScale;
  final Future<void> Function(int studentId, String value) onSave;
  final Future<void> Function(int studentId) onClear;
  final Color? color;

  @override
  ConsumerState<GradeRoundScreen> createState() => _GradeRoundScreenState();
}

class _GradeRoundScreenState extends ConsumerState<GradeRoundScreen> {
  static const _typingPause = Duration(milliseconds: 700);

  late final Map<int, String> _selections = {...widget.initialSelections};
  final _focusNode = FocusNode();
  bool _skipAbsent = true;
  bool _finished = false;
  int _index = 0;
  String _typed = '';
  Timer? _typingTimer;

  List<Student> get _roster => [
    for (final student in widget.students)
      if (!_skipAbsent || !widget.absentStudentIds.contains(student.id))
        student,
  ];

  @override
  void initState() {
    super.initState();
    final roster = _roster;
    final firstOpen = roster.indexWhere(
      (student) => !_selections.containsKey(student.id),
    );
    _index = firstOpen < 0 ? 0 : firstOpen;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roster = _roster;
    final labels = [for (final entry in widget.gradeScale) entry.label];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_finished && roster.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _finished = true),
              child: Text('grade_round_finish'.tr()),
            ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (_, event) => _handleKey(event, roster, labels),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: roster.isEmpty
                  ? _buildEmpty(context)
                  : _finished
                  ? _buildSummary(context, roster)
                  : _buildStudent(context, roster, labels),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: appScreenPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'grade_round_nobody'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.large),
          _skipAbsentToggle(),
        ],
      ),
    );
  }

  Widget _buildStudent(
    BuildContext context,
    List<Student> roster,
    List<String> labels,
  ) {
    final theme = Theme.of(context);
    final index = _index.clamp(0, roster.length - 1);
    final student = roster[index];
    final current = _selections[student.id];
    final absent = widget.absentStudentIds.contains(student.id);
    final sortField = ref.watch(studentSortFieldProvider);
    final gradedCount = roster
        .where((student) => _selections.containsKey(student.id))
        .length;

    return ListView(
      padding: appScreenPadding,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'grade_round_progress'.tr(
                  namedArgs: {
                    'current': '${index + 1}',
                    'total': '${roster.length}',
                    'graded': '$gradedCount',
                  },
                ),
                style: theme.textTheme.labelLarge,
              ),
            ),
            _skipAbsentToggle(),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        LinearProgressIndicator(
          value: roster.isEmpty ? 0 : gradedCount / roster.length,
          color: widget.color,
        ),
        const SizedBox(height: AppSpacing.xxLarge),
        Center(child: StudentAvatar(student: student, size: 96)),
        const SizedBox(height: AppSpacing.medium),
        Text(
          studentDisplayName(
            firstName: student.firstName,
            lastName: student.lastName,
            callName: student.callName,
            sortField: sortField,
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        if (absent) ...[
          const SizedBox(height: AppSpacing.small),
          Center(
            child: Chip(
              avatar: const Icon(Icons.person_off_outlined, size: 18),
              label: Text('absent'.tr()),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxLarge),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final label in labels)
              SizedBox(
                width: 72,
                height: 56,
                child: label == current
                    ? FilledButton(
                        onPressed: () => _grade(roster, student, label),
                        style: FilledButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: widget.color == null
                              ? null
                              : onColorForBackground(widget.color!),
                        ),
                        child: Text(label),
                      )
                    : FilledButton.tonal(
                        onPressed: () => _grade(roster, student, label),
                        child: Text(label),
                      ),
              ),
          ],
        ),
        if (_typed.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.small),
          Text(
            _typed,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xxLarge),
        Row(
          children: [
            IconButton.outlined(
              onPressed: index > 0 ? () => _move(roster, -1) : null,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'grade_round_previous'.tr(),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: current == null ? null : () => _clear(student),
              icon: const Icon(Icons.backspace_outlined),
              label: Text('reset'.tr()),
            ),
            const Spacer(),
            IconButton.outlined(
              onPressed: () => _move(roster, 1),
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'grade_round_skip'.tr(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'grade_round_keyboard_hint'.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, List<Student> roster) {
    final sortField = ref.watch(studentSortFieldProvider);
    final missing = [
      for (final student in roster)
        if (!_selections.containsKey(student.id)) student,
    ];

    return ListView(
      padding: appScreenPadding,
      children: [
        GradeDistributionCard(
          title: 'grade_distribution'.tr(),
          values: [
            for (final student in widget.students) ?_selections[student.id],
          ],
          gradeScale: widget.gradeScale,
          color: widget.color,
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.large),
          Text(
            'grade_round_missing'.tr(namedArgs: {'count': '${missing.length}'}),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (final student in missing)
                ActionChip(
                  label: Text(
                    studentDisplayName(
                      firstName: student.firstName,
                      lastName: student.lastName,
                      callName: student.callName,
                      sortField: sortField,
                    ),
                  ),
                  onPressed: () => setState(() {
                    _finished = false;
                    _index = roster.indexOf(student);
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxLarge),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('done'.tr()),
        ),
      ],
    );
  }

  Widget _skipAbsentToggle() {
    return FilterChip(
      label: Text('grade_round_skip_absent'.tr()),
      selected: _skipAbsent,
      onSelected: (value) => setState(() {
        final current = _currentStudent(_roster);
        _skipAbsent = value;
        final roster = _roster;
        final position = current == null ? -1 : roster.indexOf(current);
        _index = position < 0 ? 0 : position;
      }),
    );
  }

  Student? _currentStudent(List<Student> roster) =>
      roster.isEmpty ? null : roster[_index.clamp(0, roster.length - 1)];

  Future<void> _grade(
    List<Student> roster,
    Student student,
    String value,
  ) async {
    setState(() {
      _selections[student.id] = value;
      _typed = '';
    });
    _move(roster, 1);
    await widget.onSave(student.id, value);
  }

  Future<void> _clear(Student student) async {
    setState(() => _selections.remove(student.id));
    await widget.onClear(student.id);
  }

  void _move(List<Student> roster, int step) {
    _typingTimer?.cancel();
    final next = _index + step;
    setState(() {
      _typed = '';
      if (next >= roster.length) {
        _finished = true;
      } else {
        _index = next < 0 ? 0 : next;
      }
    });
  }

  KeyEventResult _handleKey(
    KeyEvent event,
    List<Student> roster,
    List<String> labels,
  ) {
    if (event is! KeyDownEvent || _finished || roster.isEmpty) {
      return KeyEventResult.ignored;
    }
    final student = _currentStudent(roster)!;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (!_commitTyped(roster, labels)) {
        _move(roster, 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _move(roster, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      if (_typed.isNotEmpty) {
        setState(() => _typed = _typed.substring(0, _typed.length - 1));
      } else {
        _clear(student);
      }
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (character == null || character.trim().isEmpty) {
      return KeyEventResult.ignored;
    }
    final typed = _typed + character;
    final result = matchGradeInput(typed, labels);
    if (!result.viable) {
      // Start over with just this key, so a typo does not block the next
      // grade.
      final restart = matchGradeInput(character, labels);
      if (!restart.viable) {
        setState(() => _typed = '');
        return KeyEventResult.handled;
      }
      return _accept(character, restart, roster, student);
    }
    return _accept(typed, result, roster, student);
  }

  KeyEventResult _accept(
    String typed,
    GradeInputMatch result,
    List<Student> roster,
    Student student,
  ) {
    _typingTimer?.cancel();
    if (result.complete) {
      _grade(roster, student, result.match!);
      return KeyEventResult.handled;
    }
    setState(() => _typed = typed);
    if (result.match != null) {
      _typingTimer = Timer(_typingPause, () {
        if (mounted) {
          _commitTyped(_roster, [
            for (final entry in widget.gradeScale) entry.label,
          ]);
        }
      });
    }
    return KeyEventResult.handled;
  }

  /// Takes the grade typed so far, if it is one. Returns whether it was.
  bool _commitTyped(List<Student> roster, List<String> labels) {
    _typingTimer?.cancel();
    final match = matchGradeInput(_typed, labels).match;
    if (match == null || roster.isEmpty) {
      return false;
    }
    _grade(roster, _currentStudent(roster)!, match);
    return true;
  }
}
