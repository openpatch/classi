import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);

    final message = switch (session.status) {
      AppSessionStatus.loading => 'loading_app'.tr(),
      AppSessionStatus.error => session.errorMessage ?? 'generic_error'.tr(),
      AppSessionStatus.needsSetup => 'loading_app'.tr(),
      AppSessionStatus.locked => 'loading_app'.tr(),
      AppSessionStatus.ready => 'loading_app'.tr(),
    };

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(message, textAlign: TextAlign.center),
              if (session.status == AppSessionStatus.error) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.read(appSessionProvider).initialize(),
                  child: Text('retry'.tr()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
