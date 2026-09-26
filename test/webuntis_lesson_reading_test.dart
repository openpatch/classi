import 'dart:convert';
import 'dart:io';

import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/features/lessons/lesson_periods.dart';
import 'package:classi/features/webuntis/webuntis_api.dart';
import 'package:classi/features/webuntis/webuntis_link.dart';
import 'package:classi/features/webuntis/webuntis_models.dart';
import 'package:classi/features/webuntis/webuntis_service.dart';
import 'package:classi/features/webuntis/webuntis_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeKeyService extends KeyService {
  @override
  Future<String?> getWebUntisSecret(File dbFile) async => 'JBSWY3DPEHPK3PXP';
}

class _FakeDatabasePathService extends DatabasePathService {
  @override
  Future<File> getDatabaseFile() async => File('/tmp/classi-test.db');
}

class _FakeSettingsService extends WebUntisSettingsService {
  BellTimes? storedBellTimes;

  @override
  Future<WebUntisConnectionSettings?> read() async =>
      const WebUntisConnectionSettings(
        server: 'mese.webuntis.com',
        school: 'mese',
        username: 'lehrer',
      );

  @override
  Future<BellTimes> readBellTimes() async => storedBellTimes ?? const {};

  @override
  Future<void> writeBellTimes(BellTimes bellTimes) async =>
      storedBellTimes = bellTimes;
}

WebUntisPeriod lesson(int id, DateTime start, {int minutes = 45}) =>
    WebUntisPeriod(
      id: id,
      lessonId: 50,
      startDateTime: start,
      endDateTime: start.add(Duration(minutes: minutes)),
      elements: const [],
    );

WebUntisAbsence absence(
  int id,
  int studentId,
  DateTime start,
  DateTime end, {
  bool excused = false,
}) => WebUntisAbsence(
  id: id,
  studentId: studentId,
  klasseId: 0,
  startDateTime: start,
  endDateTime: end,
  excused: excused,
  absenceReason: '',
  text: '',
);

void main() {
  group('lateness in a lesson day', () {
    final start = DateTime(2026, 9, 25, 8);
    final first = lesson(1, start);
    final second = lesson(2, start.add(const Duration(minutes: 50)));

    WebUntisPeriodData register(int ttId, List<WebUntisAbsence> absences) =>
        WebUntisPeriodData(
          ttId: ttId,
          absenceChecked: false,
          studentIds: const [100, 101, 102],
          absences: absences,
        );

    test('an absence ending inside the lesson is lateness', () {
      final day = WebUntisLessonDay.fromRegisters(
        [first, second],
        {
          1: register(1, [
            absence(1, 100, start, start.add(const Duration(minutes: 10))),
            absence(2, 101, start, start.add(const Duration(minutes: 45))),
          ]),
        },
      );

      expect(day.late, {100});
      expect(day.absences, {101: false});
      expect(day.attendanceTaken, isTrue);
    });

    test(
      'a lateness listed in both registers of a double lesson stays late',
      () {
        // WebUntis lists a student's absence in every register of the day's
        // lessons with the class, not only the one it falls into.
        final lateness = absence(
          1,
          100,
          start,
          start.add(const Duration(minutes: 15)),
        );
        final day = WebUntisLessonDay.fromRegisters(
          [first, second],
          {
            1: register(1, [lateness]),
            2: register(2, [lateness]),
          },
        );

        expect(day.late, {100});
        expect(day.absences, isEmpty);
      },
    );

    test('absent in any lesson beats late in another', () {
      final day = WebUntisLessonDay.fromRegisters(
        [first, second],
        {
          1: register(1, [
            absence(1, 100, start, start.add(const Duration(minutes: 10))),
          ]),
          2: register(2, [
            absence(
              2,
              100,
              second.startDateTime,
              second.endDateTime,
              excused: true,
            ),
          ]),
        },
      );

      expect(day.late, isEmpty);
      expect(day.absences, {100: true});
    });
  });

  group('reading a lesson from WebUntis', () {
    final start = DateTime(2026, 9, 25, 8);

    late _FakeSettingsService settings;

    ({WebUntisService service, List<Map<String, dynamic>> calls}) buildService({
      List<Map<String, dynamic>> absences = const [],
    }) {
      final calls = <Map<String, dynamic>>[];
      settings = _FakeSettingsService();
      final client = MockClient((request) async {
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        final params = Map<String, dynamic>.from(
          (body['params'] as List).single as Map,
        )..remove('auth');
        calls.add({'method': body['method'], ...params});

        Map<String, dynamic> period(int id, int minutesAfterStart) => {
          'id': id,
          'lessonId': 50,
          'startDateTime':
              '2026-09-25T${(8 + minutesAfterStart ~/ 60).toString().padLeft(2, '0')}:${(minutesAfterStart % 60).toString().padLeft(2, '0')}Z',
          'endDateTime':
              '2026-09-25T${(8 + (minutesAfterStart + 45) ~/ 60).toString().padLeft(2, '0')}:${((minutesAfterStart + 45) % 60).toString().padLeft(2, '0')}Z',
          'elements': [
            {'type': 'CLASS', 'id': 11},
            {'type': 'TEACHER', 'id': 7},
          ],
        };

        final result = switch (body['method']) {
          'getUserData2017' => {
            'userData': {'elemType': 'TEACHER', 'elemId': 7},
            'masterData': {
              'timeStamp': 1,
              // 2026-09-25 is a Friday. Periods 1 and 2 as in the timetable.
              'timeGrid': {
                'days': [
                  {
                    'day': 'FRI',
                    'units': [
                      {
                        'label': '1',
                        'startTime': 'T08:00',
                        'endTime': 'T08:45',
                      },
                      {
                        'label': '2',
                        'startTime': 'T08:50',
                        'endTime': 'T09:35',
                      },
                    ],
                  },
                ],
              },
            },
          },
          'getTimetable2017' => {
            'timetable': {
              'periods': [period(1, 0), period(2, 50)],
            },
          },
          'getPeriodData2017' => {
            'dataByTTId': {
              '1': {'ttId': 1, 'absences': absences},
            },
          },
          _ => <String, dynamic>{},
        };
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': 'x', 'result': result}),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      return (
        service: WebUntisService(
          keyService: _FakeKeyService(),
          databasePathService: _FakeDatabasePathService(),
          settingsService: settings,
          apiFactory: ({required server, required school}) =>
              WebUntisApi(server: server, school: school, httpClient: client),
        ),
        calls: calls,
      );
    }

    test('reading a lesson keeps to it and stores the bell times', () async {
      final built = buildService();
      final day = await built.service.loadLessonDay(
        link: const WebUntisGroupLink.klasse(11),
        date: start,
        periods: (start: 1, end: 1),
      );

      expect(day.lessons.map((l) => l.id), [1]);
      expect(day.matchedPeriods, isTrue);
      expect(settings.storedBellTimes?[DateTime.friday], [
        (start: 480, end: 525),
        (start: 530, end: 575),
      ]);
    });

    test('reading never writes to WebUntis', () async {
      final built = buildService();
      await built.service.loadLessonDay(
        link: const WebUntisGroupLink.klasse(11),
        date: start,
        periods: (start: 1, end: 2),
      );

      expect(
        built.calls.map((call) => call['method']),
        everyElement(startsWith('get')),
      );
    });
  });

  group('WebUntisTimeGrid', () {
    test('reads units per weekday and finds the period of a time', () {
      final grid = WebUntisTimeGrid.fromJson({
        'days': [
          {
            'day': 'MON',
            'units': [
              {'startTime': 'T09:55', 'endTime': 'T10:40'},
              {'startTime': 'T08:00', 'endTime': 'T08:45'},
            ],
          },
        ],
      });

      expect(grid.periodAt(DateTime(2026, 9, 21, 8, 0)), 1);
      expect(grid.periodAt(DateTime(2026, 9, 21, 10, 0)), 2);
      expect(grid.periodAt(DateTime(2026, 9, 21, 9, 0)), isNull);
      expect(grid.periodAt(DateTime(2026, 9, 22, 8, 0)), isNull);
      expect(const WebUntisTimeGrid({}).isEmpty, isTrue);
    });
  });
}
