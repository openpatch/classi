import 'package:easy_localization/easy_localization.dart';

import '../../features/school_years/school_year_repository.dart';
import 'app_database.dart';

/// Finishes setting up a freshly created library with values that need the
/// app's locale.
///
/// `onCreate` seeds the current school year, but a timeframe label has to read
/// as "1. Halbjahr" or "First Term" depending on the locale, and the database
/// layer has no business reaching into localization. So the locale-dependent
/// half of the seed happens here, right after the library is opened.
///
/// Idempotent: the repository skips seeding a year that already has timeframes.
Future<void> seedNewLibrary(AppDatabase database) async {
  final repository = SchoolYearRepository(database);
  final year = await repository.currentSchoolYear();
  if (year == null) return;

  await repository.seedDefaultTimeframes(
    schoolYearId: year.id,
    firstLabel: _translate('default_timeframe_first', 'First Term'),
    secondLabel: _translate('default_timeframe_second', 'Second Term'),
  );
}

/// Translates [key], falling back to [fallback] when localization is not
/// loaded — `tr()` hands back the key itself in that case, which would end up
/// as a visible timeframe label.
String _translate(String key, String fallback) {
  final translated = key.tr();
  return translated == key ? fallback : translated;
}
