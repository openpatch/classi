import 'package:flutter/widgets.dart';

abstract final class AppSpacing {
  static const double xSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 20;
  static const double xxLarge = 24;
}

abstract final class AppRadii {
  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
  static const double xLarge = 24;
  static const double pill = 999;
}

const EdgeInsets appScreenPadding = EdgeInsets.fromLTRB(
  AppSpacing.large,
  AppSpacing.xLarge,
  AppSpacing.large,
  AppSpacing.xxLarge,
);

const EdgeInsets appCardPadding = EdgeInsets.all(AppSpacing.xLarge);

const EdgeInsets appSurfaceTilePadding = EdgeInsets.symmetric(
  horizontal: AppSpacing.large,
  vertical: AppSpacing.xSmall,
);
