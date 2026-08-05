import 'dart:convert';
import 'dart:developer' as developer;
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
import '../groups/group_export_service.dart';
import 'timeframe_editor_sheet.dart';
import 'timeframe_grades_screen.dart';
import '../lists/list_repository.dart';
import '../lists/list_editor.dart';
import '../lessons/lesson_support.dart';
import '../lessons/lesson_widgets.dart';
import '../notes/note_editor.dart';
import '../notes/note_links.dart';
import '../seating_plan/seating_plan_grid.dart';
import '../seating_plan/seating_plan_selector_sheet.dart';
import '../students/student_batch_create_sheet.dart';
import '../students/student_form.dart';
import '../sessions/session_form.dart';
import '../sessions/session_repository.dart';
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

final archivedGroupListsProvider = StreamProvider.autoDispose .family<List<Checklist>, int>(
      (ref, groupId) =>
          ref.watch(listRepositoryProvider).watchArchivedLists(groupId),
    );

final groupListProgressProvider = StreamProvider.autoDispose
    .family<Map<int, ListProgress>, int>(
      (ref, groupId) =>
          ref.watch(listRepositoryProvider).watchListProgress(groupId: groupId),
    );

final groupSessionSummariesProvider = StreamProvider.autoDispose
    .family<List<SessionSummary>, int>(
      (ref, groupId) => ref
          .watch(sessionRepositoryProvider)
          .watchGroupSessionSummaries(groupId),
    );

final groupTimeframesProvider = StreamProvider.autoDispose
    .family<List<Timeframe>, int>(
      (ref, groupId) => ref
          .watch(timeframeRepositoryProvider)
          .watchTimeframes(groupId),
    );

// Providers for timeframe-specific student data
final studentGradesInTimeframeProvider = StreamProvider.autoDispose
    .family<List<GradeEntry>, (int, DateTime, DateTime)>(
      (ref, params) => ref
          .watch(gradeRepositoryProvider)
          .watchGradesForStudentInDateRange(
            params.$1,
            params.$2,
            params.$3,
          ),
    );

final studentAttendanceInTimeframeProvider = StreamProvider.autoDispose
    .family<List<AttendanceLog>, (int, DateTime, DateTime)>(
      (ref, params) => ref
          .watch(attendanceRepositoryProvider)
          .watchAttendanceForStudentInDateRange(
            params.$1,
            params.$2,
            params.$3,
          ),
    );

final studentMaterialInTimeframeProvider = StreamProvider.autoDispose
    .family<List<MaterialLog>, (int, DateTime, DateTime)>(
      (ref, params) => ref
          .watch(materialRepositoryProvider)
          .watchMaterialForStudentInDateRange(
            params.$1,
            params.$2,
            params.$3,
          ),
    );

final studentHomeworkInTimeframeProvider = StreamProvider.autoDispose
    .family<List<HomeworkLog>, (int, DateTime, DateTime)>(
      (ref, params) => ref
          .watch(homeworkRepositoryProvider)
          .watchHomeworkForStudentInDateRange(
            params.$1,
            params.$2,
            params.$3,
          ),
    );

String _lessonModeLocation({
  required int groupId,
  required DateTime date,
  String? categoryId,
}) {
  final normalizedCategoryId = categoryId?.trim();
  return Uri(
    path: '/groups/$groupId/lesson',
    queryParameters: {
      'date': encodeLessonDate(date),
      if (normalizedCategoryId != null && normalizedCategoryId.isNotEmpty)
        'category': normalizedCategoryId,
    },
  ).toString();
}

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
    final sessionSummariesValue = ref.watch(
      groupSessionSummariesProvider(groupId),
    );

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
                onPressed: () => _showExportSheet(context, ref, group.name),
                icon: const Icon(Icons.download_outlined),
                tooltip: 'export'.tr(),
              ),
              IconButton(
                onPressed: () => _editGroup(context, ref, group),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'edit'.tr(),
              ),
            ],
          ),
          floatingActionButton: archived
              ? null
              : LessonCategoryFabMenu(
                  categories: categories,
                  heroTagPrefix: 'group-lesson-$groupId',
                  mainLabel: 'open_lesson_mode'.tr(),
                  mainIcon: Icons.menu_book_outlined,
                  onSelected: (category) => context.push(
                    _lessonModeLocation(
                      groupId: groupId,
                      date: DateTime.now(),
                      categoryId: category.id,
                    ),
                  ),
                ),
          body: ContentConstraints(
            child: SingleChildScrollView(
              padding: appScreenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (archived && archivedDate != null)
                    Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.archive_outlined),
                        title: Text(
                          'archived_banner'.tr(
                            namedArgs: {'date': archivedDate},
                          ),
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
                                backgroundColor: groupColor.withValues(
                                  alpha: 0.18,
                                ),
                                child: CircleAvatar(
                                  radius: 5,
                                  backgroundColor: groupColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  group.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
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
                                avatar: const Icon(
                                  Icons.people_outline,
                                  size: 18,
                                ),
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
                  _TimeframesCard(
                    groupId: group.id,
                    archived: archived,
                    gradeScaleEntries: gradeScaleEntries,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _LessonCalendarCard(
                    groupId: group.id,
                    groupColor: groupColor,
                    categories: categories,
                  ),
                  const SizedBox(height: AppSpacing.large),
                  _SessionsOverviewCard(
                    groupId: group.id,
                    categories: categories,
                    gradeScaleEntries: gradeScaleEntries,
                    sessionSummariesValue: sessionSummariesValue,
                    archived: archived,
                    onAddSession: archived
                        ? null
                        : () =>
                              _addSession(context, ref, group.id, categories),
                    onEditSession: archived
                        ? null
                        : (summary) =>
                              _editSession(context, ref, summary.session),
                    onDeleteSession: archived
                        ? null
                        : (summary) =>
                              _deleteSession(context, ref, summary.session),
                  ),
                  const SizedBox(height: AppSpacing.large),
                  studentsValue.when(
                    data: (loadedStudents) => _StudentsSection(
                      students: loadedStudents,
                      sortField: sortField,
                      gradeScaleEntries: gradeScaleEntries,
                      categories: categories,
                      averagesValue: averagesValue,
                      categoryAveragesValue: categoryAveragesValue,
                      groupId: group.id,
                      onAddStudent: archived
                          ? null
                          : () => _addStudent(context, ref, group.id),
                      onBatchCreateStudents: archived
                          ? null
                          : () => _batchCreateStudents(context, ref, group.id),
                      onImportStudents: archived
                          ? null
                          : () =>
                                _importWebUntisStudents(context, ref, group.id),
                    ),
                    error: (error, _) => const AppErrorText(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
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

    try {
      await ref
          .read(studentRepositoryProvider)
          .addStudent(
            groupId: groupId,
            firstName: result.firstName,
            lastName: result.lastName,
            callName: result.callName,
            originNote: result.originNote,
            avatarJson: result.avatarJson,
          );
      _refreshStudentSection(ref, groupId);
    } catch (e, st) {
      developer.log(
        'Failed to add student',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
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

    try {
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
            'students_created'.tr(
              namedArgs: {'count': drafts.length.toString()},
            ),
          ),
        ),
      );
    } catch (e, st) {
      developer.log(
        'Failed to batch create students',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
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

    try {
      await ref
          .read(listRepositoryProvider)
          .createListWithOptions(
            groupId: group.id,
            name: result.name,
            populateFromGroupStudents: result.populateFromGroupStudents,
            sortField: ref.read(studentSortFieldProvider),
          );
    } catch (e, st) {
      developer.log(
        'Failed to create list',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
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

    try {
      await ref
          .read(noteRepositoryProvider)
          .saveNote(
            body: result.body,
            groupId: result.groupId,
            studentIds: result.studentIds,
            isTodo: result.isTodo,
            createdAt: result.createdAt,
          );
    } catch (e, st) {
      developer.log(
        'Failed to add note',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
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

    try {
      await ref
          .read(listRepositoryProvider)
          .renameList(listId: list.id, name: name);
    } catch (e, st) {
      developer.log(
        'Failed to rename list',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
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
      try {
        await ref.read(listRepositoryProvider).deleteList(list.id);
      } catch (e, st) {
        developer.log(
          'Failed to delete list',
          name: 'classi.group_detail',
          level: 1000,
          error: e,
          stackTrace: st,
        );
        if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
      }
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

    try {
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
    } catch (e, st) {
      developer.log(
        'Failed to update note',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
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
      try {
        await ref.read(noteRepositoryProvider).deleteNote(note.id);
      } catch (e, st) {
        developer.log(
          'Failed to delete note',
          name: 'classi.group_detail',
          level: 1000,
          error: e,
          stackTrace: st,
        );
        if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
      }
    }
  }

  Future<void> _showExportSheet(
    BuildContext context,
    WidgetRef ref,
    String groupName,
  ) async {
    final exportType = await showModalBottomSheet<_ExportType>(
      context: context,
      builder: (ctx) => _ExportSheet(groupName: groupName),
    );
    if (exportType == null || !context.mounted) return;
    final service = ref.read(groupExportServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = switch (exportType) {
        _ExportType.grades => await service.exportGradesCsv(
            groupId: groupId,
            groupName: groupName,
          ),
        _ExportType.attendance => await service.exportAttendanceCsv(
            groupId: groupId,
            groupName: groupName,
          ),
        _ExportType.homeworkMaterial => await service.exportHomeworkMaterialCsv(
            groupId: groupId,
            groupName: groupName,
          ),
        _ExportType.summary => await service.exportSummaryCsv(
            groupId: groupId,
            groupName: groupName,
          ),
      };
      if (!context.mounted) return;
      final session = ref.read(appSessionProvider);
      final saved = await shareOrSaveFile(
        file: result.file,
        filename: result.filename,
        mimeType: 'text/csv',
        subject: result.filename,
        savePathResolver: () async {
          session.suspendBackgroundLock();
          try {
            return await FilePicker.saveFile(
              fileName: result.filename,
              type: FileType.custom,
              allowedExtensions: ['csv'],
            );
          } finally {
            session.resumeBackgroundLock();
          }
        },
      );
      if (saved && context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('export_success'.tr())),
        );
      }
    } catch (e, st) {
      developer.log(
        'Export failed',
        name: 'classi.group_detail',
        error: e,
        stackTrace: st,
      );
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('export_failed'.tr())),
        );
      }
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

    try {
      await ref
          .read(groupRepositoryProvider)
          .updateGroup(
            id: group.id,
            name: result.name,
            colorHex: result.colorHex,
            gradeScale: result.gradeScale,
            gradeCategories: result.gradeCategories,
          );
    } catch (e, st) {
      developer.log(
        'Failed to edit group',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
  }

  Future<void> _addSession(
    BuildContext context,
    WidgetRef ref,
    int groupId,
    List<GradeCategory> categories,
  ) async {
    final result = await showSessionFormSheet(
      context: context,
      gradeCategories: categories,
      title: 'add_session'.tr(),
    );
    if (result == null) return;

    try {
      await ref
          .read(sessionRepositoryProvider)
          .upsertSession(
            groupId: groupId,
            date: result.date,
            categoryId: result.categoryId,
            categoryName: result.categoryName,
            label: result.label,
            description: result.description,
          );
    } catch (e, st) {
      developer.log(
        'Failed to add session',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
  }

  Future<void> _editSession(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final result = await showSessionFormSheet(
      context: context,
      gradeCategories: const [],
      initialDate: session.date,
      initialLabel: session.label,
      initialDescription: session.description,
      initialCategoryId: session.categoryId,
      title: 'edit_session'.tr(),
    );
    if (result == null) return;

    try {
      await ref
          .read(sessionRepositoryProvider)
          .updateSession(
            id: session.id,
            label: result.label,
            description: result.description,
          );
    } catch (e, st) {
      developer.log(
        'Failed to edit session',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete'.tr(
        namedArgs: {
          'name': session.label.isEmpty ? session.categoryName : session.label,
        },
      ),
      body: 'confirm_delete_session_body'.tr(),
    );
    if (!confirmed) return;

    try {
      await ref.read(sessionRepositoryProvider).deleteSession(session.id);
    } catch (e, st) {
      developer.log(
        'Failed to delete session',
        name: 'classi.group_detail',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (context.mounted) showErrorSnackBar(context, 'generic_error'.tr());
    }
  }
}

class _TimeframesCard extends ConsumerWidget {
  const _TimeframesCard({
    required this.groupId,
    required this.archived,
    required this.gradeScaleEntries,
  });

  final int groupId;
  final bool archived;
  final List<GradeScaleEntry> gradeScaleEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframesValue = ref.watch(groupTimeframesProvider(groupId));

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
                    'timeframes'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!archived)
                  FilledButton.tonal(
                    onPressed: () => _addTimeframe(context, ref, groupId),
                    child: Text('add_timeframe'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            timeframesValue.when(
              data: (timeframes) => timeframes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.large,
                        ),
                        child: Text(
                          'no_timeframes'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  : _TimeframesTable(
                      timeframes: timeframes,
                      allTimeframes: timeframes,
                      gradeScaleEntries: gradeScaleEntries,
                      archived: archived,
                    ),
              error: (e, s) => const AppErrorText(),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addTimeframe(
    BuildContext context,
    WidgetRef ref,
    int groupId,
  ) async {
    final result = await showTimeframeEditorSheet(
      context: context,
      groupId: groupId,
      timeframeRepository: ref.read(timeframeRepositoryProvider),
    );
    if (result != null) {
      await ref.read(timeframeRepositoryProvider).saveTimeframe(
            groupId: groupId,
            label: result.label,
            startDate: result.startDate,
            endDate: result.endDate,
          );
    }
  }
}

class _TimeframesTable extends ConsumerWidget {
  const _TimeframesTable({
    required this.timeframes,
    required this.allTimeframes,
    required this.gradeScaleEntries,
    required this.archived,
  });

  final List<Timeframe> timeframes;
  final List<Timeframe> allTimeframes;
  final List<GradeScaleEntry> gradeScaleEntries;
  final bool archived;

  String _formatPercent(int count, int total) {
    if (total == 0) return '–';
    return '${(count / total * 100).round()}%';
  }

  String _avgFinalGrade(List<TimeframeGrade> grades) {
    if (grades.isEmpty) return '–';
    final values = grades
        .map((g) => gradeValueToNumber(g.grade, gradeScaleEntries))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return grades.first.grade;
    final avg = values.reduce((a, b) => a + b) / values.length;
    return gradeLabelForNumericValue(avg, gradeScaleEntries);
  }

  List<Timeframe> _findOverlaps(Timeframe target, List<Timeframe> all) {
    return [
      for (final t in all)
        if (t.id != target.id &&
            t.startDate
                .isBefore(target.endDate.add(const Duration(days: 1))) &&
            t.endDate
                .isAfter(target.startDate.subtract(const Duration(days: 1))))
          t,
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const _TimeframesTableHeader(),
        const Divider(height: 1),
        for (var i = 0; i < timeframes.length; i++) ...[
          _buildRow(context, ref, timeframes[i]),
          if (i < timeframes.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, Timeframe timeframe) {
    final params = (
      groupId: timeframe.groupId,
      startDate: timeframe.startDate,
      endDate: timeframe.endDate,
    );
    final gradesValue = ref.watch(timeframeGradesProvider(timeframe.id));
    final attendanceValue = ref.watch(timeframeAttendanceProvider(params));
    final materialValue = ref.watch(timeframeMaterialProvider(params));
    final homeworkValue = ref.watch(timeframeHomeworkProvider(params));

    final grades = gradesValue.asData?.value ?? [];
    final attendanceLogs = attendanceValue.asData?.value ?? {};
    final materialLogs = materialValue.asData?.value ?? {};
    final homeworkLogs = homeworkValue.asData?.value ?? {};

    final allAttendance = attendanceLogs.values.expand((l) => l).toList();
    final allMaterial = materialLogs.values.expand((l) => l).toList();
    final allHomework = homeworkLogs.values.expand((l) => l).toList();

    final presentCount = allAttendance.where((l) => !l.isAbsent).length;
    final hadMaterialCount = allMaterial.where((l) => l.hadMaterial).length;
    final hadHomeworkCount = allHomework.where((l) => l.hadHomework).length;

    final overlaps = _findOverlaps(timeframe, allTimeframes);
    final hasOverlap = overlaps.isNotEmpty;

    return InkWell(
      onTap: () => _viewTimeframeGrades(context, timeframe),
      child: Container(
        color: hasOverlap
            ? Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.15)
            : null,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Row(
          children: [
            _TimeframesTableCell(
              flex: 3,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      timeframe.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasOverlap)
                    Tooltip(
                      message: 'overlaps_with'.tr(namedArgs: {
                        'timeframes': overlaps
                            .map((t) =>
                                '${t.label} (${formatShortDate(t.startDate)} – ${formatShortDate(t.endDate)})')
                            .join(', '),
                      }),
                      child: Icon(
                        Icons.warning_amber_outlined,
                        color: Theme.of(context).colorScheme.error,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
            _TimeframesTableCell(
              flex: 2,
              child: Text(
                formatShortDate(timeframe.startDate),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TimeframesTableCell(
              flex: 2,
              child: Text(
                formatShortDate(timeframe.endDate),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TimeframesTableCell(
              flex: 1,
              child: Text(
                _avgFinalGrade(grades),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TimeframesTableCell(
              flex: 1,
              child: Text(
                _formatPercent(presentCount, allAttendance.length),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TimeframesTableCell(
              flex: 1,
              child: Text(
                _formatPercent(hadMaterialCount, allMaterial.length),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _TimeframesTableCell(
              flex: 1,
              child: Text(
                _formatPercent(hadHomeworkCount, allHomework.length),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _viewTimeframeGrades(
    BuildContext context,
    Timeframe timeframe,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TimeframeGradesScreen(timeframe: timeframe),
      ),
    );
  }
}

/// Header row for [_TimeframesTable]. A plain [Row] of [Expanded] cells
/// instead of [DataTable] so it never needs to scroll horizontally: cells
/// share the available width and truncate with an ellipsis rather than
/// wrapping or forcing the table wider than its container.
class _TimeframesTableHeader extends StatelessWidget {
  const _TimeframesTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    Widget cell(String key, int flex, {TextAlign align = TextAlign.center}) {
      return _TimeframesTableCell(
        flex: flex,
        child: Text(
          key.tr(),
          style: style,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          cell('timeframe_label', 3, align: TextAlign.start),
          cell('start_date', 2),
          cell('end_date', 2),
          cell('average', 1),
          cell('attendance', 1),
          cell('material', 1),
          cell('homework', 1),
        ],
      ),
    );
  }
}

class _TimeframesTableCell extends StatelessWidget {
  const _TimeframesTableCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
    );
  }
}

class _LessonCalendarCard extends ConsumerStatefulWidget {
  const _LessonCalendarCard({
    required this.groupId,
    required this.groupColor,
    required this.categories,
  });

  final int groupId;
  final Color groupColor;
  final List<GradeCategory> categories;

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
    final lessonEntryCategoriesValue = ref.watch(
      lessonEntryCategoriesProvider(widget.groupId),
    );
    final lessonEntryCategories =
        lessonEntryCategoriesValue.value ?? const <DateTime, Set<String>>{};

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
                    _lessonModeLocation(
                      groupId: widget.groupId,
                      date: DateTime.now(),
                    ),
                  ),
                  child: Text('today'.tr()),
                ),
                const SizedBox(width: AppSpacing.medium),
                if (lessonEntryCategoriesValue.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            TableCalendar<String>(
              locale: context.locale.toLanguageTag(),
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => [
                for (final category in _categoriesForDay(
                  lessonEntryCategories: lessonEntryCategories,
                  day: day,
                ))
                  category.id,
              ],
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders<String>(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) {
                    return null;
                  }

                  final categoriesForDay = _categoriesForDay(
                    lessonEntryCategories: lessonEntryCategories,
                    day: day,
                  );
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 4,
                        children: [
                          for (final category in categoriesForDay)
                            _LessonCalendarMarker(
                              color: colorForCategoryId(
                                categoryId: category.id,
                                categories: widget.categories,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                canMarkersOverflow: false,
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
              onDaySelected: (selectedDay, focusedDay) async {
                final normalizedSelectedDay = normalizeLessonDate(selectedDay);
                setState(() {
                  _selectedDay = normalizedSelectedDay;
                  _focusedDay = normalizeLessonDate(focusedDay);
                });
                await _openLessonForDay(
                  context: context,
                  selectedDay: normalizedSelectedDay,
                  lessonEntryCategories: lessonEntryCategories,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<GradeCategory> _categoriesForDay({
    required Map<DateTime, Set<String>> lessonEntryCategories,
    required DateTime day,
  }) {
    final categoryIds =
        lessonEntryCategories[normalizeLessonDate(day)] ?? const <String>{};
    final categoriesById = {
      for (final category in widget.categories) category.id: category,
    };
    final categories = <GradeCategory>[
      for (final category in widget.categories)
        if (categoryIds.contains(category.id)) category,
    ];

    for (final categoryId in categoryIds) {
      if (categoriesById.containsKey(categoryId)) {
        continue;
      }
      categories.add(
        GradeCategory(
          id: categoryId,
          name: categoryNameFor(
            categoryId: categoryId,
            categories: widget.categories,
          ),
          weight: 1,
          colorHex: colorToHex(
            colorForCategoryId(
              categoryId: categoryId,
              categories: widget.categories,
            ),
          ),
        ),
      );
    }

    return categories;
  }

  Future<void> _openLessonForDay({
    required BuildContext context,
    required DateTime selectedDay,
    required Map<DateTime, Set<String>> lessonEntryCategories,
  }) async {
    final categoriesForDay = _categoriesForDay(
      lessonEntryCategories: lessonEntryCategories,
      day: selectedDay,
    );
    String? categoryId;

    if (categoriesForDay.length == 1) {
      categoryId = categoriesForDay.single.id;
    } else if (categoriesForDay.length > 1) {
      final selectedCategory = await showDialog<GradeCategory>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('grade_category'.tr()),
          contentPadding: const EdgeInsets.fromLTRB(0, AppSpacing.medium, 0, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in categoriesForDay)
                ListTile(
                  leading: _LessonCalendarMarker(
                    color: colorForCategoryId(
                      categoryId: category.id,
                      categories: widget.categories,
                    ),
                    size: 12,
                  ),
                  title: Text(category.name),
                  onTap: () => Navigator.of(dialogContext).pop(category),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr()),
            ),
          ],
        ),
      );
      if (selectedCategory == null || !context.mounted) {
        return;
      }
      categoryId = selectedCategory.id;
    }

    context.push(
      _lessonModeLocation(
        groupId: widget.groupId,
        date: selectedDay,
        categoryId: categoryId,
      ),
    );
  }
}

class _LessonCalendarMarker extends StatelessWidget {
  const _LessonCalendarMarker({required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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

enum _StudentViewMode { list, seatingPlan }

class _StudentsSection extends ConsumerStatefulWidget {
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
    required this.groupId,
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
  final int groupId;

  @override
  ConsumerState<_StudentsSection> createState() => _StudentsSectionState();
}

class _StudentsSectionState extends ConsumerState<_StudentsSection> {
  _StudentViewMode _viewMode = _StudentViewMode.list;
  SeatingPlan? _activePlan;
  bool _editMode = false;

  Future<void> _ensureActivePlan() async {
    final repo = ref.read(seatingPlanRepositoryProvider);
    var plan = await repo.getDefaultOrFirstPlan(widget.groupId);
    if (plan == null) {
      final id = await repo.createPlan(
        groupId: widget.groupId,
        name: 'default_seating_plan_name'.tr(),
        columns: 6,
      );
      final plans = await repo.watchPlansForGroup(widget.groupId).first;
      plan = plans.where((p) => p.id == id).firstOrNull;
    }
    if (plan == null || !mounted) return;
    setState(() {
      final planChanged = _activePlan?.id != plan!.id;
      _activePlan = plan;
      if (planChanged) _editMode = false;
    });
    await repo.initializePositionsForPlan(
      planId: plan.id,
      students: widget.students,
      columns: plan.columns,
    );
  }

  Future<void> _openPlanSelector(BuildContext context) async {
    final selected = await showSeatingPlanSelectorSheet(
      context: context,
      groupId: widget.groupId,
      activePlan: _activePlan,
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _activePlan = selected;
        _editMode = false;
      });
      await ref
          .read(seatingPlanRepositoryProvider)
          .initializePositionsForPlan(
            planId: selected.id,
            students: widget.students,
            columns: selected.columns,
          );
    } else {
      // The active plan may have been deleted — reload the next available plan.
      await _ensureActivePlan();
    }
  }

  @override
  Widget build(BuildContext context) {
    final averages = widget.averagesValue.value ?? const <int, double>{};
    final categoryAverages =
        widget.categoryAveragesValue.value ??
        const <int, Map<String, double>>{};

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
                if (widget.students.isNotEmpty)
                  SegmentedButton<_StudentViewMode>(
                    segments: [
                      ButtonSegment(
                        value: _StudentViewMode.list,
                        icon: const Icon(Icons.list),
                        tooltip: 'list_view'.tr(),
                      ),
                      ButtonSegment(
                        value: _StudentViewMode.seatingPlan,
                        icon: const Icon(Icons.grid_view_outlined),
                        tooltip: 'seating_plan'.tr(),
                      ),
                    ],
                    selected: {_viewMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      final mode = selection.first;
                      setState(() => _viewMode = mode);
                      if (mode == _StudentViewMode.seatingPlan &&
                          _activePlan == null) {
                        _ensureActivePlan();
                      }
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (_viewMode == _StudentViewMode.list) ...[
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  if (widget.onAddStudent != null)
                    FilledButton.tonalIcon(
                      onPressed: widget.onAddStudent,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text('add_student'.tr()),
                    ),
                  if (widget.onBatchCreateStudents != null)
                    OutlinedButton.icon(
                      onPressed: widget.onBatchCreateStudents,
                      icon: const Icon(Icons.group_add_outlined),
                      label: Text('batch_create_students'.tr()),
                    ),
                  if (widget.onImportStudents != null)
                    OutlinedButton.icon(
                      onPressed: widget.onImportStudents,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text('import_webuntis'.tr()),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              if (widget.students.isEmpty)
                Text('empty_students'.tr())
              else
                for (final student in widget.students)
                  Builder(
                    builder: (context) {
                      final average = averages[student.id];
                      final perCategory =
                          categoryAverages[student.id] ?? const {};
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: SurfaceListTile(
                          onTap: () => context.push('/students/${student.id}'),
                          leading: StudentAvatar(student: student),
                          title: Text(
                            studentDisplayName(
                              firstName: student.firstName,
                              lastName: student.lastName,
                              callName: student.callName,
                              sortField: widget.sortField,
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
                                          for (final category
                                              in widget.categories)
                                            if (perCategory[category.id]
                                                case final value?)
                                              _CategoryAverageChip(
                                                label:
                                                    '${category.name}: ${gradeLabelForNumericValue(value, widget.gradeScaleEntries)}',
                                                color: colorForCategory(
                                                  category,
                                                ),
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
                                        widget.gradeScaleEntries,
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
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _activePlan?.name ?? 'seating_plan'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_activePlan != null)
                        IconButton(
                          icon: Icon(
                            _editMode ? Icons.check : Icons.edit_outlined,
                          ),
                          tooltip: _editMode ? 'done'.tr() : 'edit_layout'.tr(),
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              setState(() => _editMode = !_editMode),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => _openPlanSelector(context),
                        icon: const Icon(Icons.tune_outlined, size: 18),
                        label: Text('seating_plans'.tr()),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              if (_activePlan == null)
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () => _openPlanSelector(context),
                    icon: const Icon(Icons.add),
                    label: Text('add_seating_plan'.tr()),
                  ),
                )
              else
                _SeatingPlanView(
                  plan: _activePlan!,
                  students: widget.students,
                  editMode: _editMode,
                  onChipTap: (student) =>
                      context.push('/students/${student.id}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeatingPlanView extends ConsumerWidget {
  const _SeatingPlanView({
    required this.plan,
    required this.students,
    required this.editMode,
    required this.onChipTap,
  });

  final SeatingPlan plan;
  final List<Student> students;
  final bool editMode;
  final void Function(Student student) onChipTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionsValue = ref.watch(seatingPlanPositionsProvider(plan.id));
    final positions =
        positionsValue.value ?? const <int, ({int col, int row})>{};

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.small),
      child: SeatingPlanGrid(
        students: students,
        columns: plan.columns,
        positions: positions,
        editMode: editMode,
        onChipTap: onChipTap,
        onPositionChanged: (studentId, col, row) {
          ref
              .read(seatingPlanRepositoryProvider)
              .moveStudent(
                planId: plan.id,
                studentId: studentId,
                col: col,
                row: row,
              );
        },
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

// ---------------------------------------------------------------------------
// Sessions overview card
// ---------------------------------------------------------------------------

class _SessionsOverviewCard extends StatelessWidget {
  const _SessionsOverviewCard({
    required this.groupId,
    required this.categories,
    required this.gradeScaleEntries,
    required this.sessionSummariesValue,
    required this.archived,
    required this.onAddSession,
    required this.onEditSession,
    required this.onDeleteSession,
  });

  final int groupId;
  final List<GradeCategory> categories;
  final List<GradeScaleEntry> gradeScaleEntries;
  final AsyncValue<List<SessionSummary>> sessionSummariesValue;
  final bool archived;
  final VoidCallback? onAddSession;
  final ValueChanged<SessionSummary>? onEditSession;
  final ValueChanged<SessionSummary>? onDeleteSession;

  @override
  Widget build(BuildContext context) {
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
                    'sessions_overview'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onAddSession != null)
                  FilledButton.tonal(
                    onPressed: onAddSession,
                    child: Text('plan_session'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            sessionSummariesValue.when(
              data: (summaries) => summaries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.large,
                        ),
                        child: Text(
                          'no_sessions'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    )
                  : _SessionsTable(
                      groupId: groupId,
                      summaries: summaries,
                      categories: categories,
                      gradeScaleEntries: gradeScaleEntries,
                      onEdit: onEditSession,
                      onDelete: onDeleteSession,
                    ),
              error: (e, s) => const AppErrorText(),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsTable extends StatelessWidget {
  const _SessionsTable({
    required this.groupId,
    required this.summaries,
    required this.categories,
    required this.gradeScaleEntries,
    required this.onEdit,
    required this.onDelete,
  });

  final int groupId;
  final List<SessionSummary> summaries;
  final List<GradeCategory> categories;
  final List<GradeScaleEntry> gradeScaleEntries;
  final ValueChanged<SessionSummary>? onEdit;
  final ValueChanged<SessionSummary>? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SessionsTableHeader(),
        const Divider(height: 1),
        for (var i = 0; i < summaries.length; i++) ...[
          _buildRow(context, summaries[i]),
          if (i < summaries.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _buildRow(BuildContext context, SessionSummary summary) {
    final session = summary.session;
    final locale = context.locale.toLanguageTag();

    return InkWell(
      onTap: () => context.push(
        _lessonModeLocation(
          groupId: groupId,
          date: session.date,
          categoryId: session.categoryId,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Row(
          children: [
            _SessionsTableCell(
              flex: 2,
              child: Text(
                DateFormat.yMMMd(locale).format(session.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _SessionsTableCell(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (session.label.isNotEmpty)
                    Text(
                      session.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'no_label'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (session.description != null &&
                      session.description!.isNotEmpty)
                    Text(
                      session.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _SessionsTableCell(
              flex: 2,
              child: Text(
                session.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _SessionsTableCell(
              flex: 1,
              child: _PercentCell(value: summary.attendancePercent),
            ),
            _SessionsTableCell(
              flex: 1,
              child: _PercentCell(value: summary.homeworkPercent),
            ),
            _SessionsTableCell(
              flex: 1,
              child: _PercentCell(value: summary.materialPercent),
            ),
            _SessionsTableCell(
              flex: 1,
              child: summary.gradeMean != null
                  ? Text(
                      formatNumber(summary.gradeMean!),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const Text('–', textAlign: TextAlign.center),
            ),
            SizedBox(
              width: 40,
              child: _SessionRowActions(
                summary: summary,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header row for [_SessionsTable]. A plain [Row] of [Expanded] cells
/// instead of [DataTable] so it never needs to scroll horizontally: cells
/// share the available width and truncate with an ellipsis rather than
/// wrapping or forcing the table wider than its container.
class _SessionsTableHeader extends StatelessWidget {
  const _SessionsTableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700);
    Widget cell(String key, int flex, {TextAlign align = TextAlign.center}) {
      return _SessionsTableCell(
        flex: flex,
        child: Text(
          key.tr(),
          style: style,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          cell('date', 2, align: TextAlign.start),
          cell('session_label', 3, align: TextAlign.start),
          cell('grade_category', 2, align: TextAlign.start),
          cell('attendance', 1),
          cell('homework', 1),
          cell('material', 1),
          cell('grade', 1),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SessionsTableCell extends StatelessWidget {
  const _SessionsTableCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: child,
      ),
    );
  }
}

class _PercentCell extends StatelessWidget {
  const _PercentCell({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const Text('–');
    return Text('${value!.toStringAsFixed(0)} %');
  }
}

class _SessionRowActions extends StatelessWidget {
  const _SessionRowActions({
    required this.summary,
    required this.onEdit,
    required this.onDelete,
  });

  final SessionSummary summary;
  final ValueChanged<SessionSummary>? onEdit;
  final ValueChanged<SessionSummary>? onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SessionAction>(
      onSelected: (action) {
        switch (action) {
          case _SessionAction.edit:
            onEdit?.call(summary);
          case _SessionAction.delete:
            onDelete?.call(summary);
        }
      },
      itemBuilder: (_) => [
        if (onEdit != null)
          PopupMenuItem(
            value: _SessionAction.edit,
            child: Text('edit_session'.tr()),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: _SessionAction.delete,
            child: Text('delete_session'.tr()),
          ),
      ],
    );
  }
}

enum _SessionAction { edit, delete }

enum _ExportType { grades, attendance, homeworkMaterial, summary }

class _ExportSheet extends StatelessWidget {
  const _ExportSheet({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'export'.tr(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text('export_grades'.tr()),
          onTap: () => Navigator.pop(context, _ExportType.grades),
        ),
        ListTile(
          leading: const Icon(Icons.how_to_reg_outlined),
          title: Text('export_attendance'.tr()),
          onTap: () => Navigator.pop(context, _ExportType.attendance),
        ),
        ListTile(
          leading: const Icon(Icons.checklist_outlined),
          title: Text('export_homework_material'.tr()),
          onTap: () => Navigator.pop(context, _ExportType.homeworkMaterial),
        ),
        ListTile(
          leading: const Icon(Icons.summarize_outlined),
          title: Text('export_summary'.tr()),
          onTap: () => Navigator.pop(context, _ExportType.summary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
