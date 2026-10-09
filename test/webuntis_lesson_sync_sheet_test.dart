import 'dart:convert';

import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/features/schedule/weekly_timetable.dart';
import 'package:classi/features/schedule/weekly_timetable_providers.dart';
import 'package:classi/features/schedule/weekly_timetable_screen.dart';
import 'package:classi/features/webuntis/webuntis_api.dart';
import 'package:classi/features/webuntis/webuntis_lesson_sync.dart';
import 'package:classi/features/webuntis/webuntis_lesson_sync_sheet.dart';
import 'package:classi/features/webuntis/webuntis_service.dart';
import 'package:classi/features/webuntis/webuntis_settings_service.dart';
import 'package:drift/native.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

late Map<String, dynamic> _translations;
late Map<String, dynamic> _germanTranslations;

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      locale.languageCode == 'de' ? _germanTranslations : _translations;
}

class _FakeSync extends WebUntisLessonSync {
  _FakeSync(AppDatabase database)
    : super(
        service: WebUntisService(
          keyService: KeyService(),
          databasePathService: DatabasePathService(),
          settingsService: WebUntisSettingsService(),
        ),
        database: database,
      );

  bool fail = false;
  bool hasLinkedGroups = true;
  final existingPeriods = <int>{};
  int loads = 0;
  DateTime? loadedStart;
  DateTime? loadedEnd;
  int? loadedGroup;
  List<WebUntisLessonImport>? imported;

  @override
  Future<WebUntisLessonPreview> load({
    required DateTime start,
    required DateTime end,
    int? groupId,
    int? schoolYearId,
  }) async {
    loads++;
    loadedStart = start;
    loadedEnd = end;
    loadedGroup = groupId;
    if (fail) throw const WebUntisException(WebUntisErrorCode.network);
    return (
      hasLinkedGroups: hasLinkedGroups,
      unmapped: 0,
      lessons: hasLinkedGroups
          ? [
              for (final period in [1, 5])
                (
                  groupId: 1,
                  groupName: 'Maths 10a',
                  lesson: (
                    date: start,
                    periodStart: period,
                    periodEnd: period + 1,
                  ),
                  categoryId: 'sonstige-mitarbeit',
                  categoryName: 'Participation',
                  alreadyExists: existingPeriods.contains(period),
                ),
            ]
          : <WebUntisLessonImport>[],
    );
  }

  @override
  Future<({int added, int skipped})> importLessons(
    List<WebUntisLessonImport> lessons,
  ) async {
    imported = lessons;
    return (added: lessons.length, skipped: 0);
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeSync sync, {
  bool timetable = false,
  bool connected = true,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        webUntisLessonSyncProvider.overrideWithValue(sync),
        activeSchoolYearIdProvider.overrideWithValue(1),
        bellTimesProvider.overrideWith((ref) async => {}),
        webUntisConnectionProvider.overrideWith(
          (ref) async => connected
              ? const WebUntisConnectionSettings(
                  server: 'example.webuntis.com',
                  school: 'School',
                  username: 'Teacher',
                )
              : null,
        ),
        weeklyTimetableProvider.overrideWith(
          (ref, start) => AsyncData(
            WeeklyTimetable(
              weekStart: start,
              lessons: const [],
              weekdays: const [1, 2, 3, 4, 5],
              periodCount: 6,
            ),
          ),
        ),
      ],
      child: EasyLocalization(
        assetLoader: const _TestAssetLoader(),
        supportedLocales: const [Locale('en'), Locale('de')],
        startLocale: locale,
        fallbackLocale: const Locale('en'),
        path: 'assets/translations',
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: timetable
                ? const WeeklyTimetableScreen()
                : Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        onPressed: () => showWebUntisLessonSyncSheet(
                          context: context,
                          groupId: 1,
                          weekStart: DateTime(2026, 10, 5),
                        ),
                        child: const Text('Open sync'),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
  for (
    var attempt = 0;
    attempt < 10 && find.byType(MaterialApp).evaluate().isEmpty;
    attempt++
  ) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase database;
  late _FakeSync sync;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    _translations = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/translations/en.json'))
          as Map,
    );
    _germanTranslations = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/translations/de.json'))
          as Map,
    );
  });

  setUp(() {
    database = AppDatabase.test(NativeDatabase.memory());
    sync = _FakeSync(database);
  });
  tearDown(() => database.close());

  testWidgets('group preview imports only checked lessons on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, sync);
    await tester.tap(find.text('Open sync'));
    await tester.pumpAndSettle();
    expect(sync.loadedGroup, 1);
    expect(sync.loadedStart, DateTime(2026, 10, 5));
    expect(sync.loadedEnd, DateTime(2026, 10, 11));
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text('Create'), findsNWidgets(2));
    expect(find.text('Create (2)'), findsOneWidget);
    expect(sync.imported, isNull);
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pump();
    await tester.tap(find.text('Create (1)'));
    await tester.pumpAndSettle();
    expect(sync.imported, hasLength(1));
    expect(sync.imported!.single.lesson.periodStart, 1);
    expect(
      find.text(
        '1 lessons created, 0 skipped because they already exist in Classi.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('labels existing lessons and selects only lessons to create', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    sync.existingPeriods.add(1);
    await _pump(tester, sync);
    await tester.tap(find.text('Open sync'));
    await tester.pumpAndSettle();

    expect(find.text('Already in Classi'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Create (1)'), findsOneWidget);
    final existing = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile).first,
    );
    expect(existing.value, isFalse);
    expect(existing.onChanged, isNull);
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pump();
    expect(find.text('Create (0)'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(CheckboxListTile).last);
    await tester.pump();
    await tester.tap(find.text('Create (1)'));
    await tester.pumpAndSettle();
    expect(sync.imported, hasLength(1));
    expect(sync.imported!.single.lesson.periodStart, 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disables creation when all lessons exist in German on a phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    sync.existingPeriods.addAll([1, 5]);
    await _pump(tester, sync, locale: const Locale('de'));
    await tester.tap(find.text('Open sync'));
    await tester.pumpAndSettle();

    expect(find.text('Bereits in Classi'), findsNWidgets(2));
    expect(find.text('Anlegen (0)'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(sync.imported, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timetable sync starts with the displayed week', (tester) async {
    await _pump(tester, sync, timetable: true);
    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sync lessons from WebUntis'));
    await tester.pumpAndSettle();
    final monday = mondayOf(DateTime.now());
    final nextMonday = DateTime(monday.year, monday.month, monday.day + 7);
    expect(sync.loadedStart, nextMonday);
    expect(sync.loadedGroup, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(sync.imported, isNull);
  });

  testWidgets('shows WebUntis errors and allows retrying', (tester) async {
    sync.fail = true;
    await _pump(tester, sync);
    await tester.tap(find.text('Open sync'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No connection to WebUntis.'), findsOneWidget);
    expect(find.text('Create (0)'), findsOneWidget);
    sync.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(sync.loads, 2);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
  });

  testWidgets('explains missing group links and disables import', (
    tester,
  ) async {
    sync.hasLinkedGroups = false;
    await _pump(tester, sync);
    await tester.tap(find.text('Open sync'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Link a group to a WebUntis course'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('hides timetable sync when disconnected', (tester) async {
    await _pump(tester, sync, timetable: true, connected: false);
    expect(find.byTooltip('Sync lessons from WebUntis'), findsNothing);
  });
}
