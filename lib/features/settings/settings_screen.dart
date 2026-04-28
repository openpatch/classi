import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../../core/providers/app_providers.dart';
import '../../core/security/security_preferences_service.dart';
import '../../core/session/app_session_controller.dart';
import '../../core/storage/library_backup_service.dart';
import '../../shared/utils/formatting.dart';
import '../setup/database_selection_sheet.dart';
import 'grade_system_controller.dart';
import 'grade_system_editor.dart';
import '../students/student_sorting.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final database = session.database;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'sort_students'.tr(),
            child: SegmentedButton<StudentSortField>(
              segments: [
                ButtonSegment(
                  value: StudentSortField.lastName,
                  label: Text('sort_by_last_name'.tr()),
                ),
                ButtonSegment(
                  value: StudentSortField.firstName,
                  label: Text('sort_by_first_name'.tr()),
                ),
              ],
              selected: {ref.watch(studentSortFieldProvider)},
              onSelectionChanged: (selection) => ref
                  .read(studentSortControllerProvider)
                  .setSortField(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionCard(title: '', child: _GradeSystemsSection()),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'change_passphrase'.tr(),
            child: _ChangePassphraseForm(),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'database_management'.tr(),
            child: _DatabaseSection(session: session),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'backups'.tr(),
            child: _BackupsSection(session: session),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'app_lock'.tr(),
            child: _SecuritySection(session: session),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'sidecars'.tr(),
            child: FutureBuilder<List<String>>(
              future: session.sidecarPaths(),
              builder: (context, snapshot) {
                final paths = snapshot.data ?? const <String>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final path in paths) SelectableText(path)],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'version'.tr(),
            child: FutureBuilder<DateTime?>(
              future: database?.lastModified(),
              builder: (context, snapshot) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(database?.databasePath ?? ''),
                    if (database != null) ...[
                      const SizedBox(height: 12),
                      FutureBuilder<int>(
                        future: database.fileSizeBytes(),
                        builder: (context, sizeSnapshot) =>
                            Text('${sizeSnapshot.data ?? 0} bytes'),
                      ),
                      if (snapshot.data != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '${'last_modified'.tr()}: '
                            '${DateFormat.yMMMd(context.locale.toLanguageTag()).add_Hm().format(snapshot.data!)}',
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'app_version'.tr(),
            child: const _AppInfoSection(),
          ),
        ],
      ),
    );
  }
}

class _AppInfoSection extends StatefulWidget {
  const _AppInfoSection();

  @override
  State<_AppInfoSection> createState() => _AppInfoSectionState();
}

class _AppInfoSectionState extends State<_AppInfoSection> {
  static const String _kGitHash = String.fromEnvironment('GIT_HASH');

  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info != null)
              SelectableText('${info.version}+${info.buildNumber}'),
            if (_kGitHash.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('build_commit'.tr()),
              const SizedBox(height: 4),
              SelectableText(_kGitHash),
            ],
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _GradeSystemsSection extends ConsumerWidget {
  const _GradeSystemsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(gradeSystemControllerProvider);
    final systems = controller.systems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'grade_systems'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _addSystem(context, ref),
              icon: const Icon(Icons.add),
              label: Text('add_grade_system'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!controller.initialized)
          const Center(child: CircularProgressIndicator())
        else
          for (final system in systems) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(system.name),
              subtitle: Text(
                system.entries
                    .map(
                      (entry) =>
                          '${entry.label} (${formatNumber(entry.numericValue)})',
                    )
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editSystem(context, ref, system),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'edit'.tr(),
                  ),
                  IconButton(
                    onPressed: () => _deleteSystem(context, ref, system),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'delete'.tr(),
                  ),
                ],
              ),
            ),
            if (systems.last.id != system.id) const Divider(height: 1),
          ],
      ],
    );
  }

  Future<void> _addSystem(BuildContext context, WidgetRef ref) async {
    final result = await showGradeSystemEditorSheet(
      context: context,
      title: 'add_grade_system'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(gradeSystemControllerProvider)
        .addSystem(name: result.name, entries: result.entries);
  }

  Future<void> _editSystem(
    BuildContext context,
    WidgetRef ref,
    GradeSystemDefinition system,
  ) async {
    final result = await showGradeSystemEditorSheet(
      context: context,
      initialName: system.name,
      initialEntries: system.entries,
      title: 'edit_grade_system'.tr(),
    );
    if (result == null) {
      return;
    }

    await ref
        .read(gradeSystemControllerProvider)
        .updateSystem(
          id: system.id,
          name: result.name,
          entries: result.entries,
        );
    await ref
        .read(groupRepositoryProvider)
        .updateGroupsWithMatchingGradeScale(
          previousGradeScale: system.entries,
          nextGradeScale: result.entries,
        );
  }

  Future<void> _deleteSystem(
    BuildContext context,
    WidgetRef ref,
    GradeSystemDefinition system,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr(namedArgs: {'name': system.name})),
        content: Text(system.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(gradeSystemControllerProvider).deleteSystem(system.id);
  }
}

class _ChangePassphraseForm extends ConsumerStatefulWidget {
  const _ChangePassphraseForm();

  @override
  ConsumerState<_ChangePassphraseForm> createState() =>
      _ChangePassphraseFormState();
}

class _ChangePassphraseFormState extends ConsumerState<_ChangePassphraseForm> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _currentController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'current_passphrase'.tr()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _newController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'new_passphrase'.tr()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmController,
          obscureText: true,
          decoration: InputDecoration(labelText: 'confirm_passphrase'.tr()),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () async {
              if (_newController.text != _confirmController.text) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('passphrase_mismatch'.tr())),
                );
                return;
              }

              final success = await ref
                  .read(appSessionProvider)
                  .changePassphrase(
                    _currentController.text.trim(),
                    _newController.text.trim(),
                  );
              if (!success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('invalid_passphrase'.tr())),
                  );
                }
                return;
              }
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('save'.tr())));
              }
            },
            child: Text('save'.tr()),
          ),
        ),
      ],
    );
  }
}

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection({required this.session});

  final AppSessionController session;

  static const Map<int, Duration> _timeoutOptions = {
    1: Duration(minutes: 1),
    5: Duration(minutes: 5),
    15: Duration(minutes: 15),
    30: Duration(minutes: 30),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('lock_on_background'.tr()),
          subtitle: Text('lock_on_background_hint'.tr()),
          value: session.lockOnBackground,
          onChanged: (value) =>
              ref.read(appSessionProvider).setLockOnBackground(value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Duration>(
          initialValue: _timeoutOptions.values.firstWhere(
            (value) => value == session.inactivityTimeout,
            orElse: () => SecurityPreferencesService.defaultInactivityTimeout,
          ),
          decoration: InputDecoration(labelText: 'inactivity_timeout'.tr()),
          items: [
            for (final entry in _timeoutOptions.entries)
              DropdownMenuItem(
                value: entry.value,
                child: Text(
                  'minutes_count'.tr(
                    namedArgs: {'count': entry.key.toString()},
                  ),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            ref.read(appSessionProvider).setInactivityTimeout(value);
          },
        ),
        const SizedBox(height: 12),
        _BiometricToggle(session: session),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => ref.read(appSessionProvider).lock(),
            icon: const Icon(Icons.lock_outline),
            label: Text('lock_now'.tr()),
          ),
        ),
      ],
    );
  }
}

class _BiometricToggle extends ConsumerStatefulWidget {
  const _BiometricToggle({required this.session});

  final AppSessionController session;

  @override
  ConsumerState<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<_BiometricToggle> {
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available =
        await ref.read(appSessionProvider).isBiometricAvailable();
    if (mounted) setState(() => _available = available);
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text('biometric_unlock'.tr()),
      subtitle: Text('biometric_unlock_hint'.tr()),
      value: widget.session.biometricEnabled,
      onChanged: (value) =>
          ref.read(appSessionProvider).setBiometricEnabled(value),
    );
  }
}

class _DatabaseSection extends ConsumerWidget {
  const _DatabaseSection({required this.session});

  final AppSessionController session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: session.currentDatabasePath(),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'current_database'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(snapshot.data ?? ''),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  showDatabaseSelectionSheet(context: context, ref: ref),
              icon: const Icon(Icons.storage_outlined),
              label: Text('switch_database'.tr()),
            ),
          ],
        );
      },
    );
  }
}

class _BackupsSection extends ConsumerWidget {
  const _BackupsSection({required this.session});

  final AppSessionController session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: session.currentDatabasePath(),
      builder: (context, snapshot) {
        final databasePath = snapshot.data ?? '';
        final autoExportFolderPath = session.autoExportFolderPath;
        final autoImportBackupPath = session.autoImportBackupPath;
        final autoExportTargetPath =
            autoExportFolderPath == null || databasePath.isEmpty
            ? null
            : p.join(
                autoExportFolderPath,
                LibraryBackupService.backupFileNameForDatabasePath(
                  databasePath,
                ),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('export_library_hint'.tr()),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => _exportNow(context, ref),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text('export_library'.tr()),
                ),
                OutlinedButton.icon(
                  onPressed: () => _importBackup(context, ref),
                  icon: const Icon(Icons.download_outlined),
                  label: Text('import_library'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('auto_export'.tr()),
              subtitle: Text('auto_export_hint'.tr()),
              value: session.autoExportEnabled,
              onChanged: (value) => _toggleAutoExport(
                context: context,
                ref: ref,
                nextValue: value,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('auto_import'.tr()),
              subtitle: Text('auto_import_hint'.tr()),
              value: session.autoImportEnabled,
              onChanged: (value) => _toggleAutoImport(
                context: context,
                ref: ref,
                nextValue: value,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'backup_folder'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(autoExportFolderPath ?? ''),
            if (autoExportTargetPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'auto_export_target'.tr(
                  namedArgs: {'path': autoExportTargetPath},
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickAutoExportFolder(context, ref),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text('choose_backup_folder'.tr()),
            ),
            const SizedBox(height: 16),
            Text(
              'auto_import_file'.tr(),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(autoImportBackupPath ?? ''),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickAutoImportFile(context, ref),
              icon: const Icon(Icons.insert_drive_file_outlined),
              label: Text('choose_import_backup'.tr()),
            ),
            if (session.hasPendingAutoImport) ...[
              const SizedBox(height: 8),
              Text(
                'newer_backup_available'.tr(),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            if (session.lastBackupMessageCode != null) ...[
              const SizedBox(height: 12),
              Text(
                session.lastBackupMessageCode!.tr(),
                style: TextStyle(
                  color: session.lastBackupMessageIsError
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _exportNow(BuildContext context, WidgetRef ref) async {
    final session = ref.read(appSessionProvider);
    session.suspendBackgroundLock();
    try {
      final folder = await FilePicker.getDirectoryPath();
      if (folder == null || !context.mounted) {
        return;
      }

      final errorCode = await ref
          .read(appSessionProvider)
          .exportBackupToFolder(folder);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((errorCode ?? 'backup_exported').tr())),
      );
    } finally {
      session.resumeBackgroundLock();
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final session = ref.read(appSessionProvider);
    session.suspendBackgroundLock();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['classi-backup'],
      );
      final backupPath = result?.files.single.path;
      if (backupPath == null || !context.mounted) {
        return;
      }

      final errorCode = await ref
          .read(appSessionProvider)
          .importBackup(backupPath);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((errorCode ?? 'backup_imported').tr())),
      );
    } finally {
      session.resumeBackgroundLock();
    }
  }

  Future<void> _pickAutoExportFolder(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final session = ref.read(appSessionProvider);
    session.suspendBackgroundLock();
    try {
      final folder = await FilePicker.getDirectoryPath();
      if (folder == null) {
        return;
      }

      await ref.read(appSessionProvider).setAutoExportFolderPath(folder);
    } finally {
      session.resumeBackgroundLock();
    }
  }

  Future<void> _pickAutoImportFile(BuildContext context, WidgetRef ref) async {
    final session = ref.read(appSessionProvider);
    session.suspendBackgroundLock();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['classi-backup'],
      );
      final backupPath = result?.files.single.path;
      if (backupPath == null) {
        return;
      }

      await ref.read(appSessionProvider).setAutoImportBackupPath(backupPath);
    } finally {
      session.resumeBackgroundLock();
    }
  }

  Future<void> _toggleAutoExport({
    required BuildContext context,
    required WidgetRef ref,
    required bool nextValue,
  }) async {
    final session = ref.read(appSessionProvider);
    if (nextValue && session.autoExportFolderPath == null) {
      session.suspendBackgroundLock();
      String? folder;
      try {
        folder = await FilePicker.getDirectoryPath();
      } finally {
        session.resumeBackgroundLock();
      }
      if (folder == null) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auto_export_requires_folder'.tr())),
        );
        return;
      }
      await session.setAutoExportFolderPath(folder);
    }

    await session.setAutoExportEnabled(nextValue);
  }

  Future<void> _toggleAutoImport({
    required BuildContext context,
    required WidgetRef ref,
    required bool nextValue,
  }) async {
    final session = ref.read(appSessionProvider);
    if (nextValue && session.autoImportBackupPath == null) {
      session.suspendBackgroundLock();
      FilePickerResult? result;
      try {
        result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['classi-backup'],
        );
      } finally {
        session.resumeBackgroundLock();
      }
      final backupPath = result?.files.single.path;
      if (backupPath == null) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('auto_import_requires_file'.tr())),
        );
        return;
      }
      await session.setAutoImportBackupPath(backupPath);
    }

    await session.setAutoImportEnabled(nextValue);
  }
}
