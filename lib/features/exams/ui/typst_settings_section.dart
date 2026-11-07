import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../exam_providers.dart';
import '../typst/typst_service.dart';

final _typstVersionProvider = FutureProvider.autoDispose<String>((ref) async {
  final binary = await ref.watch(typstBinaryPathProvider.future);
  return TypstService(configuredBinary: binary).version();
});

/// Where to find the `typst` binary on this computer (desktop only).
class TypstSettingsSection extends ConsumerWidget {
  const TypstSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final binary = ref.watch(typstBinaryPathProvider).value;
    final version = ref.watch(_typstVersionProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('typst_settings_hint'.tr(), style: theme.textTheme.bodySmall),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.terminal),
          title: Text(binary ?? 'typst_binary_automatic'.tr()),
          subtitle: version.when(
            data: Text.new,
            loading: () => Text('typst_checking'.tr()),
            error: (error, _) => Text(
              '$error',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => _choose(context, ref),
              child: Text('typst_binary_choose'.tr()),
            ),
            if (binary != null)
              TextButton(
                onPressed: () => _set(ref, null),
                child: Text('typst_binary_reset'.tr()),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final session = ref.read(appSessionProvider);
    session.suspendBackgroundLock();
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        dialogTitle: 'typst_binary_choose'.tr(),
      );
    } finally {
      session.resumeBackgroundLock();
    }
    final path = result?.files.single.path;
    if (path != null) await _set(ref, path);
  }

  Future<void> _set(WidgetRef ref, String? path) async {
    await ref.read(typstSettingsStoreProvider).setBinaryPath(path);
    ref.read(typstSettingsRevisionProvider.notifier).state++;
  }
}
