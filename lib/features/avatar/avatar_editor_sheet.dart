import 'dart:math' as math;

import 'package:avatar_maker/avatar_maker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
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

class _AvatarEditorSheet extends StatefulWidget {
  const _AvatarEditorSheet({required this.student, required this.onSave});

  final Student student;
  final Future<void> Function(String? avatarJson) onSave;

  @override
  State<_AvatarEditorSheet> createState() => _AvatarEditorSheetState();
}

class _AvatarEditorSheetState extends State<_AvatarEditorSheet> {
  late final NonPersistentAvatarMakerController _controller;
  late final bool _hasStoredAvatar;
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

  @override
  Widget build(BuildContext context) {
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
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AvatarMakerCustomizer(
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

  Future<void> _saveAvatar() async {
    setState(() => _isSaving = true);
    await widget.onSave(_controller.getJsonOptionsSync());
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
