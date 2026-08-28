import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'avatar_designer_app.dart';

/// Entry point for the standalone browser avatar designer.
///
/// Build with:
/// `flutter build web --release --target lib/avatar_designer/main.dart`
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('de')],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      child: const AvatarDesignerApp(),
    ),
  );
}
