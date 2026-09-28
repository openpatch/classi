import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../shared/theme/app_ui.dart';
import '../../shared/widgets/app_updater.dart';

/// Shows a seating plan filling the whole screen, scaled so every seat is in
/// view at once, with pinch, scroll-wheel and trackpad zoom on top.
///
/// [builder] draws the plan itself. It is called again whenever [refresh]
/// notifies, so a caller whose data lives outside of providers — like the
/// attendance in lesson mode — can keep the overlays current.
///
/// The route goes on the navigator of [context], so sheets and dialogs the
/// plan opens from the caller's context still land on top of it.
Future<void> showSeatingPlanFullscreen({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
  Listenable? refresh,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => SeatingPlanFullscreenPage(
        title: title,
        builder: builder,
        refresh: refresh,
      ),
    ),
  );
}

/// The page behind [showSeatingPlanFullscreen].
class SeatingPlanFullscreenPage extends StatefulWidget {
  const SeatingPlanFullscreenPage({
    required this.title,
    required this.builder,
    this.refresh,
    super.key,
  });

  final String title;
  final WidgetBuilder builder;
  final Listenable? refresh;

  @override
  State<SeatingPlanFullscreenPage> createState() =>
      _SeatingPlanFullscreenPageState();
}

class _SeatingPlanFullscreenPageState extends State<SeatingPlanFullscreenPage> {
  final _transformation = TransformationController();

  /// Whether the desktop window was already full screen before this page, so
  /// leaving the page does not take the teacher out of a mode they chose.
  bool _windowWasFullScreen = false;

  @override
  void initState() {
    super.initState();
    unawaited(_enterFullScreen());
  }

  @override
  void dispose() {
    unawaited(_leaveFullScreen());
    _transformation.dispose();
    super.dispose();
  }

  Future<void> _enterFullScreen() async {
    if (kIsWeb) return;
    try {
      if (isDesktopPlatform) {
        _windowWasFullScreen = await windowManager.isFullScreen();
        if (!_windowWasFullScreen) await windowManager.setFullScreen(true);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    } on Object {
      // Full screen is a nicety; the plan is still shown in the window.
    }
  }

  Future<void> _leaveFullScreen() async {
    if (kIsWeb) return;
    try {
      if (isDesktopPlatform) {
        if (!_windowWasFullScreen) await windowManager.setFullScreen(false);
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } on Object {
      // See _enterFullScreen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).maybePop(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            leading: IconButton(
              icon: const Icon(Icons.fullscreen_exit),
              tooltip: 'exit_fullscreen'.tr(),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            actions: [
              ValueListenableBuilder<Matrix4>(
                valueListenable: _transformation,
                builder: (context, matrix, _) => IconButton(
                  icon: const Icon(Icons.fit_screen_outlined),
                  tooltip: 'fit_to_screen'.tr(),
                  onPressed: matrix.isIdentity()
                      ? null
                      : () => _transformation.value = Matrix4.identity(),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => InteractiveViewer(
                transformationController: _transformation,
                maxScale: 6,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  // Scale the plan to the screen — up for a small class, down
                  // for a wide room — so everyone is visible without panning.
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: widget.refresh == null
                          ? Builder(builder: widget.builder)
                          : ListenableBuilder(
                              listenable: widget.refresh!,
                              builder: (context, _) => widget.builder(context),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
