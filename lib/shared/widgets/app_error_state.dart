import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'empty_state.dart';

/// Shows a [SnackBar] styled with the theme's error color.
void showErrorSnackBar(BuildContext context, String message) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: TextStyle(color: colorScheme.onError)),
      backgroundColor: colorScheme.error,
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({this.title, this.body, this.action, super.key});

  final String? title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: title ?? 'generic_error'.tr(),
      body: body ?? 'generic_error_hint'.tr(),
      action: action,
    );
  }
}

class AppErrorScaffold extends StatelessWidget {
  const AppErrorScaffold({this.title, this.body, this.action, super.key});

  final String? title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppErrorState(title: title, body: body, action: action),
    );
  }
}

class AppErrorText extends StatelessWidget {
  const AppErrorText({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message ?? 'generic_error'.tr(),
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
