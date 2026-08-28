import 'dart:convert';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:flutter/widgets.dart' show Locale;

/// Locale used for every `avatar_maker` controller in the app. The stored
/// avatar payload uses enum constant names (not localized labels), so the
/// locale only affects the customizer UI text.
const Locale avatarMakerLocale = Locale('en');

/// The 13 classic `PropertyCategoryIds` names that make up a classi avatar.
///
/// `avatar_maker` 1.7.0+ also ships three "cosmetic" categories
/// (`AvatarBackground`, `AvatarEffect`, `AvatarEffectColor`) that classi does
/// not support. Those are deliberately excluded here.
const Set<String> kClassicAvatarCategoryNames = {
  'Accessory',
  'Background',
  'EyebrowType',
  'EyeType',
  'FacialHairColor',
  'FacialHairType',
  'HairColor',
  'HairStyle',
  'MouthType',
  'Nose',
  'OutfitColor',
  'OutfitType',
  'SkinColor',
};

/// Overrides that hide the cosmetic categories added in `avatar_maker` 1.7.0.
///
/// Those categories are registered in `defaultPropertyCategories` with
/// `toDisplay: true` but an empty `properties` list. Left untouched they crash
/// the customizer (`properties!.first` on an empty list) and the shuffle button
/// (`Random().nextInt(0)`). Passing `toDisplay: false` with a one-element
/// `properties` list drops them from `displayedPropertyCategories` and keeps the
/// merge validation (which matches the default value by `label`) happy.
final List<CustomizedPropertyCategory> avatarMakerHiddenCosmeticCategories = [
  CustomizedPropertyCategory(
    id: PropertyCategoryIds.AvatarBackground,
    toDisplay: false,
    properties: [NoBackgroundItem()],
    defaultValue: NoBackgroundItem(),
  ),
  CustomizedPropertyCategory(
    id: PropertyCategoryIds.AvatarEffect,
    toDisplay: false,
    properties: [NoEffectItem()],
    defaultValue: NoEffectItem(),
  ),
  CustomizedPropertyCategory(
    id: PropertyCategoryIds.AvatarEffectColor,
    toDisplay: false,
    properties: [NoEffectColorItem()],
    defaultValue: NoEffectColorItem(),
  ),
];

/// Strips any key that is not one of the [kClassicAvatarCategoryNames] from a
/// serialized avatar payload.
///
/// `avatar_maker` 1.8.0 writes the three cosmetic keys into
/// `getJsonOptionsSync()` for freshly created avatars. classi keeps its stored
/// shape at the 13 classic keys so old and new libraries stay interchangeable.
/// Returns a compact JSON object string. Throws [FormatException] if the input
/// is not a JSON object.
String normalizeAvatarJson(String avatarJson) {
  final decoded = jsonDecode(avatarJson);
  if (decoded is! Map) {
    throw const FormatException('Avatar payload is not a JSON object');
  }
  final result = <String, dynamic>{};
  decoded.forEach((key, value) {
    if (key is String && kClassicAvatarCategoryNames.contains(key)) {
      result[key] = value;
    }
  });
  return jsonEncode(result);
}
