import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'avatar_designer_screen.dart';

class AvatarDesignerApp extends StatelessWidget {
  const AvatarDesignerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => 'avatar_designer_title'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D5AFE),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D5AFE),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const AvatarDesignerScreen(),
    );
  }
}
