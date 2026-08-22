import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'empty_state.dart';

/// Shows a [SnackBar] styled with the theme's error color.
void showErrorSnackBar(BuildContext context, String message, {
  Object? error,
  StackTrace? stackTrace,
  String supportEmail = "classi@openpatch.org"
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.error,
      content: Text(
        message, 
        style: TextStyle(color: colorScheme.onError),
      ),
      action: stackTrace != null
          ? SnackBarAction(
              label: 'Report',
              textColor: colorScheme.onError,
              onPressed: () => _sendErrorEmail(
                email: supportEmail,
                message: message,
                error: error,
                stackTrace: stackTrace,
              ),
            )
          : null,
    ),
  );
}

Future<void> _sendErrorEmail({
  required String email,
  required String message,
  Object? error,
  StackTrace? stackTrace,
}) async {
  final subject = Uri.encodeComponent('App Error Report: $message');
  final body = Uri.encodeComponent(
    'Error Details:\n$message\n\n'
    '${error != null ? "Exception:\n$error\n\n" : ""}'
    'Stack Trace:\n$stackTrace',
  );

  final Uri mailUri = Uri.parse('mailto:$email?subject=$subject&body=$body');

  if (await canLaunchUrl(mailUri)) {
    await launchUrl(mailUri);
  }
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
