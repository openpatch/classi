import 'package:flutter/widgets.dart';

import '../theme/app_ui.dart';

/// Centres [child] horizontally and constrains its width to
/// [kContentMaxWidth], preventing content from stretching uncomfortably wide
/// on desktop and large-tablet screens.
class ContentConstraints extends StatelessWidget {
  const ContentConstraints({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: child,
      ),
    );
  }
}
