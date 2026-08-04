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

    final remoteModifiedAt = session.pendingImportRemoteModifiedAt;
    final deviceName = session.pendingImportDeviceName;
    final lastExportedAt = session.lastExportedAt;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    if (_isRestoring) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('restoring_backup'.tr()),
            ],
          ),
        ),
      );
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
            if (remoteModifiedAt != null)
              Text(
                (deviceName != null
                        ? 'newer_backup_exported_from_at'
                        : 'newer_backup_exported_at')
                    .tr(
                      namedArgs: {
                        'device': ?deviceName,
                        'datetime': DateFormat.yMd(localeTag)
                            .add_Hm()
                            .format(remoteModifiedAt.toLocal()),
                      },
                    ),
              )
            else
              Text('newer_backup_available_hint'.tr()),
            if (lastExportedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'restore_will_discard_since'.tr(
                  namedArgs: {
                    'datetime': DateFormat.yMd(localeTag)
                        .add_Hm()
                        .format(lastExportedAt.toLocal()),
                  },
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _isRestoring ? null : _dismiss,
                  child: Text('dismiss'.tr()),
                ),
                FilledButton.icon(
                  onPressed: _isRestoring ? null : _restoreBackup,
                  icon: _isRestoring
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_outlined),
                  label: Text('restore_backup'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dismiss() async {
    await ref.read(appSessionProvider).dismissPendingImport();
  }

  Future<void> _restoreBackup() async {
    final session = ref.read(appSessionProvider);
    final remoteModifiedAt = session.pendingImportRemoteModifiedAt;
    final deviceName = session.pendingImportDeviceName;
    final lastExportedAt = session.lastExportedAt;
    final localeTag = Localizations.localeOf(context).toLanguageTag();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('newer_backup_available'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('restore_backup_confirm'.tr()),
            if (lastExportedAt != null || remoteModifiedAt != null) ...[
              const SizedBox(height: 12),
              if (remoteModifiedAt != null)
                Text(
                  (deviceName != null
                          ? 'newer_backup_exported_from_at'
                          : 'newer_backup_exported_at')
                      .tr(
                        namedArgs: {
                          'device': ?deviceName,
                          'datetime': DateFormat.yMd(localeTag)
                              .add_Hm()
                              .format(remoteModifiedAt.toLocal()),
                        },
                      ),
                ),
              if (lastExportedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'restore_will_discard_since'.tr(
                      namedArgs: {
                        'datetime': DateFormat.yMd(localeTag)
                            .add_Hm()
                            .format(lastExportedAt.toLocal()),
                      },
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
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
