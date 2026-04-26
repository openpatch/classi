import 'package:flutter/material.dart';

class SecurityActivityBoundary extends StatelessWidget {
  const SecurityActivityBoundary({
    required this.onActivity,
    required this.child,
    super.key,
  });

  final VoidCallback onActivity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        onActivity();
        return KeyEventResult.ignored;
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => onActivity(),
        onPointerSignal: (_) => onActivity(),
        child: child,
      ),
    );
  }
}
