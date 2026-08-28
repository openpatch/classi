import 'package:avatar_maker/avatar_maker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/avatar/avatar_helpers.dart';
import '../shared/avatar/avatar_code.dart';
import '../shared/avatar/avatar_maker_config.dart';

class AvatarDesignerScreen extends StatefulWidget {
  const AvatarDesignerScreen({super.key});

  @override
  State<AvatarDesignerScreen> createState() => _AvatarDesignerScreenState();
}

class _AvatarDesignerScreenState extends State<AvatarDesignerScreen> {
  final NonPersistentAvatarMakerController _controller =
      createAvatarMakerController();
  String? _code;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateCode() {
    setState(() {
      _code = AvatarCode.encode(
        normalizeAvatarJson(_controller.getJsonOptionsSync()),
      );
    });
  }

  void _clearCode() {
    if (_code != null) {
      setState(() => _code = null);
    }
  }

  Future<void> _copyCode() async {
    final code = _code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('avatar_designer_copied'.tr())));
  }

  void _toggleLocale() {
    final next = context.locale.languageCode == 'de'
        ? const Locale('en')
        : const Locale('de');
    context.setLocale(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final customizerWidth = size.width.clamp(280.0, 720.0);

    return Scaffold(
      appBar: AppBar(
        title: Text('avatar_designer_title'.tr()),
        actions: [
          TextButton(
            onPressed: _toggleLocale,
            child: Text(
              context.locale.languageCode.toUpperCase(),
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
          IconButton(
            onPressed: () {
              _controller.randomizedSelectedOptions();
              _clearCode();
            },
            icon: const Icon(Icons.shuffle),
            tooltip: 'randomize_avatar'.tr(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
                child: Column(
                  children: [
                    AvatarMakerAvatar(
                      controller: _controller,
                      radius: 56,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'avatar_designer_intro'.tr(),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AvatarMakerCustomizer(
                  controller: _controller,
                  autosave: false,
                  scaffoldWidth: customizerWidth.toDouble(),
                  scaffoldHeight: size.height * 0.5,
                  onChange: (_) => _clearCode(),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: _code == null
                      ? Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _generateCode,
                            icon: const Icon(Icons.qr_code_2),
                            label: Text('avatar_designer_generate'.tr()),
                          ),
                        )
                      : _CodeResult(code: _code!, onCopy: _copyCode),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeResult extends StatelessWidget {
  const _CodeResult({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'avatar_designer_hand_to_teacher'.tr(),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy),
                tooltip: 'avatar_designer_copy'.tr(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
