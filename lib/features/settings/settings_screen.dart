import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/providers/app_providers.dart';
import '../../core/security/security_preferences_service.dart';
import '../../core/session/app_session_controller.dart';
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
          _SectionCard(
            title: 'theme'.tr(),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('theme_light'.tr()),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('theme_auto'.tr()),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('theme_dark'.tr()),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (selection) => ref
                  .read(themeControllerProvider)
                  .setThemeMode(selection.first),
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

class _BackupsSection extends ConsumerStatefulWidget {
  const _BackupsSection({required this.session});

  final AppSessionController session;

  @override
  ConsumerState<_BackupsSection> createState() => _BackupsSectionState();
}

class _BackupsSectionState extends ConsumerState<_BackupsSection> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverPathController = TextEditingController();

  bool _testingConnection = false;
  bool? _connectionOk;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.session.webDavUrl ?? '';
    _usernameController.text = widget.session.webDavUsername ?? '';
    _serverPathController.text = widget.session.webDavServerPath ?? '/';
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverPathController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final session = ref.read(appSessionProvider);
    await session.setWebDavUrl(_urlController.text);
    await session.setWebDavUsername(_usernameController.text);
    if (_passwordController.text.isNotEmpty) {
      await session.setWebDavPassword(_passwordController.text);
    }
    final path = _serverPathController.text.trim();
    await session.setWebDavServerPath(path.isEmpty ? '/' : path);
    if (mounted) setState(() => _connectionOk = null);
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionOk = null;
    });
    final ok = await ref.read(appSessionProvider).testWebDavConnection(
      url: _urlController.text,
      username: _usernameController.text,
      password: _passwordController.text.isNotEmpty
          ? _passwordController.text
          : null,
    );
    if (mounted) {
      setState(() {
        _testingConnection = false;
        _connectionOk = ok;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isConfigured = session.isWebDavConfigured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('webdav_settings'.tr()),
        const SizedBox(height: 16),
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'webdav_url'.tr(),
            hintText: 'https://my.server/remote.php/dav/files/user/',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(labelText: 'webdav_username'.tr()),
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(labelText: 'webdav_password'.tr()),
          obscureText: true,
          autocorrect: false,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _serverPathController,
          decoration: InputDecoration(
            labelText: 'webdav_server_path'.tr(),
            hintText: '/backups/',
          ),
          autocorrect: false,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: _saveSettings,
              child: Text('save'.tr()),
            ),
            OutlinedButton.icon(
              onPressed: _testingConnection ? null : _testConnection,
              icon: _testingConnection
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _connectionOk == null
                          ? Icons.wifi_find_outlined
                          : (_connectionOk!
                              ? Icons.check_circle_outline
                              : Icons.error_outline),
                      color: _connectionOk == null
                          ? null
                          : (_connectionOk!
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error),
                    ),
              label: Text('webdav_test_connection'.tr()),
            ),
          ],
        ),
        if (_connectionOk != null) ...[
          const SizedBox(height: 8),
          Text(
            (_connectionOk!
                    ? 'webdav_connection_ok'
                    : 'webdav_connection_failed')
                .tr(),
            style: TextStyle(
              color: _connectionOk!
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('auto_export'.tr()),
          subtitle: Text('auto_export_hint'.tr()),
          value: session.webDavAutoExportEnabled,
          onChanged: isConfigured
              ? (value) => ref
                    .read(appSessionProvider)
                    .setWebDavAutoExportEnabled(value)
              : null,
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('auto_import'.tr()),
          subtitle: Text('auto_import_hint'.tr()),
          value: session.webDavAutoImportEnabled,
          onChanged: isConfigured
              ? (value) => ref
                    .read(appSessionProvider)
                    .setWebDavAutoImportEnabled(value)
              : null,
        ),
        if (!isConfigured) ...[
          const SizedBox(height: 4),
          Text(
            'webdav_not_configured'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
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
  }
}
