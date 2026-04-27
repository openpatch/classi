import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/providers/app_providers.dart';
import '../../core/storage/database_path_service.dart';

enum _DatabaseSelectionAction { openExisting, createNew }

Future<void> showDatabaseSelectionSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final session = ref.read(appSessionProvider);
  final currentPath = await session.currentDatabasePath();
  if (!context.mounted) {
    return;
  }

  final action = await showModalBottomSheet<_DatabaseSelectionAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'database_management'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              SelectableText(currentPath),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_open_outlined),
                title: Text('open_existing_database'.tr()),
                subtitle: Text('open_existing_database_hint'.tr()),
                onTap: () => Navigator.of(
                  context,
                ).pop(_DatabaseSelectionAction.openExisting),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.create_new_folder_outlined),
                title: Text('create_another_database'.tr()),
                subtitle: Text('create_another_database_hint'.tr()),
                onTap: () => Navigator.of(
                  context,
                ).pop(_DatabaseSelectionAction.createNew),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (action == null || !context.mounted) {
    return;
  }

  switch (action) {
    case _DatabaseSelectionAction.openExisting:
      await _openExistingDatabase(context: context, ref: ref);
      break;
    case _DatabaseSelectionAction.createNew:
      await _createNewDatabase(context: context, ref: ref);
      break;
  }
}

Future<void> _openExistingDatabase({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final path = await FilePicker.getDirectoryPath();
  if (path == null || !context.mounted) {
    return;
  }

  if (!DatabasePathService.isPackagePath(path)) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('library_package_required'.tr())));
    return;
  }

  await _applyDatabaseSelection(
    context: context,
    ref: ref,
    databasePath: path,
    createNew: false,
  );
}

Future<void> _createNewDatabase({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final currentPath = await ref.read(appSessionProvider).currentDatabasePath();
  final defaultFolder = DatabasePathService.containerParentPathFor(currentPath);
  final defaultName = p.basenameWithoutExtension(currentPath);

  if (!context.mounted) {
    return;
  }

  final databasePath = await _showCreateDatabaseDialog(
    context: context,
    initialFolder: defaultFolder,
    initialName: defaultName,
  );
  if (databasePath == null || !context.mounted) {
    return;
  }

  await _applyDatabaseSelection(
    context: context,
    ref: ref,
    databasePath: databasePath,
    createNew: true,
  );
}

Future<String?> _showCreateDatabaseDialog({
  required BuildContext context,
  required String initialFolder,
  required String initialName,
}) async {
  String selectedFolder = initialFolder;
  final nameController = TextEditingController(text: initialName);

  return showDialog<String>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final resolvedName = nameController.text.trim().isEmpty
              ? 'classi'
              : nameController.text.trim();
          final fullPath = p.join(
            selectedFolder,
            DatabasePathService.normalizeDatabasePackageName(resolvedName),
          );

          return AlertDialog(
            title: Text('create_another_database'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'database_folder'.tr(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedFolder,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'choose_library_folder'.tr(),
                      onPressed: () async {
                        final folder = await FilePicker.getDirectoryPath(
                          initialDirectory: selectedFolder,
                          dialogTitle: 'choose_library_folder'.tr(),
                        );
                        if (folder != null) {
                          setState(() => selectedFolder = folder);
                        }
                      },
                      icon: const Icon(Icons.folder_open_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'database_name'.tr(),
                    hintText: 'database_name_hint'.tr(),
                    suffixText: '.classi',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Text(
                  fullPath,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: nameController.text.trim().isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        p.join(
                          selectedFolder,
                          DatabasePathService.normalizeDatabasePackageName(
                            nameController.text.trim(),
                          ),
                        ),
                      ),
                child: Text('create_database'.tr()),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _applyDatabaseSelection({
  required BuildContext context,
  required WidgetRef ref,
  required String databasePath,
  required bool createNew,
}) async {
  final errorCode = await ref
      .read(appSessionProvider)
      .selectDatabase(databasePath, createNew: createNew);
  if (errorCode == null || !context.mounted) {
    return;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(errorCode.tr())));
}
