import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/utils/grade_categories.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/student_link_chip.dart';
import '../../shared/widgets/swipe_action_background.dart';
import '../groups/groups_screen.dart';
import 'note_editor.dart';
import 'note_links.dart';
import 'note_repository.dart';

final allNotesProvider = StreamProvider.autoDispose<List<TeacherNote>>(
  (ref) => ref.watch(noteRepositoryProvider).watchNotes(NoteFilter.all),
);

final todoNotesProvider = StreamProvider.autoDispose<List<TeacherNote>>(
  (ref) => ref.watch(noteRepositoryProvider).watchNotes(NoteFilter.todos),
);

final doneNotesProvider = StreamProvider.autoDispose<List<TeacherNote>>(
  (ref) => ref.watch(noteRepositoryProvider).watchNotes(NoteFilter.done),
);

final archivedNotesProvider = StreamProvider.autoDispose<List<TeacherNote>>(
  (ref) => ref.watch(noteRepositoryProvider).watchArchivedNotes(),
);

final allStudentsProvider = StreamProvider.autoDispose<List<Student>>(
  (ref) => ref
      .watch(studentRepositoryProvider)
      .watchAllStudents(sortField: ref.watch(studentSortFieldProvider)),
);

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  @override
  Widget build(BuildContext context) {
    final groupsValue = ref.watch(activeGroupsProvider);
    final studentsValue = ref.watch(allStudentsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('notes'.tr()),
          bottom: TabBar(
            tabs: [
              Tab(text: 'all'.tr()),
              Tab(text: 'todos'.tr()),
              Tab(text: 'done'.tr()),
              Tab(text: 'archived'.tr()),
            ],
          ),
        ),
        floatingActionButton: groupsValue.hasValue && studentsValue.hasValue
            ? FloatingActionButton.extended(
                onPressed: () => _addNote(
                  context,
                  groupsValue.value ?? const [],
                  studentsValue.value ?? const [],
                ),
                icon: const Icon(Icons.add),
                label: Text('new_note'.tr()),
              )
            : null,
        body: TabBarView(
          children: [
            _NotesList(provider: allNotesProvider, emptyKey: 'empty_notes'),
            _NotesList(provider: todoNotesProvider, emptyKey: 'empty_notes'),
            _NotesList(provider: doneNotesProvider, emptyKey: 'empty_notes'),
            _NotesList(
              provider: archivedNotesProvider,
              emptyKey: 'empty_notes',
              archived: true,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNote(
    BuildContext context,
    List<Group> groups,
    List<Student> students,
  ) async {
    final result = await showNoteEditorSheet(
      context: context,
      groups: groups,
      students: students,
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
}

class _NotesList extends ConsumerWidget {
  const _NotesList({
    required this.provider,
    required this.emptyKey,
    this.archived = false,
  });

  final StreamProvider<List<TeacherNote>> provider;
  final String emptyKey;
  final bool archived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesValue = ref.watch(provider);
    final studentsValue = ref.watch(allStudentsProvider);
    final groupsValue = ref.watch(activeGroupsProvider);

    return notesValue.when(
      data: (notes) {
        if (notes.isEmpty) {
          return EmptyState(
            icon: Icons.sticky_note_2_outlined,
            title: emptyKey.tr(),
          );
        }

        final students = {
          for (final student in studentsValue.value ?? const <Student>[])
            student.id: student,
        };
        final groups = {
          for (final group in groupsValue.value ?? const <Group>[])
            group.id: group,
        };
        final groupList = groupsValue.value ?? const <Group>[];
        final studentList = studentsValue.value ?? const <Student>[];
        final dateFormat = DateFormat.yMMMd(context.locale.toLanguageTag());

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final note = notes[index];
            final linkedStudents = [
              for (final studentId in noteStudentIds(note))
                if (students[studentId] != null) students[studentId]!,
            ];
            final linkedGroup = note.groupId == null
                ? null
                : groups[note.groupId];

            final noteCard = Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.xLarge),
                onTap: () => _handleAction(
                  context,
                  ref,
                  _NoteAction.edit,
                  note,
                  groupList,
                  studentList,
                ),
                child: Padding(
                  padding: appCardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              note.body,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          PopupMenuButton<_NoteAction>(
                            onSelected: (action) => _handleAction(
                              context,
                              ref,
                              action,
                              note,
                              groupList,
                              studentList,
                            ),
                            itemBuilder: (_) => [
                              if (!archived)
                                PopupMenuItem(
                                  value: _NoteAction.edit,
                                  child: Text('edit'.tr()),
                                ),
                              if (!archived && note.isTodo)
                                PopupMenuItem(
                                  value: _NoteAction.toggle,
                                  child: Text(
                                    note.todoDone ? 'todo'.tr() : 'done'.tr(),
                                  ),
                                ),
                              PopupMenuItem(
                                value: archived
                                    ? _NoteAction.unarchive
                                    : _NoteAction.archive,
                                child: Text(
                                  archived ? 'unarchive'.tr() : 'archive'.tr(),
                                ),
                              ),
                              PopupMenuItem(
                                value: _NoteAction.delete,
                                child: Text('delete'.tr()),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: AppSpacing.small,
                        children: [
                          if (linkedGroup != null)
                            Builder(
                              builder: (context) {
                                final groupColor = colorFromHex(
                                  linkedGroup.colorHex,
                                );
                                return ActionChip(
                                  avatar: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: groupColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  backgroundColor: groupColor.withValues(
                                    alpha: 0.16,
                                  ),
                                  side: BorderSide(
                                    color: groupColor.withValues(alpha: 0.4),
                                  ),
                                  label: Text(
                                    linkedGroup.name,
                                    style: TextStyle(color: groupColor),
                                  ),
                                  onPressed: () =>
                                      context.go('/groups/${linkedGroup.id}'),
                                );
                              },
                            ),
                          for (final linkedStudent in linkedStudents)
                            StudentLinkChip(
                              student: linkedStudent,
                              avatarSize: 24,
                            ),
                          if (note.isTodo)
                            Chip(
                              label: Text(
                                note.todoDone ? 'done'.tr() : 'todo'.tr(),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Text(dateFormat.format(note.createdAt)),
                    ],
                  ),
                ),
              ),
            );

            if (archived) {
              return noteCard;
            }

            return Dismissible(
              key: ValueKey('global-note-${note.id}'),
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
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
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
                    ref.read(noteRepositoryProvider).archiveNote(note.id);
                    return;
                  case DismissDirection.endToStart:
                    ref.read(noteRepositoryProvider).deleteNote(note.id);
                    return;
                  case DismissDirection.none:
                  case DismissDirection.down:
                  case DismissDirection.up:
                  case DismissDirection.horizontal:
                  case DismissDirection.vertical:
                    return;
                }
              },
              child: noteCard,
            );
          },
        );
      },
      error: (error, _) => const AppErrorState(),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _NoteAction action,
    TeacherNote note,
    List<Group> groups,
    List<Student> students,
  ) async {
    switch (action) {
      case _NoteAction.edit:
        final result = await showNoteEditorSheet(
          context: context,
          groups: groups,
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
        return;
      case _NoteAction.toggle:
        await ref.read(noteRepositoryProvider).toggleTodo(note, !note.todoDone);
        return;
      case _NoteAction.delete:
        final confirmed = await showConfirmDialog(
          context: context,
          title: 'confirm_delete'.tr(namedArgs: {'name': 'note_body'.tr()}),
          body: note.body,
        );
        if (confirmed) {
          await ref.read(noteRepositoryProvider).deleteNote(note.id);
        }
        return;
      case _NoteAction.archive:
        await ref.read(noteRepositoryProvider).archiveNote(note.id);
        return;
      case _NoteAction.unarchive:
        await ref.read(noteRepositoryProvider).unarchiveNote(note.id);
        return;
    }
  }
}

enum _NoteAction { edit, toggle, archive, unarchive, delete }
