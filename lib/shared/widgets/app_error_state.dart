import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'empty_state.dart';

const String supportEmail = 'classi@openpatch.org';

/// A mailto URL longer than this tends to be rejected or truncated by mail
/// clients, so the stack trace is shortened for the mail draft. The clipboard
/// fallback always carries the full report.
const int _maxMailBodyLength = 4000;

/// Everything Classi knows about a failure, in a shape the UI can still hand
/// to [sendErrorReport] long after the failure happened.
@immutable
class ErrorReport {
  const ErrorReport({
    required this.message,
    this.operation,
    this.error,
    this.stackTrace,
    this.occurredAt,
  });

  /// The user-facing message that was shown alongside the failure.
  final String message;

  /// What Classi was doing, e.g. `open the library`.
  final String? operation;

  final Object? error;
  final StackTrace? stackTrace;
  final DateTime? occurredAt;
}

/// Renders [report] as the plain text a teacher can send to support.
Future<String> buildErrorReportText(ErrorReport report) async {
  String? version;
  try {
    final info = await PackageInfo.fromPlatform();
    version = '${info.version}+${info.buildNumber}';
  } catch (_) {
    // Package metadata is a nice-to-have; never let it swallow the report.
  }

  final buffer = StringBuffer()..writeln(report.message);
  if (report.operation != null) {
    buffer.writeln('Operation: ${report.operation}');
  }
  buffer
    ..writeln('App: classi ${version ?? 'unknown'}')
    ..writeln('Platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}')
    ..writeln('Locale: ${Intl.getCurrentLocale()}')
    ..writeln(
      'Time: ${(report.occurredAt ?? DateTime.now()).toIso8601String()}',
    );
  if (report.error != null) {
    buffer
      ..writeln()
      ..writeln('Exception:')
      ..writeln(report.error);
  }
  if (report.stackTrace != null) {
    buffer
      ..writeln()
      ..writeln('Stack trace:')
      ..writeln(report.stackTrace);
  }
  return buffer.toString();
}

/// Opens a mail draft for [report], falling back to the clipboard when no mail
/// client answers — the report must never be a dead end.
Future<void> sendErrorReport(BuildContext context, ErrorReport report) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final text = await buildErrorReportText(report);

  final mailBody = text.length > _maxMailBodyLength
      ? '${text.substring(0, _maxMailBodyLength)}\n…'
      : text;
  final mailUri = Uri.parse(
    'mailto:$supportEmail'
    '?subject=${Uri.encodeComponent('Classi error report: ${report.message}')}'
    '&body=${Uri.encodeComponent(mailBody)}',
  );

  var launched = false;
  try {
    launched = await launchUrl(mailUri);
  } catch (_) {
    launched = false;
  }
  if (launched) {
    return;
  }

  await Clipboard.setData(ClipboardData(text: text));
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        'error_report_copied'.tr(namedArgs: {'email': supportEmail}),
      ),
    ),
  );
}

/// Copies the full report and confirms it, for teachers who would rather paste
/// it somewhere themselves.
Future<void> copyErrorReport(BuildContext context, ErrorReport report) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  await Clipboard.setData(
    ClipboardData(text: await buildErrorReportText(report)),
  );
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        'error_report_copied'.tr(namedArgs: {'email': supportEmail}),
      ),
    ),
  );
}

/// Shows a [SnackBar] styled with the theme's error color.
void showErrorSnackBar(
  BuildContext context,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final report = stackTrace == null && error == null
      ? null
      : ErrorReport(message: message, error: error, stackTrace: stackTrace);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: colorScheme.error,
      content: Text(message, style: TextStyle(color: colorScheme.onError)),
      action: report == null
          ? null
          : SnackBarAction(
              label: 'report_error'.tr(),
              textColor: colorScheme.onError,
              onPressed: () => sendErrorReport(context, report),
            ),
    ),
  );
}

/// The technical detail behind an error screen, collapsed by default, plus the
/// buttons that get it to support.
class ErrorReportDetails extends StatelessWidget {
  const ErrorReportDetails({
    required this.report,
    this.showTechnicalDetails = true,
    super.key,
  });

  final ErrorReport report;

  /// Whether to offer the expandable stack trace. Inline error states sit in
  /// tight boxes where the extra height would overflow, so they only show the
  /// buttons.
  final bool showTechnicalDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = !showTechnicalDetails
        ? ''
        : [
            if (report.error != null) '${report.error}',
            if (report.stackTrace != null) '${report.stackTrace}',
          ].join('\n\n');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => sendErrorReport(context, report),
              icon: const Icon(Icons.mail_outline),
              label: Text('report_error'.tr()),
            ),
            TextButton.icon(
              onPressed: () => copyErrorReport(context, report),
              icon: const Icon(Icons.copy_all_outlined),
              label: Text('copy_error_details'.tr()),
            ),
          ],
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'error_details'.tr(),
                  style: theme.textTheme.bodyMedium,
                ),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    this.title,
    this.body,
    this.action,
    this.error,
    this.stackTrace,
    this.operation,
    this.showTechnicalDetails = false,
    super.key,
  });

  final String? title;
  final String? body;
  final Widget? action;

  /// Whether the report offers the expandable stack trace; full-screen error
  /// states can afford it, inline ones cannot.
  final bool showTechnicalDetails;

  /// The failure behind this state. Pass whatever the caller was handed —
  /// without it the screen is a dead end a teacher cannot report.
  final Object? error;
  final StackTrace? stackTrace;

  /// What Classi was loading, e.g. `load the group`.
  final String? operation;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title ?? 'generic_error'.tr();
    return EmptyState(
      icon: Icons.error_outline,
      title: resolvedTitle,
      body: body ?? 'generic_error_hint'.tr(),
      action:
          action ??
          (error == null && stackTrace == null
              ? null
              : ErrorReportDetails(
                  showTechnicalDetails: showTechnicalDetails,
                  report: ErrorReport(
                    message: resolvedTitle,
                    operation: operation,
                    error: error,
                    stackTrace: stackTrace,
                  ),
                )),
    );
  }
}

class AppErrorScaffold extends StatelessWidget {
  const AppErrorScaffold({
    this.title,
    this.body,
    this.action,
    this.error,
    this.stackTrace,
    this.operation,
    super.key,
  });

  final String? title;
  final String? body;
  final Widget? action;
  final Object? error;
  final StackTrace? stackTrace;
  final String? operation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppErrorState(
        title: title,
        body: body,
        action: action,
        error: error,
        stackTrace: stackTrace,
        operation: operation,
        showTechnicalDetails: true,
      ),
    );
  }
}

/// Inline error text, with a compact report button when the failure behind it
/// is known.
class AppErrorText extends StatelessWidget {
  const AppErrorText({
    this.message,
    this.error,
    this.stackTrace,
    this.operation,
    super.key,
  });

  final String? message;
  final Object? error;
  final StackTrace? stackTrace;
  final String? operation;

  @override
  Widget build(BuildContext context) {
    final resolvedMessage = message ?? 'generic_error'.tr();
    final text = Text(
      resolvedMessage,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );

    if (error == null && stackTrace == null) {
      return text;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: text),
        IconButton(
          onPressed: () => sendErrorReport(
            context,
            ErrorReport(
              message: resolvedMessage,
              operation: operation,
              error: error,
              stackTrace: stackTrace,
            ),
          ),
          icon: const Icon(Icons.outgoing_mail, size: 18),
          tooltip: 'report_error'.tr(),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
