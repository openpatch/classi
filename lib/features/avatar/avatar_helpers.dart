// ignore_for_file: implementation_imports

import 'package:avatar_maker/avatar_maker.dart';
import 'package:avatar_maker/src/core/services/options_service.dart';

import '../../shared/avatar/avatar_maker_config.dart';

NonPersistentAvatarMakerController _newSeedController() =>
    NonPersistentAvatarMakerController(
      locale: avatarMakerLocale,
      customizedPropertyCategories: avatarMakerHiddenCosmeticCategories,
    );

final NonPersistentAvatarMakerController _avatarSeedController =
    _newSeedController();

/// Builds a fresh customizer controller, optionally seeded from a stored
/// [avatarJson] payload.
///
/// The decoded options are merged onto the package defaults so every category
/// (including the hidden cosmetic ones) has a value — `avatar_maker` 1.8.0
/// crashes when a displayed category is missing from `selectedOptions`.
NonPersistentAvatarMakerController createAvatarMakerController({
  String? avatarJson,
}) {
  if (avatarJson == null || avatarJson.isEmpty) {
    return _newSeedController();
  }

  final selectedOptions =
      Map<PropertyCategoryIds, PropertyItem>.from(
        _avatarSeedController.defaultSelectedOptions,
      )..addAll(
        OptionsService.jsonDecodeSelectedOptions(
          _avatarSeedController.propertyCategories,
          normalizeAvatarJson(avatarJson),
        ),
      );

  return NonPersistentAvatarMakerController(
    locale: avatarMakerLocale,
    customizedPropertyCategories: avatarMakerHiddenCosmeticCategories,
    selectedOptions: selectedOptions,
  );
}
