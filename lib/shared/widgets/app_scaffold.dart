import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExporting = ref.watch(
      appSessionProvider.select((s) => s.isExporting),
    );
    final isWide = MediaQuery.sizeOf(context).width > 700 || Platform.isWindows;
    final isExtended = MediaQuery.sizeOf(context).width > 1200;
    final selectedIndex = _selectedIndex(context);
    final destinations = [
      _NavigationItem(
        path: '/groups',
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: 'groups',
      ),
      _NavigationItem(
        path: '/lists',
        icon: Icons.checklist_outlined,
        selectedIcon: Icons.checklist,
        label: 'lists',
      ),
      _NavigationItem(
        path: '/notes',
        icon: Icons.sticky_note_2_outlined,
        selectedIcon: Icons.sticky_note_2,
        label: 'notes',
      ),
      _NavigationItem(
        path: '/settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'settings',
      ),
    ];

    final Widget scaffold;
    if (isWide) {
      scaffold = Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selectedIndex,
              extended: isExtended,
              labelType: isExtended
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
              destinations: [
                for (final destination in destinations)
                  NavigationRailDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: Text(destination.label.tr()),
                  ),
              ],
              trailing: const Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: _BackupStatusIndicator(dense: true),
                  ),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: child,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BackupStatusIndicator(dense: false),
            NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].path),
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label.tr(),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget result = scaffold;

    if (isExporting) {
      result = Stack(
        children: [
          AbsorbPointer(child: result),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
        ],
      );
    }

    return result;
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/lists')) {
      return 1;
    }
    if (location.startsWith('/notes')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
    return 0;
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.path,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// A small, always-visible WebDAV backup status indicator, shown next to
/// the main navigation on every screen. Tapping it triggers an immediate
/// manual export.
///
/// Only shown once WebDAV auto-export is configured and enabled — this
/// mirrors the "Export now" button already gated the same way in Settings,
/// and stays out of the way for users who haven't set up sync.
class _BackupStatusIndicator extends ConsumerWidget {
  const _BackupStatusIndicator({required this.dense});

  /// `true` renders a compact icon button (for the desktop navigation
  /// rail); `false` renders a full-width tappable strip with a status
  /// label (for the mobile bottom navigation bar).
  final bool dense;

  static const Set<String> _exportErrorCodes = {
    'backup_export_failed',
    'backup_export_busy',
    'backup_export_conflict',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionProvider);
    if (!session.isWebDavConfigured || !session.webDavAutoExportEnabled) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isExporting = session.isExporting;
    final hasExportError =
        session.lastBackupMessageIsError &&
        _exportErrorCodes.contains(session.lastBackupMessageCode);

    final IconData icon;
    final String labelKey;
    final Color color;
    if (isExporting) {
      icon = Icons.cloud_sync_outlined;
      labelKey = 'exporting_backup';
      color = colorScheme.onSurfaceVariant;
    } else if (hasExportError) {
      icon = Icons.cloud_off_outlined;
      labelKey = session.lastBackupMessageCode!;
      color = colorScheme.error;
    } else if (session.hasPendingAutoImport) {
      icon = Icons.cloud_sync_outlined;
      labelKey = 'webdav_sync_behind';
      color = colorScheme.primary;
    } else {
      icon = Icons.cloud_done_outlined;
      labelKey = 'webdav_sync_current';
      color = colorScheme.primary;
    }

    final iconWidget = isExporting
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          )
        : Icon(icon, color: color);

    if (dense) {
      return IconButton(
        onPressed: isExporting ? null : () => _exportNow(context, ref),
        tooltip: labelKey.tr(),
        icon: iconWidget,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isExporting ? null : () => _exportNow(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  labelKey.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportNow(BuildContext context, WidgetRef ref) async {
    final session = ref.read(appSessionProvider);
    final errorCode = await session.exportNow();
    if (!context.mounted) return;
    final code = errorCode ?? session.lastBackupMessageCode ?? 'backup_exported';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(code.tr())));
  }
}
