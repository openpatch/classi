import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_ui.dart';
import '../data/exam_repository.dart';
import '../domain/exam_calculator.dart';
import '../domain/exam_structure.dart';
import '../exam_providers.dart';
import 'exam_format.dart';

const double _nameWidth = 200;
const double _cellWidth = 64;
const double _rowHeight = 40;
const double _headerHeight = 60;
const double _totalWidth = 112;
const double _gradeWidth = 64;

typedef _Cell = ({int row, int column});

/// Keyboard-driven point entry for wide screens, like a spreadsheet: one row
/// per student, one column per expectation.
///
/// Cells are plain text; only the selected cell is a text field. Rows are
/// built lazily. Enter and Tab move right (wrapping to the next student), the
/// up and down arrows move between students, Escape discards the typed
/// value. A value is saved when the cell is left.
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
  final _headerScroll = ScrollController();
  final _bodyScroll = ScrollController();
  final _namesScroll = ScrollController();
  final _rowsScroll = ScrollController();
  final _editor = TextEditingController();

  /// Focus of the open cell. Every cell gets a fresh node: a text field only
  /// opens its text input connection when its node *gains* focus, so reusing
  /// an already focused node for the next cell would swallow all typing.
  late FocusNode _editorFocus = _newEditorFocus();

  _Cell? _selected;
  bool _invalid = false;

  /// Values written but not yet back from the database, so a saved cell does
  /// not flash its old value.
  final _pending = <(int, int), double?>{};

  /// Built rows by student, reused while nothing in the row changed: saving
  /// one value then rebuilds one row, not the whole class.
  final _rowCache = <int, (String, Widget)>{};

  late List<ExamItem> _items;
  late List<Student> _students;
  late ExamCalculator _calculator;

  @override
  void initState() {
    super.initState();
    _derive();
    _bodyScroll.addListener(() {
      if (_headerScroll.hasClients) _headerScroll.jumpTo(_bodyScroll.offset);
    });
    _rowsScroll.addListener(() {
      if (_namesScroll.hasClients) _namesScroll.jumpTo(_rowsScroll.offset);
    });
  }

  static bool _sameItems(ExamSnapshot a, ExamSnapshot b) {
    if (a.items.length != b.items.length) return false;
    for (var i = 0; i < a.items.length; i++) {
      final x = a.items[i];
      final y = b.items[i];
      if (x.id != y.id || x.maxPoints != y.maxPoints || x.kind != y.kind) {
        return false;
      }
    }
    return a.meta.sameAs(b.meta);
  }

  FocusNode _newEditorFocus() {
    late final FocusNode node;
    node = FocusNode()
      ..addListener(() {
        // Clicking somewhere outside the grid saves the open cell.
        if (identical(node, _editorFocus) &&
            !node.hasFocus &&
            _selected != null) {
          _commit();
        }
      });
    return node;
  }

  void _derive() {
    _items = [
      for (final item in widget.snapshot.items)
        if (item.kind.isScored && item.id != null) item,
    ];
    _students = [
      for (final s in widget.students)
        if (widget.snapshot.attendanceOf(s.id) == ExamAttendance.present) s,
    ];
    _calculator = widget.snapshot.calculator;
    _rowCache.clear();
  }

  String _rowSignature(int row, Student student) {
    final selected = _selected;
    final inRow = selected != null && selected.row == row;
    final buffer = StringBuffer()
      ..write(row)
      ..write(inRow ? 'S${selected.column}$_invalid' : '-')
      ..write(widget.snapshot.participants[student.id]?.gradeOverride);
    for (final item in _items) {
      buffer
        ..write('|')
        ..write(_value(student.id, item.id!));
    }
    return buffer.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Theme or language changed: cached rows are stale.
    _rowCache.clear();
  }

  @override
  void didUpdateWidget(covariant ExamPointsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sameShape =
        _sameItems(oldWidget.snapshot, widget.snapshot) &&
        oldWidget.snapshot.scheme.sameAs(widget.snapshot.scheme) &&
        identical(oldWidget.students, widget.students);
    final cache = Map.of(_rowCache);
    _derive();
    // Rows only depend on the student's own values (part of the signature)
    // as long as structure, scheme and students stay the same.
    if (sameShape) _rowCache.addAll(cache);
    // Drop pending values the database has caught up with.
    _pending.removeWhere(
      (key, value) => widget.snapshot.scoresOf(key.$1)[key.$2] == value,
    );
    final selected = _selected;
    if (selected != null &&
        (selected.row >= _students.length ||
            selected.column >= _items.length)) {
      _selected = null;
    }
  }

  @override
  void dispose() {
    for (final c in [_headerScroll, _bodyScroll, _namesScroll, _rowsScroll]) {
      c.dispose();
    }
    _editor.dispose();
    _editorFocus.dispose();
    super.dispose();
  }

  double? _value(int studentId, int itemId) {
    final key = (studentId, itemId);
    if (_pending.containsKey(key)) return _pending[key];
    return widget.snapshot.scoresOf(studentId)[itemId];
  }

  Map<int, double> _scoresWithPending(int studentId) {
    final scores = {...widget.snapshot.scoresOf(studentId)};
    for (final entry in _pending.entries) {
      if (entry.key.$1 != studentId) continue;
      if (entry.value == null) {
        scores.remove(entry.key.$2);
      } else {
        scores[entry.key.$2] = entry.value!;
      }
    }
    return scores;
  }

  void _select(_Cell cell) {
    final student = _students[cell.row];
    final item = _items[cell.column];
    final value = _value(student.id, item.id!);
    final previous = _editorFocus;
    _editorFocus = _newEditorFocus();
    // The old field is gone after this frame; release its node then.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    setState(() {
      _selected = cell;
      _invalid = false;
      _editor.text = value == null ? '' : formatPoints(context, value);
      _editor.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _editor.text.length,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selected == cell) _editorFocus.requestFocus();
    });
  }

  /// Saves the open cell. Returns `false` (and keeps the cell open) when the
  /// typed value is not a valid number of points.
  bool _commit() {
    final cell = _selected;
    if (cell == null) return true;
    final student = _students[cell.row];
    final item = _items[cell.column];
    final text = _editor.text;
    final value = parsePoints(text);
    final valid =
        text.trim().isEmpty ||
        (value != null && value >= 0 && value <= item.maxPoints + 1e-9);
    if (!valid) {
      setState(() => _invalid = true);
      return false;
    }
    final key = (student.id, item.id!);
    if (_value(student.id, item.id!) == value) return true;
    setState(() => _pending[key] = value);
    ref
        .read(examRepositoryProvider)
        .setScore(
          examId: widget.snapshot.exam.id,
          expectationId: item.id!,
          studentId: student.id,
          points: value,
        )
        .catchError((Object _) {
          if (mounted) setState(() => _pending.remove(key));
        });
    return true;
  }

  void _move({int dRow = 0, int dColumn = 0}) {
    final cell = _selected;
    if (cell == null || !_commit()) return;
    var row = cell.row;
    var column = cell.column + dColumn;
    if (column >= _items.length) {
      column = 0;
      row++;
    } else if (column < 0) {
      column = _items.length - 1;
      row--;
    }
    row += dRow;
    if (row < 0 || row >= _students.length) return;
    _select((row: row, column: column));
    _reveal(row, column);
  }

  /// Scrolls so the selected cell is visible.
  void _reveal(int row, int column) {
    if (_rowsScroll.hasClients) {
      final top = row * _rowHeight;
      final viewport = _rowsScroll.position.viewportDimension;
      final offset = _rowsScroll.offset;
      if (top < offset) {
        _rowsScroll.jumpTo(top);
      } else if (top + _rowHeight > offset + viewport) {
        _rowsScroll.jumpTo(top + _rowHeight - viewport);
      }
    }
    if (_bodyScroll.hasClients) {
      final left = column * _cellWidth;
      final viewport = _bodyScroll.position.viewportDimension;
      final offset = _bodyScroll.offset;
      if (left < offset) {
        _bodyScroll.jumpTo(left);
      } else if (left + _cellWidth > offset + viewport) {
        _bodyScroll.jumpTo(left + _cellWidth - viewport);
      }
    }
  }

  void _cancel() {
    final cell = _selected;
    if (cell == null) return;
    _select(cell);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absent = widget.students.length - _students.length;
    final tableWidth = _items.length * _cellWidth + _totalWidth + _gradeWidth;
    final border = BorderSide(color: theme.dividerColor);

    Widget headerCell(ExamItem item) => Tooltip(
      message:
          '${taskHeading(item, widget.snapshot.meta)}\n${item.description}',
      child: Container(
        width: _cellWidth,
        height: _headerHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(left: border, bottom: border),
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

    Widget plain(String text, double width, {TextStyle? style}) => Container(
      width: width,
      height: _headerHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(left: border, bottom: border),
      ),
      child: Text(text, style: style),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.large,
            AppSpacing.medium,
            AppSpacing.large,
            AppSpacing.small,
          ),
          child: Text(
            absent > 0
                ? '${'exam_grid_hint'.tr()} ${'exam_grid_absent'.tr(namedArgs: {'count': '$absent'})}'
                : 'exam_grid_hint'.tr(),
            style: theme.textTheme.bodySmall,
          ),
        ),
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
                controller: _headerScroll,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: [
                    for (final item in _items) headerCell(item),
                    plain(
                      'exam_total'.tr(),
                      _totalWidth,
                      style: theme.textTheme.labelLarge,
                    ),
                    plain(
                      'grade'.tr(),
                      _gradeWidth,
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _nameWidth,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: ListView.builder(
                    controller: _namesScroll,
                    physics: const NeverScrollableScrollPhysics(),
                    itemExtent: _rowHeight,
                    itemCount: _students.length,
                    itemBuilder: (context, row) => Container(
                      color: row.isOdd
                          ? theme.colorScheme.surfaceContainerLow
                          : null,
                      padding: const EdgeInsets.only(left: AppSpacing.large),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        studentName(_students[row]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  controller: _bodyScroll,
                  child: SingleChildScrollView(
                    controller: _bodyScroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: ListView.builder(
                        controller: _rowsScroll,
                        itemExtent: _rowHeight,
                        itemCount: _students.length,
                        itemBuilder: (context, row) {
                          final student = _students[row];
                          final signature = _rowSignature(row, student);
                          final cached = _rowCache[student.id];
                          if (cached != null && cached.$1 == signature) {
                            return cached.$2;
                          }
                          final built = _row(theme, row);
                          _rowCache[student.id] = (signature, built);
                          return built;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, int row) {
    final student = _students[row];
    final result = _calculator.compute(_scoresWithPending(student.id));
    final override = widget.snapshot.participants[student.id]?.gradeOverride;
    final border = BorderSide(color: theme.dividerColor);
    Widget fixed(String text, double width, {TextStyle? style}) => Container(
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border(left: border)),
      child: Text(text, style: style, overflow: TextOverflow.ellipsis),
    );

    return Container(
      color: row.isOdd ? theme.colorScheme.surfaceContainerLow : null,
      child: Row(
        children: [
          for (var column = 0; column < _items.length; column++)
            _cell(theme, row, column, student),
          fixed(
            '${formatPoints(context, result.total)} '
            '(${formatPercent(context, result.percent)} %)',
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
      ),
    );
  }

  Widget _cell(ThemeData theme, int row, int column, Student student) {
    final item = _items[column];
    final selected = _selected == (row: row, column: column);
    final border = BorderSide(color: theme.dividerColor);

    if (selected) {
      final color = _invalid
          ? theme.colorScheme.error
          : theme.colorScheme.primary;
      return Container(
        width: _cellWidth,
        decoration: BoxDecoration(
          color: _invalid ? theme.colorScheme.errorContainer : null,
          border: Border.all(color: color, width: 2),
        ),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                _move(dRow: 1),
            const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
                _move(dRow: -1),
            const SingleActivator(LogicalKeyboardKey.tab): () =>
                _move(dColumn: 1),
            const SingleActivator(LogicalKeyboardKey.tab, shift: true): () =>
                _move(dColumn: -1),
            const SingleActivator(LogicalKeyboardKey.escape): _cancel,
          },
          child: TextField(
            controller: _editor,
            focusNode: _editorFocus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _move(dColumn: 1),
            onChanged: (_) {
              if (_invalid) setState(() => _invalid = false);
            },
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      );
    }

    final value = _value(student.id, item.id!);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_commit()) _select((row: row, column: column));
      },
      child: Container(
        width: _cellWidth,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border(left: border)),
        child: Text(
          value == null ? '' : formatPoints(context, value),
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}
