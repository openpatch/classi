import 'dart:developer' as developer;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/storage/library_backup_service.dart';
import '../../core/sync/conflict_diff_service.dart';
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
  ConflictDiffSummary? _diff;
  bool _loadingDiff = false;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  Future<void> _loadDiff() async {
    setState(() => _loadingDiff = true);
    try {
      final summary = await ref
          .read(appSessionProvider)
          .conflictDiff(
            conflictRemotePath: widget.conflict.remotePath,
            canonicalRemotePath: widget.canonical.remotePath,
          );
      if (mounted) setState(() => _diff = summary);
    } on Object catch (error, stackTrace) {
      // The summary is an aid, not a prerequisite: both options stay on
      // screen without it. Swallowing the error here keeps an unawaited
      // future from tearing down the screen the user needs.
      developer.log(
        'Could not load the conflict diff',
        name: 'classi.sync',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _diff = null);
    } finally {
      if (mounted) setState(() => _loadingDiff = false);
    }
  }

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
            if (_loadingDiff)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_diff != null)
              _DiffSummaryCard(summary: _diff!),
            if (_loadingDiff || _diff != null)
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

class _DiffSummaryCard extends StatelessWidget {
  const _DiffSummaryCard({required this.summary});

  final ConflictDiffSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: appCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.medium),
                Text(
                  'conflict_diff_title'.tr(),
                  style: textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            if (summary.totalDifferences == 0)
              Text(
                'conflict_diff_identical'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              _DiffStatRow(
                icon: Icons.add_circle_outline,
                color: colorScheme.primary,
                label: 'conflict_diff_only_here'.tr(),
                count: summary.rowsOnlyOnThisDevice,
              ),
              _DiffStatRow(
                icon: Icons.cloud_download_outlined,
                color: colorScheme.primary,
                label: 'conflict_diff_only_server'.tr(),
                count: summary.rowsOnlyOnServer,
              ),
              if (summary.rowsChangedOnBoth > 0)
                _DiffStatRow(
                  icon: Icons.warning_amber_outlined,
                  color: colorScheme.error,
                  label: 'conflict_diff_changed_both'.tr(),
                  count: summary.rowsChangedOnBoth,
                ),
              const SizedBox(height: AppSpacing.small),
              ...summary.tableSummaries.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xSmall),
                  child: Text(
                    t.changedOnBoth > 0
                        ? 'conflict_diff_table_line_conflicting'.tr(
                            namedArgs: {
                              'table': t.displayNameKey.tr(),
                              'here': '${t.onlyOnThisDevice}',
                              'server': '${t.onlyOnServer}',
                              'both': '${t.changedOnBoth}',
                            },
                          )
                        : 'conflict_diff_table_line'.tr(
                            namedArgs: {
                              'table': t.displayNameKey.tr(),
                              'here': '${t.onlyOnThisDevice}',
                              'server': '${t.onlyOnServer}',
                            },
                          ),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DiffStatRow extends StatelessWidget {
  const _DiffStatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xSmall),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.small),
          Text('$count $label'),
        ],
      ),
    );
  }
}
