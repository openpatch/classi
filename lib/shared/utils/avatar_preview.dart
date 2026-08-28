// ignore_for_file: implementation_imports

import 'dart:developer' as developer;

import 'package:avatar_maker/avatar_maker.dart';
import 'package:avatar_maker/src/core/services/avatar_service.dart';
import 'package:avatar_maker/src/core/services/facial_hairs_service.dart';
import 'package:avatar_maker/src/core/services/hair_service.dart';
import 'package:avatar_maker/src/core/services/options_service.dart';
import 'package:avatar_maker/src/core/services/outfit_service.dart';
import '../avatar/avatar_maker_config.dart';

final NonPersistentAvatarMakerController _avatarPreviewSeedController =
    NonPersistentAvatarMakerController(
      locale: avatarMakerLocale,
      customizedPropertyCategories: avatarMakerHiddenCosmeticCategories,
    );

final RegExp _filterElementPattern = RegExp(
  r'<filter\b[\s\S]*?<\/filter>',
  caseSensitive: false,
);
final RegExp _selfClosingFilterPattern = RegExp(
  r'<filter\b[^>]*/>',
  caseSensitive: false,
);
final RegExp _filterAttributePattern = RegExp(
  r'\sfilter="url\(#.*?\)"',
  caseSensitive: false,
);

/// Returns a safe SVG preview for a stored avatar.
///
/// The underlying `avatar_maker` package emits SVG filters that Flutter's SVG
/// loader does not support on all screens, so previews strip those filters
/// while keeping the selected avatar parts intact.
String? avatarSvgFromJson(String? avatarJson) {
  if (avatarJson == null || avatarJson.isEmpty) {
    return null;
  }

  try {
    final selectedOptions =
        Map<PropertyCategoryIds, PropertyItem>.from(
          _avatarPreviewSeedController.defaultSelectedOptions,
        )..addAll(
          OptionsService.jsonDecodeSelectedOptions(
            _avatarPreviewSeedController.propertyCategories,
            normalizeAvatarJson(avatarJson),
          ),
        );

    return sanitizeAvatarSvg(_drawAvatarSvg(selectedOptions));
  } on FormatException catch (error, stackTrace) {
    developer.log(
      'Invalid avatar JSON format.',
      name: 'classi.avatar',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  } on StateError catch (error, stackTrace) {
    developer.log(
      'Stored avatar options could not be restored.',
      name: 'classi.avatar',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// Removes unsupported SVG filter definitions and usages from avatar previews.
String sanitizeAvatarSvg(String rawSvg) {
  return rawSvg
      .replaceAll(_filterElementPattern, '')
      .replaceAll(_selfClosingFilterPattern, '')
      .replaceAll(_filterAttributePattern, '');
}

String _drawAvatarSvg(Map<PropertyCategoryIds, PropertyItem> selectedOptions) {
  return AvatarService.drawSVG(
    accessory: selectedOptions[PropertyCategoryIds.Accessory]!.value,
    backgroundStyle: selectedOptions[PropertyCategoryIds.Background]!.value,
    eyebrows: selectedOptions[PropertyCategoryIds.EyebrowType]!.value,
    eyes: selectedOptions[PropertyCategoryIds.EyeType]!.value,
    facialHair: FacialHairsService.generateFacialHair(
      color:
          selectedOptions[PropertyCategoryIds.FacialHairColor]
              as FacialHairColors,
      type:
          selectedOptions[PropertyCategoryIds.FacialHairType]
              as FacialHairTypes,
    ),
    hair: HairService.generateHairStyle(
      color: selectedOptions[PropertyCategoryIds.HairColor] as HairColors,
      style: selectedOptions[PropertyCategoryIds.HairStyle] as HairStyles,
    ),
    mouth: selectedOptions[PropertyCategoryIds.MouthType]!.value,
    nose: selectedOptions[PropertyCategoryIds.Nose]!.value,
    outfit: OutfitService.generateOutfit(
      color: selectedOptions[PropertyCategoryIds.OutfitColor] as OutfitColors,
      type: selectedOptions[PropertyCategoryIds.OutfitType] as OutfitTypes,
    ),
    skin: selectedOptions[PropertyCategoryIds.SkinColor]!.value,
  );
}
