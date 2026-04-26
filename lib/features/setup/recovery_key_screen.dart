import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

class RecoveryKeyScreen extends ConsumerStatefulWidget {
  const RecoveryKeyScreen({super.key});

  @override
  ConsumerState<RecoveryKeyScreen> createState() => _RecoveryKeyScreenState();
}

class _RecoveryKeyScreenState extends ConsumerState<RecoveryKeyScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    final recoveryKey = session.pendingRecoveryKey;
    if (recoveryKey == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/groups');
        }
      });
    }

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
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'recovery_key_title'.tr(),
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 12),
                            Text('recovery_key_intro'.tr()),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SelectableText(
                                recoveryKey ?? '',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(letterSpacing: 1.2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'recovery_key_print_hint'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: recoveryKey == null
                                    ? null
                                    : () => _copyRecoveryKey(
                                        context,
                                        recoveryKey,
                                      ),
                                icon: const Icon(Icons.copy_outlined),
                                label: Text('copy_recovery_key'.tr()),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _confirmed,
                              onChanged: (value) =>
                                  setState(() => _confirmed = value ?? false),
                              title: Text('recovery_key_confirm_saved'.tr()),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _confirmed ? _continue : null,
                                child: Text('continue_to_app'.tr()),
                              ),
                            ),
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

  Future<void> _copyRecoveryKey(
    BuildContext context,
    String recoveryKey,
  ) async {
    await Clipboard.setData(ClipboardData(text: recoveryKey));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('recovery_key_copied'.tr())));
  }

  void _continue() {
    ref.read(appSessionProvider).clearPendingRecoveryKey();
    context.go('/groups');
  }
}
