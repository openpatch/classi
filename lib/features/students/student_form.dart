import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/student_avatar.dart';
import '../avatar/avatar_editor_sheet.dart';
import 'student_draft.dart';

typedef StudentFormResult = StudentDraft;

Future<StudentFormResult?> showStudentFormSheet({
  required BuildContext context,
  String? initialFirstName,
  String? initialLastName,
  String? initialOriginNote,
  String? initialAvatarJson,
  String? title,
  Future<void> Function()? onDelete,
}) {
  return showModalBottomSheet<StudentFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _StudentFormSheet(
      initialFirstName: initialFirstName,
      initialLastName: initialLastName,
      initialOriginNote: initialOriginNote,
      initialAvatarJson: initialAvatarJson,
      title: title,
      onDelete: onDelete,
    ),
  );
}

class _StudentFormSheet extends ConsumerStatefulWidget {
  const _StudentFormSheet({
    this.initialFirstName,
    this.initialLastName,
    this.initialOriginNote,
    this.initialAvatarJson,
    this.title,
    this.onDelete,
  });

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialOriginNote;
  final String? initialAvatarJson;
  final String? title;
  final Future<void> Function()? onDelete;

  @override
  ConsumerState<_StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends ConsumerState<_StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _originNoteController;
  late String? _avatarJson;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.initialFirstName);
    _lastNameController = TextEditingController(text: widget.initialLastName);
    _originNoteController = TextEditingController(
      text: widget.initialOriginNote,
    );
    _avatarJson = widget.initialAvatarJson;
    _firstNameController.addListener(_handleNameChanged);
    _lastNameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_handleNameChanged);
    _lastNameController.removeListener(_handleNameChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _originNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'add_student'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: StudentAvatar(student: _previewStudent, size: 52),
                  title: Text('edit_avatar'.tr()),
                  subtitle: Text(
                    studentDisplayNameWithOrigin(
                      firstName: _previewStudent.firstName.isEmpty
                          ? '...'
                          : _previewStudent.firstName,
                      lastName: _previewStudent.lastName.isEmpty
                          ? '...'
                          : _previewStudent.lastName,
                      originNote: _previewStudent.originNote,
                      sortField: sortField,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editAvatar,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'first_name'.tr(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'first_name'.tr()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'last_name'.tr(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'last_name'.tr()
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _originNoteController,
                        decoration: InputDecoration(
                          labelText: 'origin_note'.tr(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (widget.onDelete != null) ...[
                    TextButton(
                      onPressed: _delete,
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                      child: Text('delete'.tr()),
                    ),
                  ],
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _save, child: Text('save'.tr())),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Student get _previewStudent => Student(
    id: 0,
    firstName: _firstNameController.text.trim(),
    lastName: _lastNameController.text.trim(),
    groupId: 0,
    originNote: _originNoteController.text.trim().isEmpty
        ? null
        : _originNoteController.text.trim(),
    createdAt: DateTime.now(),
    avatarJson: _avatarJson,
  );

  void _handleNameChanged() {
    setState(() {});
  }

  Future<void> _editAvatar() {
    return showAvatarEditorSheet(
      context: context,
      student: _previewStudent,
      onSave: (avatarJson) async {
        setState(() => _avatarJson = avatarJson);
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop((
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      originNote: _originNoteController.text.trim().isEmpty
          ? null
          : _originNoteController.text.trim(),
      avatarJson: _avatarJson,
    ));
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'confirm_delete'.tr(
        namedArgs: {
          'name': studentDisplayName(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
          ),
        },
      ),
      body: 'confirm_delete_student_body'.tr(),
    );
    if (!confirmed || !mounted) {
      return;
    }
    await widget.onDelete!();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}
