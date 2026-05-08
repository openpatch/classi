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
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    } else {
      scaffold = Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
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
