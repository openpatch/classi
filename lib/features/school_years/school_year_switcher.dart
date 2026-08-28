import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

/// The school year picker in the app shell.
///
/// Lives next to the navigation rather than on any one screen, because the
/// choice scopes the whole app: which groups are listed, which timetable is
/// shown, which lessons are in reach. Keeping it always visible also makes it
/// obvious *why* last year's groups are not on screen.
class SchoolYearSwitcher extends ConsumerWidget {
  const SchoolYearSwitcher({required this.extended, super.key});

  /// Whether there is room for the year's label next to the icon.
  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(activeSchoolYearControllerProvider);
    final active = controller.activeSchoolYear;
    if (!controller.isLoaded || active == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isArchived = active.archivedAt != null;
    final foreground = isArchived
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    return MenuAnchor(
      builder: (context, menuController, _) {
        final button = TextButton.icon(
          onPressed: () => menuController.isOpen
              ? menuController.close()
              : menuController.open(),
          icon: Icon(
            isArchived ? Icons.inventory_2_outlined : Icons.school_outlined,
            size: 18,
            color: foreground,
          ),
          label: extended
              ? Text(
                  active.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
                )
              : const SizedBox.shrink(),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: extended ? 12 : 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );

        return Tooltip(
          message: extended ? 'school_year'.tr() : active.label,
          child: button,
        );
      },
      menuChildren: [
        for (final year in controller.schoolYears)
          MenuItemButton(
            leadingIcon: Icon(
              year.id == active.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
            ),
            trailingIcon: year.archivedAt != null
                ? const Icon(Icons.inventory_2_outlined, size: 16)
                : null,
            onPressed: () => ref
                .read(activeSchoolYearControllerProvider)
                .select(year.id),
            child: Text(year.label),
          ),
        const Divider(height: 8),
        MenuItemButton(
          leadingIcon: const Icon(Icons.tune, size: 18),
          onPressed: () => context.go('/years'),
          child: Text('manage_school_years'.tr()),
        ),
      ],
    );
  }
}
