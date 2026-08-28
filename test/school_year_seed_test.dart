import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/timeframe_repository.dart';
import 'package:classi/features/school_years/school_year_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SchoolYearRepository schoolYears;
  late TimeframeRepository timeframes;

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    schoolYears = SchoolYearRepository(database);
    timeframes = TimeframeRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('a fresh library comes with the current school year', () async {
    final years = await schoolYears.allSchoolYears();

    expect(years, hasLength(1));
    expect(await schoolYears.currentSchoolYear(), isNotNull);
  });

  test('seeding splits the year into two halves that meet', () async {
    final year = (await schoolYears.allSchoolYears()).single;

    await schoolYears.seedDefaultTimeframes(
      schoolYearId: year.id,
      firstLabel: 'First',
      secondLabel: 'Second',
    );

    final seeded = await timeframes.getTimeframes(year.id);
    expect(seeded.map((t) => t.label), ['First', 'Second']);
    expect(seeded.first.startDate, year.startDate);
    expect(seeded.last.endDate, year.endDate);
    // No gap: the second half starts the day after the first ends.
    expect(
      seeded.last.startDate.difference(seeded.first.endDate).inDays,
      1,
    );
  });

  test('seeding leaves an already-structured year alone', () async {
    final year = (await schoolYears.allSchoolYears()).single;
    await timeframes.saveTimeframe(
      schoolYearId: year.id,
      label: 'Trimester 1',
      startDate: year.startDate,
      endDate: year.endDate,
    );

    await schoolYears.seedDefaultTimeframes(
      schoolYearId: year.id,
      firstLabel: 'First',
      secondLabel: 'Second',
    );

    expect(
      (await timeframes.getTimeframes(year.id)).map((t) => t.label),
      ['Trimester 1'],
    );
  });

  test('seeding twice does not double the timeframes', () async {
    final year = (await schoolYears.allSchoolYears()).single;

    for (var i = 0; i < 2; i++) {
      await schoolYears.seedDefaultTimeframes(
        schoolYearId: year.id,
        firstLabel: 'First',
        secondLabel: 'Second',
      );
    }

    expect(await timeframes.getTimeframes(year.id), hasLength(2));
  });
}
