import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';

class AutoImportPromptCard extends ConsumerStatefulWidget {
  const AutoImportPromptCard({super.key});

  @override
  ConsumerState<AutoImportPromptCard> createState() =>
      _AutoImportPromptCardState();
}

class _AutoImportPromptCardState extends ConsumerState<AutoImportPromptCard> {
  bool _isRestoring = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionProvider);
    if (!session.hasPendingAutoImport) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'newer_backup_available'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('newer_backup_available_hint'.tr()),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isRestoring ? null : _restoreBackup,
                icon: _isRestoring
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore_outlined),
                label: Text('restore_backup'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('newer_backup_available'.tr()),
        content: Text('restore_backup_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('restore_backup'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isRestoring = true);
    try {
      final errorCode = await ref
          .read(appSessionProvider)
          .restorePendingAutoImport();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((errorCode ?? 'backup_restored').tr())),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }
}
