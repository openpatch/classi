import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A small mark for anything linked to WebUntis: a group standing for a
/// course or class, a student carrying a WebUntis id.
///
/// Linked and hand-made entries otherwise look the same, and whether a
/// student is linked decides whether WebUntis attendance reaches them.
class WebUntisBadge extends StatelessWidget {
  const WebUntisBadge({required this.tooltip, this.size = 16, super.key});

  /// Translation key of what the mark means here.
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip.tr(),
      child: Icon(
        Icons.cloud_sync_outlined,
        size: size,
        color: Theme.of(context).colorScheme.primary,
        semanticLabel: tooltip.tr(),
      ),
    );
  }
}

/// [title] with a [WebUntisBadge] after it when [linked].
class WebUntisLinkedTitle extends StatelessWidget {
  const WebUntisLinkedTitle({
    required this.title,
    required this.linked,
    required this.tooltip,
    super.key,
  });

  final Widget title;
  final bool linked;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    if (!linked) return title;
    return Row(
      children: [
        Flexible(child: title),
        const SizedBox(width: 6),
        WebUntisBadge(tooltip: tooltip),
      ],
    );
  }
}
