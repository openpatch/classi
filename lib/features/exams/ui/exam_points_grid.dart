import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../data/exam_repository.dart';
import '../domain/exam_structure.dart';
import '../exam_providers.dart';
import 'exam_format.dart';

const double _nameWidth = 200;
const double _cellWidth = 64;
const double _rowHeight = 44;
const double _headerHeight = 60;
const double _totalWidth = 96;
const double _gradeWidth = 64;

/// Keyboard-driven point entry for wide screens: one row per student, one
/// column per expectation. Enter and Tab move right (wrapping to the next
/// student), the up and down arrows move between students. A value is saved
/// when the field is left.
class ExamPointsGrid extends ConsumerStatefulWidget {
  const ExamPointsGrid({
    required this.snapshot,
    required this.students,
    super.key,
  });

  final ExamSnapshot snapshot;
  final List<Student> students;

  @override
  ConsumerState<ExamPointsGrid> createState() => _ExamPointsGridState();
}

class _ExamPointsGridState extends ConsumerState<ExamPointsGrid> {
  final _header = ScrollController();
  final _body = ScrollController();
  final _controllers = <(int, int), TextEditingController>{};
  final _focus = <(int, int), FocusNode>{};
  final _invalid = <(int, int)>{};

  List<ExamItem> get _items => [
    for (final item in widget.snapshot.items)
      if (item.kind.isScored && item.id != null) item,
  ];

  @override
  void initState() {
    super.initState();
    _body.addListener(() {
      if (_header.hasClients) _header.jumpTo(_body.offset);
    });
  }

  @override
  void dispose() {
    _header.dispose();
    _body.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  String _stored(int studentId, int itemId) {
    final value = widget.snapshot.scoresOf(studentId)[itemId];
    return value == null ? '' : formatPoints(context, value);
  }

  TextEditingController _controller(int studentId, int itemId) {
    return _controllers.putIfAbsent((
      studentId,
      itemId,
    ), () => TextEditingController(text: _stored(studentId, itemId)));
  }

  @override
  void didUpdateWidget(covariant ExamPointsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow changes made elsewhere (another device, the per-student
    // screen), but never overwrite what is being typed or a rejected value.
    for (final entry in _controllers.entries) {
      final key = entry.key;
      if ((_focus[key]?.hasFocus ?? false) || _invalid.contains(key)) continue;
      final stored = _stored(key.$1, key.$2);
      if (parsePoints(entry.value.text) != parsePoints(stored)) {
        entry.value.text = stored;
      }
    }
  }

  FocusNode _node(int studentId, int itemId, ExamItem item) {
    return _focus.putIfAbsent((studentId, itemId), () {
      final node = FocusNode();
      node.addListener(() {
        if (!node.hasFocus) _commit(studentId, item);
      });
      return node;
    });
  }

  Future<void> _commit(int studentId, ExamItem item) async {
    final key = (studentId, item.id!);
    final text = _controllers[key]?.text ?? '';
    final value = parsePoints(text);
    final valid =
        text.trim().isEmpty ||
        (value != null && value >= 0 && value <= item.maxPoints + 1e-9);
    if (!valid) {
      setState(() => _invalid.add(key));
      return;
    }
    if (_invalid.remove(key)) setState(() {});
    final current = widget.snapshot.scoresOf(studentId)[item.id];
    if (current == value) return;
    try {
      await ref
          .read(examRepositoryProvider)
          .setScore(
            examId: widget.snapshot.exam.id,
            expectationId: item.id!,
            studentId: studentId,
            points: value,
          );
    } on RangeError {
      if (mounted) setState(() => _invalid.add(key));
    }
  }

  void _move(int row, int column, {required int dRow, required int dColumn}) {
    final items = _items;
    var r = row;
    var c = column + dColumn;
    if (dColumn != 0) {
      if (c >= items.length) {
        c = 0;
        r++;
      } else if (c < 0) {
        c = items.length - 1;
        r--;
      }
    }
    r += dRow;
    final present = _presentStudents;
    if (r < 0 || r >= present.length) return;
    final target = _focus[(present[r].id, items[c].id!)];
    target?.requestFocus();
    final controller = _controllers[(present[r].id, items[c].id!)];
    if (controller != null) {
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }
  }

  List<Student> get _presentStudents => [
    for (final s in widget.students)
      if (widget.snapshot.attendanceOf(s.id) == ExamAttendance.present) s,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _items;
    final students = _presentStudents;
    final absent = widget.students.length - students.length;
    final calculator = widget.snapshot.calculator;
    final tableWidth = items.length * _cellWidth + _totalWidth + _gradeWidth;

    Widget headerCell(ExamItem item) => Tooltip(
      message:
          '${taskHeading(item, widget.snapshot.meta)}\n${item.description}',
      child: Container(
        width: _cellWidth,
        height: _headerHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.dividerColor),
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(shortTaskLabel(item), style: theme.textTheme.labelLarge),
            if (item.label != null)
              Text(
                item.label!,
                style: theme.textTheme.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '/${formatPoints(context, item.maxPoints)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    Widget fixed(
      String text,
      double width, {
      TextStyle? style,
      Alignment align = Alignment.center,
    }) => Container(
      width: width,
      height: _rowHeight,
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.medium,
            AppSpacing.large,
            0,
          ),
          child: Text(
            absent > 0
                ? '${'exam_grid_hint'.tr()} ${'exam_grid_absent'.tr(namedArgs: {'count': '$absent'})}'
                : 'exam_grid_hint'.tr(),
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            SizedBox(
              width: _nameWidth,
              height: _headerHeight,
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.large),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'students'.tr(),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _header,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: tableWidth,
                  child: Row(
                    children: [
                      for (final item in items) headerCell(item),
                      fixed(
                        'exam_total'.tr(),
                        _totalWidth,
                        style: theme.textTheme.labelLarge,
                      ),
                      fixed(
                        'grade'.tr(),
                        _gradeWidth,
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _nameWidth,
                  child: Column(
                    children: [
                      for (final (index, student) in students.indexed)
                        Container(
                          height: _rowHeight,
                          color: index.isOdd
                              ? theme.colorScheme.surfaceContainerLow
                              : null,
                          padding: const EdgeInsets.only(
                            left: AppSpacing.large,
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            studentName(student),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _body,
                    child: SingleChildScrollView(
                      controller: _body,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: tableWidth,
                        child: Column(
                          children: [
                            for (final (row, student) in students.indexed)
                              Container(
                                color: row.isOdd
                                    ? theme.colorScheme.surfaceContainerLow
                                    : null,
                                child: Row(
                                  children: [
                                    for (final (column, item) in items.indexed)
                                      _cell(row, column, student, item),
                                    () {
                                      final result = calculator.compute(
                                        widget.snapshot.scoresOf(student.id),
                                      );
                                      final override = widget
                                          .snapshot
                                          .participants[student.id]
                                          ?.gradeOverride;
                                      return Row(
                                        children: [
                                          fixed(
                                            '${formatPoints(context, result.total)} (${formatPercent(context, result.percent)} %)',
                                            _totalWidth,
                                          ),
                                          fixed(
                                            override ??
                                                (result.complete
                                                    ? (result.grade ?? '–')
                                                    : '(${result.grade ?? '–'})'),
                                            _gradeWidth,
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ],
                                      );
                                    }(),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(int row, int column, Student student, ExamItem item) {
    final theme = Theme.of(context);
    final key = (student.id, item.id!);
    final invalid = _invalid.contains(key);
    return Container(
      width: _cellWidth,
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
              _move(row, column, dRow: 1, dColumn: 0),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
              _move(row, column, dRow: -1, dColumn: 0),
        },
        child: TextField(
          controller: _controller(student.id, item.id!),
          focusNode: _node(student.id, item.id!, item),
          textAlign: TextAlign.center,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _move(row, column, dRow: 0, dColumn: 1),
          onTap: () {
            final c = _controllers[key]!;
            c.selection = TextSelection(
              baseOffset: 0,
              extentOffset: c.text.length,
            );
          },
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: const OutlineInputBorder(),
            enabledBorder: invalid
                ? OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                  )
                : OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
            focusedBorder: invalid
                ? OutlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.error,
                      width: 2,
                    ),
                  )
                : null,
            filled: invalid,
            fillColor: invalid ? theme.colorScheme.errorContainer : null,
          ),
        ),
      ),
    );
  }
}
