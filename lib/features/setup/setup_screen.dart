import 'dart:developer' as developer;
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../core/providers/app_providers.dart';
import '../../core/security/security_preferences_service.dart';
import '../../core/session/app_session_controller.dart';
import '../../core/storage/database_path_service.dart';
import '../../shared/widgets/app_error_state.dart';
import 'auto_import_prompt_card.dart';
import 'database_selection_sheet.dart';
import 'webdav_restore_flow.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const int _totalSteps = 4;
  static const String _defaultLibraryName = 'classi';

  static const Map<int, Duration> _timeoutOptions = {
    1: Duration(minutes: 1),
    5: Duration(minutes: 5),
    15: Duration(minutes: 15),
    30: Duration(minutes: 30),
  };

  final _locationFormKey = GlobalKey<FormState>();
  final _securityFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();

  int _currentStep = 0;
  bool _isSaving = false;
  String? _selectedFolder;
  bool _folderError = false;

  // Step 3: App lock preferences with recommended defaults.
  bool _lockOnBackground = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  Duration _inactivityTimeout =
      SecurityPreferencesService.defaultInactivityTimeout;

  // Step 4: WebDAV backup credentials (optional).
  final _webDavUrlController = TextEditingController();
  final _webDavUsernameController = TextEditingController();
  final _webDavPasswordController = TextEditingController();
  final _webDavServerPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await ref.read(appSessionProvider).isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _loadDefaultPath() async {
    // Do not pre-populate the folder so the user must explicitly choose where
    // to store their data.  Only pre-fill the library name with a sensible
    // default so the name field is not blank.
    if (!mounted) return;
    setState(() {
      _selectedFolder = null;
      _nameController.text = _defaultLibraryName;
    });
  }

  String get _databasePath {
    final folder = _selectedFolder;
    if (folder == null) return '';
    final name = _nameController.text.trim().isEmpty
        ? _defaultLibraryName
        : _nameController.text.trim();
    return p.join(
      folder,
      DatabasePathService.normalizeDatabasePackageName(name),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passphraseController.dispose();
    _confirmController.dispose();
    _webDavUrlController.dispose();
    _webDavUsernameController.dispose();
    _webDavPasswordController.dispose();
    _webDavServerPathController.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    switch (_currentStep) {
      case 0:
        final folderMissing = _selectedFolder == null;
        setState(() => _folderError = folderMissing);
        if (folderMissing) return;
        if (_locationFormKey.currentState!.validate()) {
          setState(() => _currentStep = 1);
        }
      case 1:
        if (_securityFormKey.currentState!.validate()) {
          setState(() => _currentStep = 2);
        }
      case 2:
        setState(() => _currentStep = 3);
    }
  }

  void _onBack() => setState(() => _currentStep -= 1);

  Future<void> _submit() async {
    setState(() => _isSaving = true);

    try {
      final session = ref.read(appSessionProvider);
      await session.setNewDatabasePath(_databasePath);
      await _persistSetupPreferences(session);
      if (!mounted) return;

      await session.createDatabase(_passphraseController.text.trim());
      if (!mounted) return;

      if (session.status == AppSessionStatus.ready) {
        context.go('/setup/recovery');
      } else {
        showErrorSnackBar(context, 'error_loading_database'.tr());
      }
    } catch (e, st) {
      developer.log(
        'Failed to create database',
        name: 'classi.setup',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (mounted) showErrorSnackBar(context, 'error_loading_database'.tr());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _restoreFromWebDav() async {
    setState(() => _isSaving = true);

    try {
      final session = ref.read(appSessionProvider);
      await session.setNewDatabasePath(_databasePath);
      // Only save the step-3 WebDAV form if the user filled it in, so that
      // credentials entered via the picker's credential sheet are preserved
      // across retries when the form is left empty.
      if (_webDavUrlController.text.trim().isNotEmpty) {
        await _persistSetupPreferences(session);
      }
      if (!mounted) {
        return;
      }
      await restoreWebDavBackupFlow(
        context: context,
        ref: ref,
        destinationPath: _databasePath,
        createNew: true,
      );
    } catch (e, st) {
      developer.log(
        'Failed to restore database from WebDAV',
        name: 'classi.setup',
        level: 1000,
        error: e,
        stackTrace: st,
      );
      if (mounted) showErrorSnackBar(context, 'backup_import_failed'.tr());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _persistSetupPreferences(AppSessionController session) async {
    await session.setLockOnBackground(_lockOnBackground);
    await session.setInactivityTimeout(_inactivityTimeout);
    await session.setBiometricEnabled(_biometricEnabled);

    final webDavUrl = _webDavUrlController.text.trim();
    if (webDavUrl.isNotEmpty) {
      await session.setWebDavUrl(webDavUrl);
      await session.setWebDavUsername(_webDavUsernameController.text.trim());
      final password = _webDavPasswordController.text;
      if (password.isNotEmpty) {
        await session.setWebDavPassword(password);
      }
      final serverPath = _webDavServerPathController.text.trim();
      await session.setWebDavServerPath(serverPath.isEmpty ? '/' : serverPath);
      await session.setWebDavAutoExportEnabled(true);
      await session.setWebDavAutoImportEnabled(true);
      return;
    }

    await session.setWebDavUrl(null);
    await session.setWebDavUsername(null);
    await session.setWebDavPassword(null);
    await session.setWebDavServerPath(null);
    await session.setWebDavAutoExportEnabled(false);
    await session.setWebDavAutoImportEnabled(false);
  }

  Future<void> _pickFolder() async {
    final folder = await FilePicker.getDirectoryPath(
      initialDirectory: _selectedFolder,
      dialogTitle: 'choose_library_folder'.tr(),
    );
    if (folder != null && mounted) {
      setState(() {
        _selectedFolder = folder;
        _folderError = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _totalSteps - 1;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'setup_title'.tr(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            _WizardStepIndicator(
                              currentStep: _currentStep,
                              totalSteps: _totalSteps,
                            ),
                            const SizedBox(height: 24),
                            _buildStepContent(),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isSaving
                                    ? null
                                    : (isLastStep ? _submit : _onNext),
                                child: _isSaving
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        isLastStep
                                            ? 'create_database'.tr()
                                            : 'next'.tr(),
                                      ),
                              ),
                            ),
                            if (isLastStep) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : _restoreFromWebDav,
                                  icon: const Icon(
                                    Icons.cloud_download_outlined,
                                  ),
                                  label: Text(
                                    'restore_from_webdav_backup'.tr(),
                                  ),
                                ),
                              ),
                            ],
                            if (_currentStep > 0) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _isSaving ? null : _onBack,
                                  child: Text('back'.tr()),
                                ),
                              ),
                            ],
                            if (_currentStep == 0) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () => showDatabaseSelectionSheet(
                                          context: context,
                                          ref: ref,
                                        ),
                                  icon: const Icon(Icons.storage_outlined),
                                  label: Text('choose_database'.tr()),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _LibraryStep(
          formKey: _locationFormKey,
          nameController: _nameController,
          selectedFolder: _selectedFolder,
          databasePath: _databasePath,
          isSaving: _isSaving,
          onPickFolder: _pickFolder,
          onChanged: () => setState(() {}),
          folderError: _folderError,
        );
      case 1:
        return _SecurityStep(
          formKey: _securityFormKey,
          passphraseController: _passphraseController,
          confirmController: _confirmController,
        );
      case 2:
        return _LockingStep(
          lockOnBackground: _lockOnBackground,
          inactivityTimeout: _inactivityTimeout,
          timeoutOptions: _timeoutOptions,
          biometricAvailable: _biometricAvailable,
          biometricEnabled: _biometricEnabled,
          onLockOnBackgroundChanged: (value) =>
              setState(() => _lockOnBackground = value),
          onInactivityTimeoutChanged: (value) =>
              setState(() => _inactivityTimeout = value),
          onBiometricEnabledChanged: (value) =>
              setState(() => _biometricEnabled = value),
        );
      case 3:
        return _BackupStep(
          urlController: _webDavUrlController,
          usernameController: _webDavUsernameController,
          passwordController: _webDavPasswordController,
          serverPathController: _webDavServerPathController,
          onChanged: () => setState(() {}),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WizardStepIndicator extends StatelessWidget {
  const _WizardStepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'wizard_step_counter'.tr(
            namedArgs: {
              'current': (currentStep + 1).toString(),
              'total': totalSteps.toString(),
            },
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryStep extends StatelessWidget {
  const _LibraryStep({
    required this.formKey,
    required this.nameController,
    required this.selectedFolder,
    required this.databasePath,
    required this.isSaving,
    required this.onPickFolder,
    required this.onChanged,
    required this.folderError,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String? selectedFolder;
  final String databasePath;
  final bool isSaving;
  final VoidCallback onPickFolder;
  final VoidCallback onChanged;
  final bool folderError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('setup_library_intro'.tr()),
          const SizedBox(height: 16),
          Text(
            'database_folder'.tr(),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedFolder ?? 'no_folder_selected'.tr(),
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selectedFolder == null
                        ? colorScheme.onSurfaceVariant
                        : null,
                    fontStyle: selectedFolder == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'choose_library_folder'.tr(),
                onPressed: isSaving ? null : onPickFolder,
                icon: const Icon(Icons.folder_open_outlined),
              ),
            ],
          ),
          if (folderError) ...[
            const SizedBox(height: 4),
            Text(
              'library_folder_required'.tr(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          if (Platform.isAndroid) ...[
            const SizedBox(height: 8),
            const _AndroidStorageNote(),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'database_name'.tr(),
              hintText: 'database_name_hint'.tr(),
              suffixText: '.classi',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'database_name_required'.tr();
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          if (databasePath.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              databasePath,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          const AutoImportPromptCard(),
        ],
      ),
    );
  }
}

class _AndroidStorageNote extends StatelessWidget {
  const _AndroidStorageNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: Theme.of(context).colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'library_storage_warning_android'.tr(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _SecurityStep extends StatelessWidget {
  const _SecurityStep({
    required this.formKey,
    required this.passphraseController,
    required this.confirmController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passphraseController;
  final TextEditingController confirmController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('setup_intro'.tr()),
          const SizedBox(height: 24),
          TextFormField(
            controller: passphraseController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'setup_passphrase'.tr()),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'passphrase_required'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'confirm_passphrase'.tr()),
            validator: (value) {
              if (value != passphraseController.text) {
                return 'passphrase_mismatch'.tr();
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _LockingStep extends StatelessWidget {
  const _LockingStep({
    required this.lockOnBackground,
    required this.inactivityTimeout,
    required this.timeoutOptions,
    required this.biometricAvailable,
    required this.biometricEnabled,
    required this.onLockOnBackgroundChanged,
    required this.onInactivityTimeoutChanged,
    required this.onBiometricEnabledChanged,
  });

  final bool lockOnBackground;
  final Duration inactivityTimeout;
  final Map<int, Duration> timeoutOptions;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final ValueChanged<bool> onLockOnBackgroundChanged;
  final ValueChanged<Duration> onInactivityTimeoutChanged;
  final ValueChanged<bool> onBiometricEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('setup_locking_intro'.tr()),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('lock_on_background'.tr()),
          subtitle: Text('lock_on_background_hint'.tr()),
          value: lockOnBackground,
          onChanged: onLockOnBackgroundChanged,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Duration>(
          initialValue: inactivityTimeout,
          isExpanded: true,
          decoration: InputDecoration(labelText: 'inactivity_timeout'.tr()),
          items: [
            for (final entry in timeoutOptions.entries)
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
            if (value != null) onInactivityTimeoutChanged(value);
          },
        ),
        if (biometricAvailable) ...[
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('biometric_unlock'.tr()),
            subtitle: Text('biometric_unlock_hint'.tr()),
            value: biometricEnabled,
            onChanged: onBiometricEnabledChanged,
          ),
        ],
      ],
    );
  }
}

class _BackupStep extends StatelessWidget {
  const _BackupStep({
    required this.urlController,
    required this.usernameController,
    required this.passwordController,
    required this.serverPathController,
    required this.onChanged,
  });

  final TextEditingController urlController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController serverPathController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('setup_backup_intro'.tr()),
        const SizedBox(height: 16),
        TextField(
          controller: urlController,
          decoration: InputDecoration(
            labelText: 'webdav_url'.tr(),
            hintText: 'https://my.server/remote.php/dav/files/user/',
          ),
          keyboardType: TextInputType.url,
          autocorrect: false,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: usernameController,
          decoration: InputDecoration(labelText: 'webdav_username'.tr()),
          autocorrect: false,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'webdav_password'.tr()),
          obscureText: true,
          autocorrect: false,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: serverPathController,
          decoration: InputDecoration(
            labelText: 'webdav_server_path'.tr(),
            hintText: '/backups/',
          ),
          autocorrect: false,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 8),
        Text(
          'webdav_not_configured'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
