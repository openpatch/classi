import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import '../../shared/widgets/app_error_state.dart';

class RecoverAccessScreen extends ConsumerStatefulWidget {
  const RecoverAccessScreen({super.key});

  @override
  ConsumerState<RecoverAccessScreen> createState() =>
      _RecoverAccessScreenState();
}

class _RecoverAccessScreenState extends ConsumerState<RecoverAccessScreen> {
  final _recoveryKeyController = TextEditingController();
  final _newPassphraseController = TextEditingController();
  final _confirmPassphraseController = TextEditingController();
  bool _isRecovering = false;

  @override
  void dispose() {
    _recoveryKeyController.dispose();
    _newPassphraseController.dispose();
    _confirmPassphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);

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
                              'recover_access_title'.tr(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text('recover_access_intro'.tr()),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _recoveryKeyController,
                              autofocus: true,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                labelText: 'recovery_key'.tr(),
                                errorText:
                                    session.errorCode ==
                                        AppSessionErrorCode.invalidRecoveryKey
                                    ? AppSessionErrorCode
                                          .invalidRecoveryKey
                                          .translationKey
                                          .tr()
                                    : session.errorCode ==
                                          AppSessionErrorCode
                                              .recoveryNotAvailable
                                    ? AppSessionErrorCode
                                          .recoveryNotAvailable
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
                            const SizedBox(height: 12),
                            TextField(
                              controller: _newPassphraseController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'new_passphrase'.tr(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _confirmPassphraseController,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'confirm_passphrase'.tr(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isRecovering ? null : _submit,
                                child: _isRecovering
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text('recover_access'.tr()),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _isRecovering
                                    ? null
                                    : () => context.go('/unlock'),
                                child: Text('back_to_unlock'.tr()),
                              ),
                            ),
                            if (session.status == AppSessionStatus.error) ...[
                              const SizedBox(height: 12),
                              AppErrorText(
                                message:
                                    session.errorCode?.translationKey.tr() ??
                                    'generic_error'.tr(),
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

  Future<void> _submit() async {
    final recoveryKey = _recoveryKeyController.text.trim();
    final newPassphrase = _newPassphraseController.text.trim();
    final confirmPassphrase = _confirmPassphraseController.text.trim();
    if (recoveryKey.isEmpty || newPassphrase.isEmpty) {
      return;
    }
    if (newPassphrase != confirmPassphrase) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('passphrase_mismatch'.tr())));
      return;
    }

    setState(() => _isRecovering = true);
    try {
      final success = await ref
          .read(appSessionProvider)
          .recoverAccess(
            recoveryKey: recoveryKey,
            newPassphrase: newPassphrase,
          );
      if (!mounted || !success) {
        return;
      }
      context.go('/today');
    } finally {
      if (mounted) {
        setState(() => _isRecovering = false);
      }
    }
  }
}
