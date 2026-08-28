import 'dart:math' as math;

import 'package:avatar_maker/avatar_maker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/app_providers.dart';
import '../../shared/avatar/avatar_code.dart';
import '../../shared/avatar/avatar_maker_config.dart';
import '../../shared/utils/formatting.dart';
import 'avatar_helpers.dart';

Future<void> showAvatarEditorSheet({
  required BuildContext context,
  required Student student,
  required Future<void> Function(String? avatarJson) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _AvatarEditorSheet(student: student, onSave: onSave),
  );
}

class _AvatarEditorSheet extends ConsumerStatefulWidget {
  const _AvatarEditorSheet({required this.student, required this.onSave});

  final Student student;
  final Future<void> Function(String? avatarJson) onSave;

  @override
  ConsumerState<_AvatarEditorSheet> createState() => _AvatarEditorSheetState();
}

class _AvatarEditorSheetState extends ConsumerState<_AvatarEditorSheet> {
  late NonPersistentAvatarMakerController _controller;
  late final bool _hasStoredAvatar;
  int _controllerGeneration = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hasStoredAvatar =
        widget.student.avatarJson != null &&
        widget.student.avatarJson!.isNotEmpty;
    _controller = createAvatarMakerController(
      avatarJson: widget.student.avatarJson,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replaceController(NonPersistentAvatarMakerController next) {
    final previous = _controller;
    setState(() {
      _controller = next;
      _controllerGeneration++;
    });
    // Let the widgets keyed to the old generation unmount before the old
    // controller goes away, so their listener teardown does not touch a
    // disposed ChangeNotifier.
    WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final sortField = ref.watch(studentSortFieldProvider);
    final size = MediaQuery.sizeOf(context);
    final customizerWidth = math.min(size.width - 32, 720.0);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: size.height * 0.95,
        child: Scaffold(
          appBar: AppBar(
            title: Text('edit_avatar'.tr()),
            actions: [
              IconButton(
                onPressed: _isSaving ? null : _showCodeDialog,
                icon: const Icon(Icons.keyboard_alt_outlined),
                tooltip: 'avatar_enter_code'.tr(),
              ),
              IconButton(
                onPressed: _isSaving
                    ? null
                    : () => _controller.randomizedSelectedOptions(),
                icon: const Icon(Icons.shuffle),
                tooltip: 'randomize_avatar'.tr(),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  children: [
                    AvatarMakerAvatar(
                      key: ValueKey('avatar-$_controllerGeneration'),
                      controller: _controller,
                      radius: 56,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      studentDisplayName(
                        firstName: widget.student.firstName,
                        lastName: widget.student.lastName,
                        callName: widget.student.callName,
                        sortField: sortField,
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AvatarMakerCustomizer(
                    key: ValueKey('customizer-$_controllerGeneration'),
                    controller: _controller,
                    autosave: false,
                    scaffoldWidth: customizerWidth,
                    scaffoldHeight: size.height * 0.58,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Row(
                  children: [
                    if (_hasStoredAvatar)
                      TextButton(
                        onPressed: _isSaving ? null : _removeAvatar,
                        child: Text('remove_avatar'.tr()),
                      ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr()),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveAvatar,
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('save'.tr()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCodeDialog() async {
    final avatarJson = await showDialog<String>(
      context: context,
      builder: (_) => const _AvatarCodeDialog(),
    );

    if (avatarJson == null || !mounted) return;

    _replaceController(createAvatarMakerController(avatarJson: avatarJson));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('avatar_code_applied'.tr())));
  }

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    await widget.onSave(normalizeAvatarJson(_controller.getJsonOptionsSync()));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isSaving = true);
    await widget.onSave(null);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Prompts for an avatar code and pops the decoded 13-key `avatarJson` string
/// on success, or `null` on cancel.
class _AvatarCodeDialog extends StatefulWidget {
  const _AvatarCodeDialog();

  @override
  State<_AvatarCodeDialog> createState() => _AvatarCodeDialogState();
}

class _AvatarCodeDialogState extends State<_AvatarCodeDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final result = AvatarCode.tryDecode(_controller.text);
    if (result.error != null) {
      setState(() => _error = _localizedError(result.error!));
      return;
    }
    Navigator.of(context).pop(result.avatarJson);
  }

  String _localizedError(AvatarCodeErrorKind kind) {
    return switch (kind) {
      AvatarCodeErrorKind.empty => 'avatar_code_empty'.tr(),
      AvatarCodeErrorKind.unknownPrefix ||
      AvatarCodeErrorKind.malformed => 'avatar_code_invalid'.tr(),
      AvatarCodeErrorKind.unsupportedVersion ||
      AvatarCodeErrorKind.schemaMismatch => 'avatar_code_wrong_version'.tr(),
      AvatarCodeErrorKind.checksumFailed => 'avatar_code_typo'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('avatar_enter_code'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('avatar_code_dialog_body'.tr()),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'avatar_code_field_label'.tr(),
              hintText: 'avatar_code_hint'.tr(),
              errorText: _error,
            ),
            onSubmitted: (_) => _apply(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(onPressed: _apply, child: Text('avatar_code_apply'.tr())),
      ],
    );
  }
}
