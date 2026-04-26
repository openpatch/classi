import 'package:flutter/material.dart';

import '../theme/app_ui.dart';

class SurfaceListTile extends StatelessWidget {
  const SurfaceListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.contentPadding,
    super.key,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
      tileColor:
          backgroundColor ??
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      minVerticalPadding: 0,
      contentPadding: contentPadding ?? appSurfaceTilePadding,
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}
