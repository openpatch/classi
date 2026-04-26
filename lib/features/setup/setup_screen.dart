import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import 'auto_import_prompt_card.dart';
import 'database_selection_sheet.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _passphraseController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'setup_title'.tr(),
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 12),
                              Text('setup_intro'.tr()),
                              const SizedBox(height: 12),
                              FutureBuilder<String>(
                                future: ref
                                    .read(appSessionProvider)
                                    .currentDatabasePath(),
                                builder: (context, snapshot) {
                                  return SelectableText(
                                    snapshot.data ?? '',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              const AutoImportPromptCard(),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _passphraseController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'setup_passphrase'.tr(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'setup_passphrase'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'confirm_passphrase'.tr(),
                                ),
                                validator: (value) {
                                  if (value != _passphraseController.text) {
                                    return 'passphrase_mismatch'.tr();
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isSaving ? null : _submit,
                                  child: _isSaving
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text('create_database'.tr()),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () => showDatabaseSelectionSheet(
                                          context: context,
                                          ref: ref,
                                        ),
                                  icon: const Icon(Icons.storage_outlined),
                                  label: Text('choose_database'.tr()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ref
          .read(appSessionProvider)
          .createDatabase(_passphraseController.text.trim());
      if (!mounted) {
        return;
      }

      if (ref.read(appSessionProvider).status == AppSessionStatus.ready) {
        context.go('/setup/recovery');
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('error_loading_database'.tr())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
