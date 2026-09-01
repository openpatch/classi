import '../../core/session/app_session_controller.dart';
import 'app_error_state.dart';

/// Bridges a session failure to the reporting UI, so an error screen can hand
/// the underlying exception to support instead of only naming it.
extension AppSessionErrorDetailsReport on AppSessionErrorDetails {
  ErrorReport toReport(String message) => ErrorReport(
    message: message,
    operation: operation,
    error: error,
    stackTrace: stackTrace,
    occurredAt: occurredAt,
  );
}
