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
import 'auto_import_prompt_card.dart';
import 'database_selection_sheet.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  static const int _totalSteps = 4;

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

  // Step 3: App lock preferences with recommended defaults.
  bool _lockOnBackground = true;
  Duration _inactivityTimeout =
      SecurityPreferencesService.defaultInactivityTimeout;

  // Step 4: Backup preferences.
  bool _autoExportEnabled = false;
  String? _autoExportFolderPath;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    final currentPath =
        await ref.read(appSessionProvider).currentDatabasePath();
    if (!mounted) return;
    setState(() {
      _selectedFolder =
          DatabasePathService.containerParentPathFor(currentPath);
      _nameController.text = p.basenameWithoutExtension(currentPath);
    });
  }

  String get _databasePath {
    final folder = _selectedFolder ?? '';
    final name = _nameController.text.trim().isEmpty
        ? 'classi'
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
    super.dispose();
  }

  Future<void> _onNext() async {
    switch (_currentStep) {
      case 0:
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

  Future<void> _toggleAutoExport(bool value) async {
    if (value && _autoExportFolderPath == null) {
      final folder = await FilePicker.getDirectoryPath();
      if (!mounted) return;
      if (folder == null) return;
      setState(() {
        _autoExportFolderPath = folder;
        _autoExportEnabled = true;
      });
    } else {
      setState(() => _autoExportEnabled = value);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);

    try {
      final session = ref.read(appSessionProvider);

      await session.setLockOnBackground(_lockOnBackground);
      await session.setInactivityTimeout(_inactivityTimeout);

      if (_autoExportEnabled && _autoExportFolderPath != null) {
        await session.setAutoExportFolderPath(_autoExportFolderPath);
        await session.setAutoExportEnabled(true);
      }

      await session.setNewDatabasePath(_databasePath);
      if (!mounted) return;

      await session.createDatabase(_passphraseController.text.trim());
      if (!mounted) return;

      if (session.status == AppSessionStatus.ready) {
        context.go('/setup/recovery');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_loading_database'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickFolder() async {
    final folder = await FilePicker.getDirectoryPath(
      initialDirectory: _selectedFolder,
      dialogTitle: 'choose_library_folder'.tr(),
    );
    if (folder != null && mounted) {
      setState(() => _selectedFolder = folder);
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
                              style:
                                  Theme.of(context).textTheme.headlineMedium,
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
          onLockOnBackgroundChanged: (value) =>
              setState(() => _lockOnBackground = value),
          onInactivityTimeoutChanged: (value) =>
              setState(() => _inactivityTimeout = value),
        );
      case 3:
        return _BackupStep(
          autoExportEnabled: _autoExportEnabled,
          autoExportFolderPath: _autoExportFolderPath,
          onAutoExportToggled: _toggleAutoExport,
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
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final String? selectedFolder;
  final String databasePath;
  final bool isSaving;
  final VoidCallback onPickFolder;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
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
                  selectedFolder ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              IconButton(
                tooltip: 'choose_library_folder'.tr(),
                onPressed: isSaving ? null : onPickFolder,
                icon: const Icon(Icons.folder_open_outlined),
              ),
            ],
          ),
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
                return 'database_name'.tr();
              }
              return null;
            },
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 8),
          SelectableText(
            databasePath,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          const AutoImportPromptCard(),
        ],
      ),
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
            decoration: InputDecoration(
              labelText: 'setup_passphrase'.tr(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'setup_passphrase'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'confirm_passphrase'.tr(),
            ),
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
    required this.onLockOnBackgroundChanged,
    required this.onInactivityTimeoutChanged,
  });

  final bool lockOnBackground;
  final Duration inactivityTimeout;
  final Map<int, Duration> timeoutOptions;
  final ValueChanged<bool> onLockOnBackgroundChanged;
  final ValueChanged<Duration> onInactivityTimeoutChanged;

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
          decoration: InputDecoration(labelText: 'inactivity_timeout'.tr()),
          items: [
            for (final entry in timeoutOptions.entries)
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
            if (value != null) onInactivityTimeoutChanged(value);
          },
        ),
      ],
    );
  }
}

class _BackupStep extends StatelessWidget {
  const _BackupStep({
    required this.autoExportEnabled,
    required this.autoExportFolderPath,
    required this.onAutoExportToggled,
  });

  final bool autoExportEnabled;
  final String? autoExportFolderPath;
  final void Function(bool) onAutoExportToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('setup_backup_intro'.tr()),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text('auto_export'.tr()),
          subtitle: Text('auto_export_hint'.tr()),
          value: autoExportEnabled,
          onChanged: onAutoExportToggled,
        ),
        if (autoExportFolderPath != null) ...[
          const SizedBox(height: 8),
          Text(
            autoExportFolderPath!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
