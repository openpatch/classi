import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import '../../core/storage/library_backup_service.dart';
import '../../shared/widgets/app_error_state.dart';

Future<String?> restoreWebDavBackupFlow({
  required BuildContext context,
  required WidgetRef ref,
  required String destinationPath,
  required bool createNew,
  WebDavBackupEntry? selectedBackup,
}) async {
  final backup =
      selectedBackup ??
      await showWebDavBackupPicker(context: context, ref: ref);
  if (backup == null || !context.mounted) {
    return null;
  }

  final errorCode = await ref
      .read(appSessionProvider)
      .restoreWebDavBackup(
        remotePath: backup.remotePath,
        destinationPath: destinationPath,
        createNew: createNew,
      );
  if (errorCode == null || !context.mounted) {
    return errorCode;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(errorCode.tr())));
  return errorCode;
}

Future<WebDavBackupEntry?> showWebDavBackupPicker({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final configured = await _ensureWebDavConfiguration(
    context: context,
    ref: ref,
  );
  if (!configured || !context.mounted) {
    return null;
  }

  List<WebDavBackupEntry> backups;
  try {
    backups = await ref.read(appSessionProvider).listWebDavBackups();
  } catch (_) {
    if (!context.mounted) return null;

    // Connection failed – let the user correct their credentials and retry once.
    final corrected = await _showWebDavCredentialsSheet(
      context: context,
      session: ref.read(appSessionProvider),
    );
    if (!corrected || !context.mounted) return null;

    try {
      backups = await ref.read(appSessionProvider).listWebDavBackups();
    } catch (_) {
      if (context.mounted) {
        showErrorSnackBar(context, 'webdav_connection_failed'.tr());
      }
      return null;
    }
  }
  if (!context.mounted) {
    return null;
  }

  if (backups.isEmpty) {
    showErrorSnackBar(context, 'no_webdav_backups_found'.tr());
    return null;
  }

  return showModalBottomSheet<WebDavBackupEntry>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'choose_webdav_backup'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: backups.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final backup = backups[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_download_outlined),
                      title: Text(backup.libraryName),
                      subtitle: Text(_backupSubtitle(context, backup)),
                      onTap: () => Navigator.of(context).pop(backup),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> _ensureWebDavConfiguration({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final session = ref.read(appSessionProvider);
  if (session.isWebDavConfigured) {
    return true;
  }
  return _showWebDavCredentialsSheet(context: context, session: session);
}

/// Shows the WebDAV credentials sheet pre-populated with any current values
/// and saves the result to [session]. Returns `true` if the user confirmed.
Future<bool> _showWebDavCredentialsSheet({
  required BuildContext context,
  required AppSessionController session,
}) async {
  final credentials = await showModalBottomSheet<_WebDavRestoreCredentials>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _WebDavCredentialsSheet(session: session),
  );
  if (credentials == null) {
    return false;
  }

  await session.setWebDavUrl(credentials.url);
  await session.setWebDavUsername(credentials.username);
  await session.setWebDavPassword(
    credentials.password.isEmpty ? null : credentials.password,
  );
  await session.setWebDavServerPath(
    credentials.serverPath.isEmpty ? '/' : credentials.serverPath,
  );
  return true;
}

class _WebDavCredentialsSheet extends ConsumerStatefulWidget {
  const _WebDavCredentialsSheet({required this.session});

  final AppSessionController session;

  @override
  ConsumerState<_WebDavCredentialsSheet> createState() =>
      _WebDavCredentialsSheetState();
}

class _WebDavCredentialsSheetState
    extends ConsumerState<_WebDavCredentialsSheet> {
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _serverPathController;
  bool _testingConnection = false;
  bool? _connectionOk;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(
      text: widget.session.webDavUrl ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.session.webDavUsername ?? '',
    );
    _passwordController = TextEditingController();
    _serverPathController = TextEditingController(
      text: widget.session.webDavServerPath ?? '/',
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _serverPathController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testingConnection = true;
      _connectionOk = null;
    });
    final ok = await ref
        .read(appSessionProvider)
        .testWebDavConnection(
          url: _urlController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _testingConnection = false;
      _connectionOk = ok;
    });
  }

  void _submit() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      _WebDavRestoreCredentials(
        url: url,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        serverPath: _serverPathController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'restore_from_webdav_backup'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('webdav_not_configured'.tr()),
              const SizedBox(height: 16),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'webdav_url'.tr(),
                  hintText: 'https://my.server/remote.php/dav/files/user/',
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
                onChanged: (_) => setState(() => _connectionOk = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'webdav_username'.tr()),
                autocorrect: false,
                onChanged: (_) => setState(() => _connectionOk = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'webdav_password'.tr()),
                obscureText: true,
                autocorrect: false,
                onChanged: (_) => setState(() => _connectionOk = null),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serverPathController,
                decoration: InputDecoration(
                  labelText: 'webdav_server_path'.tr(),
                  hintText: '/backups/',
                ),
                autocorrect: false,
                onChanged: (_) => setState(() => _connectionOk = null),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: _urlController.text.trim().isEmpty
                        ? null
                        : _submit,
                    child: Text('save'.tr()),
                  ),
                  OutlinedButton.icon(
                    onPressed: _testingConnection ? null : _testConnection,
                    icon: _testingConnection
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _connectionOk == null
                                ? Icons.wifi_find_outlined
                                : (_connectionOk!
                                      ? Icons.check_circle_outline
                                      : Icons.error_outline),
                            color: _connectionOk == null
                                ? null
                                : (_connectionOk!
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.error),
                          ),
                    label: Text('webdav_test_connection'.tr()),
                  ),
                ],
              ),
              if (_connectionOk != null) ...[
                const SizedBox(height: 8),
                Text(
                  (_connectionOk!
                          ? 'webdav_connection_ok'
                          : 'webdav_connection_failed')
                      .tr(),
                  style: TextStyle(
                    color: _connectionOk!
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WebDavRestoreCredentials {
  const _WebDavRestoreCredentials({
    required this.url,
    required this.username,
    required this.password,
    required this.serverPath,
  });

  final String url;
  final String username;
  final String password;
  final String serverPath;
}

String _backupSubtitle(BuildContext context, WebDavBackupEntry backup) {
  final parts = <String>[backup.fileName];

  final modifiedAt = backup.modifiedAt;
  if (modifiedAt != null) {
    final localeTag = context.locale.toLanguageTag();
    parts.add(DateFormat.yMd(localeTag).add_Hm().format(modifiedAt.toLocal()));
  }

  final sizeBytes = backup.sizeBytes;
  if (sizeBytes != null) {
    parts.add(_formatBytes(sizeBytes));
  }

  return parts.join(' • ');
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '$bytes B';
}
