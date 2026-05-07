import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_bar_title.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/student_link_chip.dart';
import '../../shared/widgets/surface_list_tile.dart';
import '../../shared/widgets/student_avatar.dart';
import '../../shared/widgets/swipe_action_background.dart';
import '../../shared/theme/app_ui.dart';
import '../lists/list_repository.dart';
import '../lists/list_editor.dart';
import '../lessons/lesson_support.dart';
import '../notes/note_editor.dart';
import '../notes/note_links.dart';
import '../students/student_batch_create_sheet.dart';
import '../students/student_form.dart';
import '../students/student_import_parser.dart';
import '../students/student_sorting.dart';
import 'group_form.dart';

final groupProvider = StreamProvider.autoDispose.family<Group?, int>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).watchGroup(groupId),
);

final groupStudentsProvider = StreamProvider.autoDispose
    .family<List<Student>, int>(
      (ref, groupId) => ref
          .watch(studentRepositoryProvider)
          .watchByGroup(
            groupId,
            sortField: ref.watch(studentSortFieldProvider),
          ),
    );

final groupAveragesProvider = StreamProvider.autoDispose
    .family<Map<int, double>, int>(
      (ref, groupId) =>
          ref.watch(gradeRepositoryProvider).watchGroupAverages(groupId),
    );

final groupCategoryAveragesProvider = StreamProvider.autoDispose
    .family<Map<int, Map<String, double>>, int>(
      (ref, groupId) => ref
          .watch(gradeRepositoryProvider)
          .watchGroupCategoryAverages(groupId),
    );

final groupNotesProvider = StreamProvider.autoDispose
    .family<List<TeacherNote>, int>(
      (ref, groupId) =>
          ref.watch(noteRepositoryProvider).watchNotesForGroup(groupId),
    );

final archivedGroupNotesProvider = StreamProvider.autoDispose
    .family<List<TeacherNote>, int>(
      (ref, groupId) =>
          ref.watch(noteRepositoryProvider).watchArchivedNotesForGroup(groupId),
    );

final groupListsProvider = StreamProvider.autoDispose
    .family<List<Checklist>, int>(
      (ref, groupId) => ref.watch(listRepositoryProvider).watchLists(groupId),
    );

final archivedGroupListsProvider = StreamProvider.autoDispose
    .family<List<Checklist>, int>(
      (ref, groupId) =>
          ref.watch(listRepositoryProvider).watchArchivedLists(groupId),
    );

final groupListProgressProvider = StreamProvider.autoDispose
    .family<Map<int, ListProgress>, int>(
      (ref, groupId) =>
          ref.watch(listRepositoryProvider).watchListProgress(groupId: groupId),
    );

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({required this.groupId, super.key});

  final int groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(studentSortFieldProvider);
    final groupValue = ref.watch(groupProvider(groupId));
    final studentsValue = ref.watch(groupStudentsProvider(groupId));
    final averagesValue = ref.watch(groupAveragesProvider(groupId));
    final categoryAveragesValue = ref.watch(
      groupCategoryAveragesProvider(groupId),
    );
    final notesValue = ref.watch(groupNotesProvider(groupId));
    final archivedNotesValue = ref.watch(archivedGroupNotesProvider(groupId));
    final listsValue = ref.watch(groupListsProvider(groupId));
    final archivedListsValue = ref.watch(archivedGroupListsProvider(groupId));
    final listProgressValue = ref.watch(groupListProgressProvider(groupId));

    return groupValue.when(
      data: (group) {
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Missing group',
            ),
          );
        }

        final archived = group.archivedAt != null;
        final groupColor = colorFromHex(group.colorHex);
        final appBarForeground = onColorForBackground(groupColor);
        final gradeScaleEntries = parseGradeScaleEntries(group.gradeScaleJson);
        final categories = parseGradeCategories(group.gradeCategoriesJson);
        final archivedDate = group.archivedAt == null
            ? null
            : DateFormat.yMMMd(
                context.locale.toLanguageTag(),
              ).format(group.archivedAt!);
        final students = studentsValue.value ?? const <Student>[];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: groupColor,
            foregroundColor: appBarForeground,
            title: AppBarTitle(title: group.name, subtitle: 'groups'.tr()),
            actions: [
              IconButton(
                onPressed: () => _editGroup(context, ref, group),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'edit'.tr(),
              ),
            ],
          ),
          floatingActionButton: archived
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => context.push(
                    '/groups/$groupId/lesson?date=${encodeLessonDate(DateTime.now())}',
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text('open_lesson_mode'.tr()),
                ),
          body: ContentConstraints(
            child: ListView(
              padding: appScreenPadding,
              children: [
              if (archived && archivedDate != null)
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(
                      'archived_banner'.tr(namedArgs: {'date': archivedDate}),
                    ),
                    onTap: () => ref
                        .read(groupRepositoryProvider)
                        .unarchiveGroup(group.id),
                  ),
                ),
              Card(
                child: Padding(
                  padding: appCardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: groupColor.withValues(alpha: 0.18),
                            child: CircleAvatar(
                              radius: 5,
                              backgroundColor: groupColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              group.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: AppSpacing.small,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.people_outline, size: 18),
                            label: Text(
                              '${students.length} ${'students'.tr()}',
                            ),
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.category_outlined,
                              size: 18,
                            ),
                            label: Text(
                              '${categories.length} ${'grade_categories'.tr()}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.small),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Text('grades'.tr()),
                        childrenPadding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.small,
                              children: [
                                for (final grade in parseGradeScale(
                                  group.gradeScaleJson,
                                ))
                                  Chip(label: Text(grade)),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: AppSpacing.small,
                              runSpacing: AppSpacing.small,
                              children: [
                                for (final category in categories)
                                  Chip(
                                    avatar: CircleAvatar(
                                      radius: 8,
                                      backgroundColor: colorForCategory(
                                        category,
                                      ),
                                    ),
                                    label: Text(
                                      '${category.name} (${formatNumber(category.weight)})',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              _LessonCalendarCard(groupId: group.id, groupColor: groupColor),
              const SizedBox(height: AppSpacing.large),
              studentsValue.when(
                data: (loadedStudents) => _StudentsSection(
                  students: loadedStudents,
                  sortField: sortField,
                  gradeScaleEntries: gradeScaleEntries,
                  categories: categories,
                  averagesValue: averagesValue,
                  categoryAveragesValue: categoryAveragesValue,
                  onAddStudent: archived
                      ? null
                      : () => _addStudent(context, ref, group.id),
                  onBatchCreateStudents: archived
                      ? null
                      : () => _batchCreateStudents(context, ref, group.id),
                  onImportStudents: archived
                      ? null
                      : () => _importWebUntisStudents(context, ref, group.id),
                ),
                error: (error, _) => const AppErrorText(),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: AppSpacing.large),
              _GroupListsCard(
                groupId: group.id,
                activeListsValue: listsValue,
                archivedListsValue: archivedListsValue,
                progress:
                    listProgressValue.value ?? const <int, ListProgress>{},
                onAddList: archived
                    ? null
                    : () => _createList(context, ref, group),
                onEditList: (list) => _editList(context, ref, list),
                onArchiveList: (list) =>
                    ref.read(listRepositoryProvider).archiveList(list.id),
                onUnarchiveList: (list) =>
                    ref.read(listRepositoryProvider).unarchiveList(list.id),
                onDeleteList: (list) => _deleteList(context, ref, list),
                onDeleteListDirect: (list) =>
                    ref.read(listRepositoryProvider).deleteList(list.id),
              ),
              const SizedBox(height: AppSpacing.large),
              _GroupNotesCard(
                activeNotesValue: notesValue,
                archivedNotesValue: archivedNotesValue,
                students: students,
                onEditNote: (note) =>
                    _editNote(context, ref, group, students, note),
                onToggleNote: (note) => ref
                    .read(noteRepositoryProvider)
                    .toggleTodo(note, !note.todoDone),
                onArchiveNote: (note) =>
                    ref.read(noteRepositoryProvider).archiveNote(note.id),
                onUnarchiveNote: (note) =>
                    ref.read(noteRepositoryProvider).unarchiveNote(note.id),
                onDeleteNote: (note) => _deleteNote(context, ref, note),
                onDeleteNoteDirect: (note) =>
                    ref.read(noteRepositoryProvider).deleteNote(note.id),
                onAddNote: archived
                    ? null
                    : () => _addGroupNote(context, ref, group, students),
              ),
            ],
          ),
          ),
        );
      },
      error: (error, _) => const AppErrorScaffold(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Future<void> _addStudent(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final result = await showStudentFormSheet(context: context);
    if (result == null) {
      return;
    }

    await ref
        .read(studentRepositoryProvider)
        .addStudent(
          groupId: groupId,
          firstName: result.firstName,
          lastName: result.lastName,
          originNote: result.originNote,
          avatarJson: result.avatarJson,
        );
    _refreshStudentSection(ref, groupId);
  }

  Future<void> _batchCreateStudents(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final drafts = await showStudentBatchCreateSheet(context: context);
    if (drafts == null || drafts.isEmpty) {
      return;
    }

    await ref
        .read(studentRepositoryProvider)
        .addStudents(groupId: groupId, students: drafts);
    _refreshStudentSection(ref, groupId);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'students_created'.tr(namedArgs: {'count': drafts.length.toString()}),
        ),
      ),
    );
  }

  Future<void> _importWebUntisStudents(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final session = ref.read(appSessionProvider);
    session.suspendBackgroundLock();
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'tsv', 'txt'],
        withData: true,
      );
    } finally {
      session.resumeBackgroundLock();
    }
    if (result == null || result.files.isEmpty) {
      return;
    }

    try {
      final file = result.files.single;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final drafts = parseWebUntisStudentText(
        utf8.decode(bytes, allowMalformed: true),
      );
      await ref
          .read(studentRepositoryProvider)
          .addStudents(groupId: groupId, students: drafts);
      _refreshStudentSection(ref, groupId);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'students_imported'.tr(
              namedArgs: {'count': drafts.length.toString()},
            ),
          ),
        ),
      );
    } on FormatException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.tr())));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('webuntis_import_failed'.tr())));
    }
  }

  void _refreshStudentSection(WidgetRef ref, int groupId) {
    ref.invalidate(groupStudentsProvider(groupId));
    ref.invalidate(groupAveragesProvider(groupId));
    ref.invalidate(groupCategoryAveragesProvider(groupId));
  }

  Future<void> _createList(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final result = await showListEditorDialog(
      context: context,
      groups: [group],
      initialGroupId: group.id,
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
          groupId: group.id,
          name: result.name,
          populateFromGroupStudents: result.populateFromGroupStudents,
          sortField: ref.read(studentSortFieldProvider),
        );
  }

  Future<void> _addGroupNote(
    BuildContext context,
    WidgetRef ref,
    Group group,
    List<Student> students,
  ) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: [group],
      students: students,
      initialGroupId: group.id,
      title: 'add_group_note'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(noteRepositoryProvider)
        .saveNote(
          body: result.body,
          groupId: result.groupId,
          studentIds: result.studentIds,
          isTodo: result.isTodo,
          createdAt: result.createdAt,
        );
  }

  Future<void> _editList(
    BuildContext context,
    WidgetRef ref,
    Checklist list,
  ) async {
    final name = await _showListNameDialog(
      context: context,
      initialName: list.name,
      title: 'edit'.tr(),
      actionLabel: 'save'.tr(),
    );
    if (name == null || name.isEmpty) {
      return;
    }

    await ref
        .read(listRepositoryProvider)
        .renameList(listId: list.id, name: name);
  }

  Future<String?> _showListNameDialog({
    required BuildContext context,
    required String title,
    required String actionLabel,
    String? initialName,
  }) async {
    final controller = TextEditingController(text: initialName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'new_list'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();
    return name;
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

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    Group group,
    List<Student> students,
    TeacherNote note,
  ) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: [group],
      students: students,
      initialGroupId: note.groupId,
      initialStudentIds: noteStudentIds(note),
      initialBody: note.body,
      initialIsTodo: note.isTodo,
      initialCreatedAt: note.createdAt,
      title: 'edit_note'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(noteRepositoryProvider)
        .updateNote(
          note: note,
          body: result.body,
          groupId: result.groupId,
          studentIds: result.studentIds,
          isTodo: result.isTodo,
          createdAt: result.createdAt,
        );
  }

  Future<void> _deleteNote(
    BuildContext context,
    WidgetRef ref,
    TeacherNote note,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete'.tr(namedArgs: {'name': 'note_body'.tr()}),
      body: note.body,
    );
    if (confirmed) {
      await ref.read(noteRepositoryProvider).deleteNote(note.id);
    }
  }

  Future<void> _editGroup(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final gradeSystems = ref.read(gradeSystemControllerProvider).systems;
    if (gradeSystems.isEmpty) {
      return;
    }

    final result = await showGroupFormSheet(
      context: context,
      gradeSystems: gradeSystems,
      initialName: group.name,
      initialGroupColorHex: group.colorHex,
      initialGradeScale: parseGradeScaleEntries(group.gradeScaleJson),
      initialGradeCategories: parseGradeCategories(group.gradeCategoriesJson),
      title: 'edit'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(groupRepositoryProvider)
        .updateGroup(
          id: group.id,
          name: result.name,
          colorHex: result.colorHex,
          gradeScale: result.gradeScale,
          gradeCategories: result.gradeCategories,
        );
  }
}

class _LessonCalendarCard extends ConsumerStatefulWidget {
  const _LessonCalendarCard({required this.groupId, required this.groupColor});

  final int groupId;
  final Color groupColor;

  @override
  ConsumerState<_LessonCalendarCard> createState() =>
      _LessonCalendarCardState();
}

class _LessonCalendarCardState extends ConsumerState<_LessonCalendarCard> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = normalizeLessonDate(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final lessonEntryDatesValue = ref.watch(
      lessonEntryDatesProvider(widget.groupId),
    );
    final lessonEntryDates = lessonEntryDatesValue.value ?? const <DateTime>{};

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'lesson_calendar'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => context.push(
                    '/groups/${widget.groupId}/lesson?date=${encodeLessonDate(DateTime.now())}',
                  ),
                  child: Text('today'.tr()),
                ),
                const SizedBox(width: AppSpacing.medium),
                if (lessonEntryDatesValue.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            TableCalendar<void>(
              locale: context.locale.toLanguageTag(),
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) =>
                  lessonEntryDates.contains(normalizeLessonDate(day))
                  ? const [null]
                  : const [],
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                canMarkersOverflow: false,
                markerSize: 6,
                markerMargin: const EdgeInsets.only(top: 2),
                markersAnchor: 0.82,
                markerDecoration: BoxDecoration(
                  color: widget.groupColor,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: widget.groupColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: widget.groupColor.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
              onPageChanged: (focusedDay) {
                setState(() => _focusedDay = normalizeLessonDate(focusedDay));
              },
              onDaySelected: (selectedDay, focusedDay) {
                final normalizedSelectedDay = normalizeLessonDate(selectedDay);
                setState(() {
                  _selectedDay = normalizedSelectedDay;
                  _focusedDay = normalizeLessonDate(focusedDay);
                });
                context.push(
                  '/groups/${widget.groupId}/lesson?date=${encodeLessonDate(normalizedSelectedDay)}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupListsCard extends StatelessWidget {
  const _GroupListsCard({
    required this.groupId,
    required this.activeListsValue,
    required this.archivedListsValue,
    required this.progress,
    required this.onAddList,
    required this.onEditList,
    required this.onArchiveList,
    required this.onUnarchiveList,
    required this.onDeleteList,
    required this.onDeleteListDirect,
  });

  final int groupId;
  final AsyncValue<List<Checklist>> activeListsValue;
  final AsyncValue<List<Checklist>> archivedListsValue;
  final Map<int, ListProgress> progress;
  final VoidCallback? onAddList;
  final ValueChanged<Checklist> onEditList;
  final ValueChanged<Checklist> onArchiveList;
  final ValueChanged<Checklist> onUnarchiveList;
  final ValueChanged<Checklist> onDeleteList;
  final ValueChanged<Checklist> onDeleteListDirect;

  @override
  Widget build(BuildContext context) {
    final activeLists = activeListsValue.value ?? const <Checklist>[];
    final archivedLists = archivedListsValue.value ?? const <Checklist>[];

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'lists'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onAddList != null)
                  FilledButton.tonalIcon(
                    onPressed: onAddList,
                    icon: const Icon(Icons.add),
                    label: Text('new_list'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (activeListsValue.isLoading || archivedListsValue.isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (activeLists.isEmpty && archivedLists.isEmpty)
              Text('empty_lists'.tr())
            else ...[
              for (final list in activeLists)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: Dismissible(
                    key: ValueKey('group-list-${list.id}'),
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
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
                    child: SurfaceListTile(
                      onTap: () =>
                          context.push('/groups/$groupId/lists/${list.id}'),
                      title: Text(
                        '${list.name} (${(progress[list.id]?.checked ?? 0)}/${(progress[list.id]?.total ?? 0)})',
                      ),
                      trailing: PopupMenuButton<_GroupListAction>(
                        onSelected: (action) {
                          switch (action) {
                            case _GroupListAction.edit:
                              onEditList(list);
                              return;
                            case _GroupListAction.archive:
                              onArchiveList(list);
                              return;
                            case _GroupListAction.unarchive:
                              onUnarchiveList(list);
                              return;
                            case _GroupListAction.delete:
                              onDeleteList(list);
                              return;
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _GroupListAction.edit,
                            child: Text('edit'.tr()),
                          ),
                          PopupMenuItem(
                            value: _GroupListAction.archive,
                            child: Text('archive'.tr()),
                          ),
                          PopupMenuItem(
                            value: _GroupListAction.delete,
                            child: Text('delete'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (archivedLists.isNotEmpty) ...[
                const Divider(height: AppSpacing.xxLarge),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('${'archived'.tr()} (${archivedLists.length})'),
                  children: [
                    for (final list in archivedLists)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: SurfaceListTile(
                          onTap: () =>
                              context.push('/groups/$groupId/lists/${list.id}'),
                          title: Text(
                            '${list.name} (${(progress[list.id]?.checked ?? 0)}/${(progress[list.id]?.total ?? 0)})',
                          ),
                          trailing: PopupMenuButton<_GroupListAction>(
                            onSelected: (action) {
                              switch (action) {
                                case _GroupListAction.edit:
                                case _GroupListAction.archive:
                                  return;
                                case _GroupListAction.unarchive:
                                  onUnarchiveList(list);
                                  return;
                                case _GroupListAction.delete:
                                  onDeleteList(list);
                                  return;
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: _GroupListAction.unarchive,
                                child: Text('unarchive'.tr()),
                              ),
                              PopupMenuItem(
                                value: _GroupListAction.delete,
                                child: Text('delete'.tr()),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupNotesCard extends StatelessWidget {
  const _GroupNotesCard({
    required this.activeNotesValue,
    required this.archivedNotesValue,
    required this.students,
    required this.onEditNote,
    required this.onToggleNote,
    required this.onArchiveNote,
    required this.onUnarchiveNote,
    required this.onDeleteNote,
    required this.onDeleteNoteDirect,
    required this.onAddNote,
  });

  final AsyncValue<List<TeacherNote>> activeNotesValue;
  final AsyncValue<List<TeacherNote>> archivedNotesValue;
  final List<Student> students;
  final ValueChanged<TeacherNote> onEditNote;
  final ValueChanged<TeacherNote> onToggleNote;
  final ValueChanged<TeacherNote> onArchiveNote;
  final ValueChanged<TeacherNote> onUnarchiveNote;
  final ValueChanged<TeacherNote> onDeleteNote;
  final ValueChanged<TeacherNote> onDeleteNoteDirect;
  final VoidCallback? onAddNote;

  @override
  Widget build(BuildContext context) {
    final activeNotes = activeNotesValue.value ?? const <TeacherNote>[];
    final archivedNotes = archivedNotesValue.value ?? const <TeacherNote>[];
    final studentsById = {for (final student in students) student.id: student};
    final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'notes'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onAddNote != null)
                  FilledButton.tonalIcon(
                    onPressed: onAddNote,
                    icon: const Icon(Icons.add),
                    label: Text('add_group_note'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (activeNotesValue.isLoading || archivedNotesValue.isLoading)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (activeNotes.isEmpty && archivedNotes.isEmpty)
              Text('empty_group_notes'.tr())
            else ...[
              for (final note in activeNotes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: Dismissible(
                    key: ValueKey('group-note-${note.id}'),
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
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onErrorContainer,
                    ),
                    confirmDismiss: (direction) async {
                      switch (direction) {
                        case DismissDirection.startToEnd:
                          return true;
                        case DismissDirection.endToStart:
                          return showConfirmDialog(
                            context: context,
                            title: 'confirm_delete'.tr(
                              namedArgs: {'name': 'note_body'.tr()},
                            ),
                            body: note.body,
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
                          onArchiveNote(note);
                          return;
                        case DismissDirection.endToStart:
                          onDeleteNoteDirect(note);
                          return;
                        case DismissDirection.none:
                        case DismissDirection.down:
                        case DismissDirection.up:
                        case DismissDirection.horizontal:
                        case DismissDirection.vertical:
                          return;
                      }
                    },
                    child: _GroupNoteTile(
                      note: note,
                      linkedStudents: [
                        for (final studentId in noteStudentIds(note))
                          if (studentsById[studentId] != null)
                            studentsById[studentId]!,
                      ],
                      dateFormat: dateFormat,
                      onTap: () => onEditNote(note),
                      onSelected: (action) {
                        switch (action) {
                          case _GroupNoteAction.edit:
                            onEditNote(note);
                            return;
                          case _GroupNoteAction.toggle:
                            onToggleNote(note);
                            return;
                          case _GroupNoteAction.archive:
                            onArchiveNote(note);
                            return;
                          case _GroupNoteAction.unarchive:
                            onUnarchiveNote(note);
                            return;
                          case _GroupNoteAction.delete:
                            onDeleteNote(note);
                            return;
                        }
                      },
                    ),
                  ),
                ),
              if (archivedNotes.isNotEmpty) ...[
                const Divider(height: AppSpacing.xxLarge),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('${'archived'.tr()} (${archivedNotes.length})'),
                  children: [
                    for (final note in archivedNotes)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: _GroupNoteTile(
                          note: note,
                          linkedStudents: [
                            for (final studentId in noteStudentIds(note))
                              if (studentsById[studentId] != null)
                                studentsById[studentId]!,
                          ],
                          dateFormat: dateFormat,
                          archived: true,
                          onTap: () => onEditNote(note),
                          onSelected: (action) {
                            switch (action) {
                              case _GroupNoteAction.edit:
                              case _GroupNoteAction.toggle:
                              case _GroupNoteAction.archive:
                                return;
                              case _GroupNoteAction.unarchive:
                                onUnarchiveNote(note);
                                return;
                              case _GroupNoteAction.delete:
                                onDeleteNote(note);
                                return;
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupNoteTile extends StatelessWidget {
  const _GroupNoteTile({
    required this.note,
    required this.linkedStudents,
    required this.dateFormat,
    required this.onTap,
    required this.onSelected,
    this.archived = false,
  });

  final TeacherNote note;
  final List<Student> linkedStudents;
  final DateFormat dateFormat;
  final bool archived;
  final VoidCallback onTap;
  final ValueChanged<_GroupNoteAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return SurfaceListTile(
      onTap: onTap,
      leading: linkedStudents.isEmpty
          ? null
          : linkedStudents.length == 1
          ? StudentAvatar(student: linkedStudents.first, size: 32)
          : CircleAvatar(child: Text('${linkedStudents.length}')),
      title: Text(note.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(dateFormat.format(note.createdAt)),
          if (linkedStudents.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                for (final student in linkedStudents)
                  StudentLinkChip(student: student),
              ],
            ),
          ],
          if (note.isTodo) Text(note.todoDone ? 'done'.tr() : 'todo'.tr()),
        ],
      ),
      trailing: PopupMenuButton<_GroupNoteAction>(
        onSelected: onSelected,
        itemBuilder: (_) => archived
            ? [
                PopupMenuItem(
                  value: _GroupNoteAction.unarchive,
                  child: Text('unarchive'.tr()),
                ),
                PopupMenuItem(
                  value: _GroupNoteAction.delete,
                  child: Text('delete'.tr()),
                ),
              ]
            : [
                PopupMenuItem(
                  value: _GroupNoteAction.edit,
                  child: Text('edit'.tr()),
                ),
                if (note.isTodo)
                  PopupMenuItem(
                    value: _GroupNoteAction.toggle,
                    child: Text(note.todoDone ? 'todo'.tr() : 'done'.tr()),
                  ),
                PopupMenuItem(
                  value: _GroupNoteAction.archive,
                  child: Text('archive'.tr()),
                ),
                PopupMenuItem(
                  value: _GroupNoteAction.delete,
                  child: Text('delete'.tr()),
                ),
              ],
      ),
    );
  }
}

class _StudentsSection extends StatelessWidget {
  const _StudentsSection({
    required this.students,
    required this.sortField,
    required this.gradeScaleEntries,
    required this.categories,
    required this.averagesValue,
    required this.categoryAveragesValue,
    required this.onAddStudent,
    required this.onBatchCreateStudents,
    required this.onImportStudents,
  });

  final List<Student> students;
  final StudentSortField sortField;
  final List<GradeScaleEntry> gradeScaleEntries;
  final List<GradeCategory> categories;
  final AsyncValue<Map<int, double>> averagesValue;
  final AsyncValue<Map<int, Map<String, double>>> categoryAveragesValue;
  final VoidCallback? onAddStudent;
  final VoidCallback? onBatchCreateStudents;
  final VoidCallback? onImportStudents;

  @override
  Widget build(BuildContext context) {
    final averages = averagesValue.value ?? const <int, double>{};
    final categoryAverages =
        categoryAveragesValue.value ?? const <int, Map<String, double>>{};

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'students'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: [
                if (onAddStudent != null)
                  FilledButton.tonalIcon(
                    onPressed: onAddStudent,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text('add_student'.tr()),
                  ),
                if (onBatchCreateStudents != null)
                  OutlinedButton.icon(
                    onPressed: onBatchCreateStudents,
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text('batch_create_students'.tr()),
                  ),
                if (onImportStudents != null)
                  OutlinedButton.icon(
                    onPressed: onImportStudents,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text('import_webuntis'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (students.isEmpty)
              Text('empty_students'.tr())
            else
              for (final student in students)
                Builder(
                  builder: (context) {
                    final average = averages[student.id];
                    final perCategory =
                        categoryAverages[student.id] ?? const {};
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.small),
                      child: SurfaceListTile(
                        onTap: () => context.push('/students/${student.id}'),
                        leading: StudentAvatar(student: student),
                        title: Text(
                          studentDisplayName(
                            firstName: student.firstName,
                            lastName: student.lastName,
                            sortField: sortField,
                          ),
                        ),
                        subtitle:
                            student.originNote == null && perCategory.isEmpty
                            ? null
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (student.originNote != null)
                                    Text(student.originNote!),
                                  if (perCategory.isNotEmpty) ...[
                                    if (student.originNote != null)
                                      const SizedBox(height: 6),
                                    Wrap(
                                      spacing: AppSpacing.small,
                                      runSpacing: AppSpacing.small,
                                      children: [
                                        for (final category in categories)
                                          if (perCategory[category.id]
                                              case final value?)
                                            _CategoryAverageChip(
                                              label:
                                                  '${category.name}: ${gradeLabelForNumericValue(value, gradeScaleEntries)}',
                                              color: colorForCategory(category),
                                            ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                        trailing: average == null
                            ? null
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'average'.tr(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  Text(
                                    gradeLabelForNumericValue(
                                      average,
                                      gradeScaleEntries,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAverageChip extends StatelessWidget {
  const _CategoryAverageChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

enum _GroupListAction { edit, archive, unarchive, delete }

enum _GroupNoteAction { edit, toggle, archive, unarchive, delete }
