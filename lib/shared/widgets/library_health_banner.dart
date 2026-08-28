import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';

/// A single strip above the content for things the teacher should know about
/// the library as a whole.
///
/// At most one is shown at a time, most urgent first: a damaged database beats
/// "you are looking at last year", which beats "you have no backup". Stacking
/// them would push the actual screen off the top.
class LibraryHealthBanner extends ConsumerWidget {
  const LibraryHealthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasIntegrityWarning = ref.watch(
      appSessionProvider.select((session) => session.hasIntegrityWarning),
    );

    if (hasIntegrityWarning) {
      return _Banner(
        icon: Icons.error_outline,
        message: 'library_integrity_warning'.tr(),
        background: theme.colorScheme.errorContainer,
        foreground: theme.colorScheme.onErrorContainer,
        actionLabel: 'settings'.tr(),
        onAction: () => context.go('/settings'),
      );
    }

    final isArchivedYear = ref.watch(
      activeSchoolYearControllerProvider.select(
        (controller) => controller.isViewingArchivedYear,
      ),
    );

    if (isArchivedYear) {
      final label = ref.watch(
        activeSchoolYearControllerProvider.select(
          (controller) => controller.activeSchoolYear?.label ?? '',
        ),
      );
      return _Banner(
        icon: Icons.inventory_2_outlined,
        message: 'viewing_archived_school_year'.tr(args: [label]),
        background: theme.colorScheme.surfaceContainerHighest,
        foreground: theme.colorScheme.onSurfaceVariant,
      );
    }

    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color background;
  final Color foreground;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: onAction == null ? 16 : 8,
          top: 8,
          bottom: 8,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: foreground),
              ),
            ),
            if (onAction != null && actionLabel != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: foreground),
                child: Text(actionLabel!),
              ),
          ],
        ),
      ),
    );
  }
}
