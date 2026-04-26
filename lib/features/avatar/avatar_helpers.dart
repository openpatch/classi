// ignore_for_file: implementation_imports

import 'package:avatar_maker/avatar_maker.dart';
import 'package:avatar_maker/src/core/services/options_service.dart';
import 'package:flutter/widgets.dart';

const Locale avatarMakerLocale = Locale('en');
final NonPersistentAvatarMakerController _avatarSeedController =
    NonPersistentAvatarMakerController(locale: avatarMakerLocale);

NonPersistentAvatarMakerController createAvatarMakerController({
  String? avatarJson,
}) {
  if (avatarJson == null || avatarJson.isEmpty) {
    return NonPersistentAvatarMakerController(locale: avatarMakerLocale);
  }

  final selectedOptions = OptionsService.jsonDecodeSelectedOptions(
    _avatarSeedController.propertyCategories,
    avatarJson,
  );
  return NonPersistentAvatarMakerController(
    locale: avatarMakerLocale,
    selectedOptions: selectedOptions,
  );
}
