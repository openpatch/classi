import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import '../../shared/widgets/app_error_state.dart';
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

  @override
  void dispose() {
    _controller.dispose();
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
                            const SizedBox(height: 24),
                            TextField(
                              controller: _controller,
                              obscureText: true,
                              autofocus: true,
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
      final success = await ref.read(appSessionProvider).unlock(passphrase);
      if (!mounted || !success) {
        return;
      }
      context.go('/groups');
    } finally {
      if (mounted) {
        setState(() => _isUnlocking = false);
      }
    }
  }
}
