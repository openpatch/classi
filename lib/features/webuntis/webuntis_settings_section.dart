import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'webuntis_api.dart';
import 'webuntis_settings_service.dart';

/// The **Settings → WebUntis** section: connect a WebUntis account to this
/// library, see which account is connected, or disconnect again.
class WebUntisSettingsSection extends ConsumerStatefulWidget {
  const WebUntisSettingsSection({super.key});

  @override
  ConsumerState<WebUntisSettingsSection> createState() =>
      _WebUntisSettingsSectionState();
}

class _WebUntisSettingsSectionState
    extends ConsumerState<WebUntisSettingsSection> {
  final _serverController = TextEditingController();
  final _schoolController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _serverController.dispose();
    _schoolController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(webUntisConnectionProvider);

    return connection.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.large),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text('webuntis_error_generic'.tr()),
      data: (settings) =>
          settings == null ? _buildForm(context) : _buildConnected(settings),
    );
  }

  Widget _buildConnected(WebUntisConnectionSettings settings) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.link),
          title: Text(settings.displayName ?? settings.username),
          subtitle: Text('${settings.school} · ${settings.server}'),
        ),
        if (settings.lastSyncedAt case final syncedAt?)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.small),
            child: Text(
              'webuntis_last_synced'.tr(
                namedArgs: {
                  'date': DateFormat.yMMMd(
                    context.locale.toLanguageTag(),
                  ).add_Hm().format(syncedAt),
                },
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
        Text('webuntis_connected_hint'.tr(), style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.large),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : _testConnection,
              icon: const Icon(Icons.wifi_tethering),
              label: Text('webuntis_test_connection'.tr()),
            ),
            TextButton.icon(
              onPressed: _busy ? null : _disconnect,
              icon: const Icon(Icons.link_off),
              label: Text('webuntis_disconnect'.tr()),
            ),
          ],
        ),
        if (_error case final message?) _ErrorText(message: message),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'webuntis_connect_hint'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.large),
        TextField(
          controller: _serverController,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'webuntis_server'.tr(),
            hintText: 'mese.webuntis.com',
            helperText: 'webuntis_server_hint'.tr(),
            helperMaxLines: 3,
          ),
          onChanged: _adoptPastedUrl,
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          controller: _schoolController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'webuntis_school'.tr(),
            helperText: 'webuntis_school_hint'.tr(),
            helperMaxLines: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          controller: _usernameController,
          autocorrect: false,
          decoration: InputDecoration(labelText: 'webuntis_username'.tr()),
        ),
        const SizedBox(height: AppSpacing.medium),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'webuntis_password'.tr(),
            helperText: 'webuntis_password_hint'.tr(),
            helperMaxLines: 3,
          ),
          onSubmitted: (_) => _connect(),
        ),
        if (_error case final message?) _ErrorText(message: message),
        const SizedBox(height: AppSpacing.large),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _busy ? null : _connect,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: Text('webuntis_connect'.tr()),
          ),
        ),
      ],
    );
  }

  /// Fills in the school automatically when a whole WebUntis URL is pasted
  /// into the server field, which is what a teacher has at hand.
  void _adoptPastedUrl(String value) {
    final school = WebUntisApi.schoolFromUrl(value);
    if (school != null && _schoolController.text.trim().isEmpty) {
      _schoolController.text = school;
    }
  }

  Future<void> _connect() async {
    final server = _serverController.text.trim();
    final school = _schoolController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (server.isEmpty ||
        school.isEmpty ||
        username.isEmpty ||
        password.isEmpty) {
      setState(() => _error = 'webuntis_fill_all_fields'.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final userData = await ref
          .read(webUntisServiceProvider)
          .connect(
            server: server,
            school: school,
            username: username,
            password: password,
          );
      _passwordController.clear();
      ref.invalidate(webUntisConnectionProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'webuntis_connected'.tr(
              namedArgs: {
                'name': userData.displayName.isEmpty
                    ? username
                    : userData.displayName,
              },
            ),
          ),
        ),
      );
    } on WebUntisException catch (error) {
      if (mounted) {
        setState(() => _error = error.translationKey.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final userData = await ref.read(webUntisServiceProvider).loadUserData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'webuntis_test_ok'.tr(
              namedArgs: {'count': userData.klassen.length.toString()},
            ),
          ),
        ),
      );
    } on WebUntisException catch (error) {
      if (mounted) {
        setState(() => _error = error.translationKey.tr());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'webuntis_disconnect'.tr(),
      body: 'webuntis_disconnect_confirm'.tr(),
      confirmKey: 'webuntis_disconnect',
    );
    if (!confirmed) {
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(webUntisServiceProvider).disconnect();
      ref.invalidate(webUntisConnectionProvider);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
