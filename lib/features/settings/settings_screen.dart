import 'dart:async';
import 'dart:developer' as developer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/providers/app_providers.dart';
import '../../core/security/security_preferences_service.dart';
import '../../core/session/app_session_controller.dart';
import '../../core/storage/library_backup_service.dart';
import '../../core/sync/device_identity_service.dart';
import '../../core/update/app_update_controller.dart';
import '../../shared/utils/formatting.dart';
import '../../shared/widgets/app_updater.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/content_constraints.dart';
import '../setup/database_selection_sheet.dart';
import 'backup_conflict_screen.dart';
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
      body: ContentConstraints(
        child: ListView(
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
              title: 'school_years'.tr(),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('manage_school_years'.tr()),
                subtitle: Text('school_years_hint'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/years'),
              ),
            ),
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
      ),
    );
  }
}

class _AppInfoSection extends ConsumerStatefulWidget {
  const _AppInfoSection();

  @override
  ConsumerState<_AppInfoSection> createState() => _AppInfoSectionState();
}

class _AppInfoSectionState extends ConsumerState<_AppInfoSection> {
  static const String _kGitHash = String.fromEnvironment('GIT_HASH');

  late final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final appUpdate = ref.watch(appUpdateControllerProvider);
    return FutureBuilder<PackageInfo>(
      future: _packageInfoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (info != null)
              SelectableText('${info.version}+${info.buildNumber}'),
            if (supportsSelfUpdate) ...[
              const SizedBox(height: 12),
              Text(
                'app_update_status_title'.tr(),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Text(
                appUpdate.status == AppUpdateStatus.available &&
                        appUpdate.latestVersion != null
                    ? 'app_update_status_available_version'.tr(
                        namedArgs: {'version': appUpdate.latestVersion!},
                      )
                    : appUpdate.status.translationKey.tr(),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    appUpdate.status == AppUpdateStatus.checking ||
                        !appUpdate.canCheckForUpdates
                    ? null
                    : () => ref
                          .read(appUpdateControllerProvider)
                          .checkForUpdates(),
                icon: appUpdate.status == AppUpdateStatus.checking
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: Text('app_update_check_now'.tr()),
              ),
            ],
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
  bool _isSaving = false;
  bool _wrongCurrentPassphrase = false;

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
          onChanged: (_) {
            if (_wrongCurrentPassphrase) {
              setState(() => _wrongCurrentPassphrase = false);
            }
          },
          decoration: InputDecoration(
            labelText: 'current_passphrase'.tr(),
            errorText: _wrongCurrentPassphrase
                ? 'invalid_passphrase'.tr()
                : null,
          ),
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
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(labelText: 'confirm_passphrase'.tr()),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('save'.tr()),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final current = _currentController.text.trim();
    final newPass = _newController.text.trim();
    final confirm = _confirmController.text.trim();

    if (current.isEmpty || newPass.isEmpty) return;

    if (newPass != confirm) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('passphrase_mismatch'.tr())));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await ref
          .read(appSessionProvider)
          .changePassphrase(current, newPass);
      if (!mounted) return;
      if (!success) {
        setState(() => _wrongCurrentPassphrase = true);
        return;
      }
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('passphrase_changed'.tr())));
    } catch (e, st) {
      developer.log(
        'Failed to change passphrase',
        name: 'classi.settings',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      showErrorSnackBar(context, 'generic_error'.tr(), error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  /// How long the app may be in the background before it locks.
  static const List<Duration> _graceOptions = [
    Duration.zero,
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
  ];

  static String _graceLabel(Duration value) {
    if (value <= Duration.zero) return 'background_lock_grace_none'.tr();
    if (value.inSeconds < 60) {
      return 'seconds_count'.tr(
        namedArgs: {'count': value.inSeconds.toString()},
      );
    }
    return 'minutes_count'.tr(
      namedArgs: {'count': value.inMinutes.toString()},
    );
  }

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
          isExpanded: true,
          decoration: InputDecoration(labelText: 'inactivity_timeout'.tr()),
          items: [
            for (final entry in _timeoutOptions.entries)
              DropdownMenuItem(
                value: entry.value,
                child: Text(
                  'minutes_count'.tr(
                    namedArgs: {'count': entry.key.toString()},
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        DropdownButtonFormField<Duration>(
          initialValue: _graceOptions.firstWhere(
            (value) => value == session.backgroundLockGrace,
            orElse: () => SecurityPreferencesService.defaultBackgroundLockGrace,
          ),
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'background_lock_grace'.tr(),
            helperText: 'background_lock_grace_hint'.tr(),
            helperMaxLines: 3,
          ),
          items: [
            for (final value in _graceOptions)
              DropdownMenuItem(
                value: value,
                child: Text(
                  _graceLabel(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          // Nothing to delay when the app never locks on its way out.
          onChanged: session.lockOnBackground
              ? (value) {
                  if (value == null) return;
                  ref.read(appSessionProvider).setBackgroundLockGrace(value);
                }
              : null,
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
    final available = await ref.read(appSessionProvider).isBiometricAvailable();
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
  final _deviceNameController = TextEditingController();

  bool _testingConnection = false;
  bool? _connectionOk;
  bool _isExportingNow = false;
  bool _isRestoringNow = false;
  List<WebDavBackupEntry>? _backups;
  bool _loadingBackups = false;
  bool _backupsLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.session.webDavUrl ?? '';
    _usernameController.text = widget.session.webDavUsername ?? '';
    _serverPathController.text = widget.session.webDavServerPath ?? '/';
    if (widget.session.isWebDavConfigured) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBackups());
    }
    unawaited(_loadDeviceName());
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverPathController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceName() async {
    final name = await ref.read(appSessionProvider).storedDeviceName();
    if (mounted) setState(() => _deviceNameController.text = name ?? '');
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
    await session.setDeviceName(_deviceNameController.text);
    if (mounted) {
      setState(() => _connectionOk = null);
      _loadBackups();
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionOk = null;
    });
    final ok = await ref
        .read(appSessionProvider)
        .testWebDavConnection(
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

  /// Backups excluding `_CONFLICT_` copies, which are surfaced separately
  /// through [_pendingConflicts] instead of appearing as plain list entries.
  List<WebDavBackupEntry> get _nonConflictBackups => [
    for (final backup in _backups ?? const <WebDavBackupEntry>[])
      if (!backup.isConflict) backup,
  ];

  /// Pairs each conflict copy with its canonical counterpart, newest
  /// conflict per library only (older conflict copies for the same library
  /// are superseded once the newest one is resolved).
  List<({WebDavBackupEntry canonical, WebDavBackupEntry conflict})>
  get _pendingConflicts => LibraryBackupService.pendingConflictPairs(
    _backups ?? const <WebDavBackupEntry>[],
  );

  Future<void> _resolveConflict(
    WebDavBackupEntry canonical,
    WebDavBackupEntry conflict,
  ) async {
    final resolved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BackupConflictScreen(canonical: canonical, conflict: conflict),
      ),
    );
    if (resolved == true) {
      _loadBackups();
    }
  }

  Future<void> _loadBackups() async {
    if (_loadingBackups) return;
    setState(() {
      _loadingBackups = true;
      _backupsLoadFailed = false;
    });
    try {
      final backups = await ref.read(appSessionProvider).listWebDavBackups();
      if (mounted) setState(() => _backups = backups);
    } catch (_) {
      if (mounted) setState(() => _backupsLoadFailed = true);
    } finally {
      if (mounted) setState(() => _loadingBackups = false);
    }
  }

  Future<void> _exportNow() async {
    setState(() => _isExportingNow = true);
    try {
      final errorCode = await ref.read(appSessionProvider).exportNow();
      if (!mounted) return;
      final code =
          errorCode ??
          ref.read(appSessionProvider).lastBackupMessageCode ??
          'backup_exported';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(code.tr())));
    } finally {
      if (mounted) setState(() => _isExportingNow = false);
    }
  }

  Future<void> _restoreFromBackup(WebDavBackupEntry backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('restore_backup'.tr()),
        content: Text('restore_backup_overwrite_warning'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('restore_backup'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRestoringNow = true);
    try {
      final dbPath = await widget.session.currentDatabasePath();
      if (!mounted) return;
      final errorCode = await ref
          .read(appSessionProvider)
          .restoreWebDavBackup(
            remotePath: backup.remotePath,
            destinationPath: dbPath,
            createNew: false,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((errorCode ?? 'backup_restored').tr())),
      );
    } finally {
      if (mounted) setState(() => _isRestoringNow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final isConfigured = session.isWebDavConfigured;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    String? formatDateTime(DateTime? dt) {
      if (dt == null) return null;
      return DateFormat.yMd(localeTag).add_Hm().format(dt.toLocal());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('webdav_settings'.tr()),
        const SizedBox(height: 16),
        TextField(
          controller: _deviceNameController,
          decoration: InputDecoration(
            labelText: 'device_name'.tr(),
            hintText: DeviceIdentityService.defaultDeviceName(),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'device_name_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
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
            FilledButton(onPressed: _saveSettings, child: Text('save'.tr())),
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
        if (isConfigured) ...[
          const SizedBox(height: 12),
          _MaxVersionsPicker(session: session),
        ],
        if (isConfigured && session.webDavAutoExportEnabled) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: (_isExportingNow || session.isExporting)
                  ? null
                  : _exportNow,
              icon: (_isExportingNow || session.isExporting)
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text('export_now'.tr()),
            ),
          ),
        ],
        if (isConfigured) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          for (final pair in _pendingConflicts) ...[
            _ConflictBanner(
              onResolve: () => _resolveConflict(pair.canonical, pair.conflict),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'available_backups'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: _loadingBackups ? null : _loadBackups,
                icon: _loadingBackups
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'retry'.tr(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_backupsLoadFailed)
            Text(
              'webdav_connection_failed'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_backups == null || _loadingBackups && _backups!.isEmpty)
            const SizedBox.shrink()
          else if (_nonConflictBackups.isEmpty)
            Text(
              'no_webdav_backups_found'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _nonConflictBackups.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final backup = _nonConflictBackups[index];
                return _BackupListTile(
                  backup: backup,
                  localeTag: localeTag,
                  restoring: _isRestoringNow,
                  onRestore: () => _restoreFromBackup(backup),
                );
              },
            ),
        ],
        if (session.hasPendingAutoImport) ...[
          const SizedBox(height: 8),
          Text(
            'newer_backup_available'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
        if (session.lastExportedAt != null ||
            session.lastImportedAt != null) ...[
          const SizedBox(height: 12),
          if (session.lastExportedAt != null)
            Text(
              'last_exported_at'.tr(
                namedArgs: {
                  'datetime': formatDateTime(session.lastExportedAt)!,
                },
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (session.lastImportedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'last_imported_at'.tr(
                  namedArgs: {
                    'datetime': formatDateTime(session.lastImportedAt)!,
                  },
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
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

class _MaxVersionsPicker extends StatelessWidget {
  const _MaxVersionsPicker({required this.session});

  final AppSessionController session;

  static const List<int> _options = [1, 3, 5, 10];

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'backup_max_versions'.tr(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<int>(
              segments: [
                for (final n in _options)
                  ButtonSegment(
                    value: n,
                    label: Text(
                      n == 1 ? 'backup_versions_no_history'.tr() : n.toString(),
                    ),
                  ),
              ],
              selected: {session.webDavMaxVersions},
              onSelectionChanged: (selection) => ref
                  .read(appSessionProvider)
                  .setWebDavMaxVersions(selection.first),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'backup_max_versions_hint'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.onResolve});

  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'backup_conflict_detected'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'backup_conflict_detected_hint'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: onResolve,
                      child: Text('resolve_conflict'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupListTile extends StatelessWidget {
  const _BackupListTile({
    required this.backup,
    required this.localeTag,
    required this.restoring,
    required this.onRestore,
  });

  final WebDavBackupEntry backup;
  final String localeTag;
  final bool restoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final modifiedAt = backup.modifiedAt;
    final dateStr = modifiedAt != null
        ? DateFormat.yMd(localeTag).add_Hm().format(modifiedAt.toLocal())
        : null;
    final sizeStr = backup.sizeBytes != null
        ? _formatBytes(backup.sizeBytes!)
        : null;
    final subtitleParts = [?backup.deviceName, ?dateStr, ?sizeStr];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.cloud_outlined),
      title: Text(backup.libraryName),
      subtitle: subtitleParts.isNotEmpty
          ? Text(subtitleParts.join(' • '))
          : null,
      trailing: IconButton(
        icon: restoring
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.restore_outlined),
        tooltip: 'restore_backup'.tr(),
        onPressed: restoring ? null : onRestore,
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}
