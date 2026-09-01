import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import '../../shared/widgets/app_error_state.dart';
import '../../shared/widgets/session_error_report.dart';
import 'auto_import_prompt_card.dart';
import 'database_selection_sheet.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _controller = TextEditingController();
  bool _isUnlocking = false;
  bool _biometricAvailable = false;
  bool _isCheckingWebDavStatus = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await ref.read(appSessionProvider).isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final showBiometric = _biometricAvailable && session.biometricEnabled;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final showWebDavStatus =
        session.isWebDavConfigured ||
        session.webDavAutoExportEnabled ||
        session.webDavAutoImportEnabled ||
        session.lastExportedAt != null ||
        session.lastImportedAt != null ||
        session.lastBackupMessageCode != null;

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
                              'unlock_title'.tr(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text('unlock_intro'.tr()),
                            const SizedBox(height: 12),
                            FutureBuilder<String>(
                              future: ref
                                  .read(appSessionProvider)
                                  .currentDatabasePath(),
                              builder: (context, snapshot) {
                                return SelectableText(
                                  snapshot.data ?? '',
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const AutoImportPromptCard(),
                            if (showWebDavStatus) ...[
                              const SizedBox(height: 12),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'webdav_sync_status_title'.tr(),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        session.webDavSyncStatus.translationKey
                                            .tr(),
                                      ),
                                      if (session
                                              .pendingImportRemoteModifiedAt !=
                                          null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'newer_backup_exported_at'.tr(
                                            namedArgs: {
                                              'datetime':
                                                  DateFormat.yMd(
                                                    localeTag,
                                                  ).add_Hm().format(
                                                    session
                                                        .pendingImportRemoteModifiedAt!
                                                        .toLocal(),
                                                  ),
                                            },
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      if (session.lastExportedAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'last_exported_at'.tr(
                                            namedArgs: {
                                              'datetime':
                                                  DateFormat.yMd(
                                                    localeTag,
                                                  ).add_Hm().format(
                                                    session.lastExportedAt!
                                                        .toLocal(),
                                                  ),
                                            },
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      if (session.lastImportedAt != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'last_imported_at'.tr(
                                            namedArgs: {
                                              'datetime':
                                                  DateFormat.yMd(
                                                    localeTag,
                                                  ).add_Hm().format(
                                                    session.lastImportedAt!
                                                        .toLocal(),
                                                  ),
                                            },
                                          ),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      if (session.lastBackupMessageCode !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          session.lastBackupMessageCode!.tr(),
                                          style: TextStyle(
                                            color:
                                                session.lastBackupMessageIsError
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.error
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          onPressed:
                                              _isCheckingWebDavStatus ||
                                                  _isUnlocking
                                              ? null
                                              : _refreshWebDavStatus,
                                          icon: _isCheckingWebDavStatus
                                              ? const SizedBox.square(
                                                  dimension: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Icon(Icons.sync),
                                          label: Text(
                                            'webdav_sync_check_now'.tr(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            TextField(
                              controller: _controller,
                              obscureText: true,
                              autofocus: !showBiometric,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'setup_passphrase'.tr(),
                                errorText:
                                    session.errorCode ==
                                        AppSessionErrorCode.invalidPassphrase
                                    ? AppSessionErrorCode
                                          .invalidPassphrase
                                          .translationKey
                                          .tr()
                                    : session.errorCode ==
                                          AppSessionErrorCode
                                              .integrityCheckFailed
                                    ? AppSessionErrorCode
                                          .integrityCheckFailed
                                          .translationKey
                                          .tr()
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isUnlocking ? null : _submit,
                                child: _isUnlocking
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text('unlock'.tr()),
                              ),
                            ),
                            if (showBiometric) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _isUnlocking
                                      ? null
                                      : _unlockWithBiometrics,
                                  icon: const Icon(Icons.fingerprint),
                                  label: Text('unlock_with_biometrics'.tr()),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            FutureBuilder<bool>(
                              future: ref
                                  .read(appSessionProvider)
                                  .supportsRecovery(),
                              builder: (context, snapshot) {
                                if (snapshot.data != true) {
                                  return const SizedBox.shrink();
                                }
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _isUnlocking
                                        ? null
                                        : () => context.go('/recover'),
                                    child: Text('recover_with_key'.tr()),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _isUnlocking
                                    ? null
                                    : () => showDatabaseSelectionSheet(
                                        context: context,
                                        ref: ref,
                                      ),
                                icon: const Icon(Icons.storage_outlined),
                                label: Text('choose_database'.tr()),
                              ),
                            ),
                            if (session.status == AppSessionStatus.error) ...[
                              const SizedBox(height: 12),
                              AppErrorText(
                                message:
                                    session.errorCode?.translationKey.tr() ??
                                    'generic_error'.tr(),
                              ),
                              if (session.errorDetails != null) ...[
                                const SizedBox(height: 8),
                                ErrorReportDetails(
                                  report: session.errorDetails!.toReport(
                                    session.errorCode?.translationKey.tr() ??
                                        'generic_error'.tr(),
                                  ),
                                ),
                              ],
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

  Future<void> _submit() async {
    final passphrase = _controller.text.trim();
    if (passphrase.isEmpty) {
      return;
    }

    setState(() => _isUnlocking = true);
    try {
      await ref.read(appSessionProvider).unlock(passphrase);
    } finally {
      if (mounted) {
        setState(() => _isUnlocking = false);
      }
    }
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() => _isUnlocking = true);
    try {
      await ref
          .read(appSessionProvider)
          .unlockWithBiometrics(localizedReason: 'biometric_reason'.tr());
    } finally {
      if (mounted) setState(() => _isUnlocking = false);
    }
  }

  Future<void> _refreshWebDavStatus() async {
    setState(() => _isCheckingWebDavStatus = true);
    try {
      await ref.read(appSessionProvider).refreshWebDavSyncStatus();
    } finally {
      if (mounted) {
        setState(() => _isCheckingWebDavStatus = false);
      }
    }
  }
}
