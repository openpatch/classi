import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/storage/library_backup_service.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/content_constraints.dart';

/// Guided resolution for a WebDAV sync conflict: shown when this device's
/// export found the canonical backup had moved on to a revision it never
/// saw, so it uploaded its own changes as a separate `_CONFLICT_` copy
/// instead of overwriting the newer backup (see [WebDavSyncConflictException]).
///
/// Both versions are shown side by side with their device and time so the
/// teacher can tell which one is theirs and pick which becomes the active
/// library. Nothing is deleted by resolving here — the version not chosen
/// stays available in "Available backups" afterward.
class BackupConflictScreen extends ConsumerStatefulWidget {
  const BackupConflictScreen({
    required this.canonical,
    required this.conflict,
    super.key,
  });

  /// The current backup on the server that this device's export conflicted
  /// with.
  final WebDavBackupEntry canonical;

  /// The `_CONFLICT_` copy this device uploaded of its own local content.
  final WebDavBackupEntry conflict;

  @override
  ConsumerState<BackupConflictScreen> createState() =>
      _BackupConflictScreenState();
}

class _BackupConflictScreenState extends ConsumerState<BackupConflictScreen> {
  bool _resolving = false;

  @override
  Widget build(BuildContext context) {
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('resolve_conflict'.tr())),
      body: ContentConstraints(
        child: ListView(
          padding: appScreenPadding,
          children: [
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: appCardPadding,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        'backup_conflict_explanation'.tr(),
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            _ConflictOptionCard(
              icon: Icons.smartphone_outlined,
              title: 'this_device_version'.tr(),
              entry: widget.conflict,
              localeTag: localeTag,
              actionLabel: 'keep_this_device_version'.tr(),
              busy: _resolving,
              onSelect: _keepThisDevice,
            ),
            const SizedBox(height: AppSpacing.medium),
            _ConflictOptionCard(
              icon: Icons.cloud_outlined,
              title: 'server_version'.tr(),
              entry: widget.canonical,
              localeTag: localeTag,
              actionLabel: 'use_server_version'.tr(),
              busy: _resolving,
              onSelect: _useServerVersion,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _keepThisDevice() async {
    setState(() => _resolving = true);
    try {
      final errorCode = await ref
          .read(appSessionProvider)
          .keepThisDeviceVersionAfterConflict(
            canonicalRevision: widget.canonical.revision,
          );
      if (!mounted) return;
      if (errorCode == null) {
        // The canonical backup now carries this device's content, so the
        // copy is reconciled: archive it out of the conflict namespace or
        // every device keeps reporting the conflict.
        await ref
            .read(appSessionProvider)
            .markConflictResolved(conflictFileName: widget.conflict.fileName);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('conflict_resolved'.tr())));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorCode.tr())));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _useServerVersion() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'use_server_version'.tr(),
      body: 'restore_backup_overwrite_warning'.tr(),
      confirmKey: 'restore_backup',
    );
    if (!confirmed || !mounted) return;

    setState(() => _resolving = true);
    try {
      // Restoring the open library locks the session, which pops this screen
      // out from under us, so the whole resolution — restore *and* archiving
      // the conflict copy — is handed to the session in one call. Anything
      // this method still wanted to do afterwards may never run.
      final errorCode = await ref
          .read(appSessionProvider)
          .useServerVersionAfterConflict(
            canonicalRemotePath: widget.canonical.remotePath,
            conflictFileName: widget.conflict.fileName,
          );
      if (!mounted) return;
      if (errorCode == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('backup_restored'.tr())));
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorCode.tr())));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }
}

class _ConflictOptionCard extends StatelessWidget {
  const _ConflictOptionCard({
    required this.icon,
    required this.title,
    required this.entry,
    required this.localeTag,
    required this.actionLabel,
    required this.busy,
    required this.onSelect,
  });

  final IconData icon;
  final String title;
  final WebDavBackupEntry entry;
  final String localeTag;
  final String actionLabel;
  final bool busy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final modifiedAt = entry.modifiedAt;
    final dateStr = modifiedAt != null
        ? DateFormat.yMd(localeTag).add_Hm().format(modifiedAt.toLocal())
        : null;
    final sizeStr = entry.sizeBytes != null
        ? _formatBytes(entry.sizeBytes!)
        : null;
    final subtitleParts = [entry.deviceName ?? 'unknown_device'.tr(), ?dateStr, ?sizeStr];

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              subtitleParts.join(' • '),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: busy ? null : onSelect,
                child: busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }
}
