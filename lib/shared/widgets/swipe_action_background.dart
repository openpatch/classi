import 'package:flutter/material.dart';

import '../theme/app_ui.dart';

class SwipeActionBackground extends StatelessWidget {
  const SwipeActionBackground({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isLeading = alignment == Alignment.centerLeft;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.xLarge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isLeading
            ? [
                Icon(icon, color: foregroundColor),
                const SizedBox(width: AppSpacing.small),
                Text(label, style: TextStyle(color: foregroundColor)),
              ]
            : [
                Text(label, style: TextStyle(color: foregroundColor)),
                const SizedBox(width: AppSpacing.small),
                Icon(icon, color: foregroundColor),
              ],
      ),
    );
  }
}
