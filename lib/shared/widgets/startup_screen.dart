import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import 'app_error_state.dart';

class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    final errorText =
        session.errorCode?.translationKey.tr() ?? 'generic_error'.tr();

    if (session.status == AppSessionStatus.error) {
      return AppErrorScaffold(
        title: errorText,
        action: FilledButton(
          onPressed: () => ref.read(appSessionProvider).initialize(),
          child: Text('retry'.tr()),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('loading_app'.tr(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
