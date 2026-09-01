import 'dart:convert';

import 'package:classi/features/webuntis/webuntis_api.dart';
import 'package:classi/features/webuntis/webuntis_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  /// Builds an API whose transport records the requests it is given and
  /// answers each with the next canned response.
  ({WebUntisApi api, List<Map<String, dynamic>> requests, List<Uri> urls})
  buildApi(List<Object> responses) {
    final requests = <Map<String, dynamic>>[];
    final urls = <Uri>[];
    var index = 0;

    final client = MockClient((request) async {
      urls.add(request.url);
      requests.add(Map<String, dynamic>.from(jsonDecode(request.body) as Map));
      final response = responses[index.clamp(0, responses.length - 1)];
      index++;
      if (response is int) {
        return http.Response('', response);
      }
      return http.Response(
        jsonEncode(response),
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });

    return (
      api: WebUntisApi(
        server: 'mese.webuntis.com',
        school: 'mese',
        httpClient: client,
        clock: () => DateTime.fromMillisecondsSinceEpoch(1234567890000),
      ),
      requests: requests,
      urls: urls,
    );
  }

  group('normalizeServer', () {
    test('reduces anything a teacher can paste to a host', () {
      expect(
        WebUntisApi.normalizeServer('mese.webuntis.com'),
        'mese.webuntis.com',
      );
      expect(
        WebUntisApi.normalizeServer('https://mese.webuntis.com/'),
        'mese.webuntis.com',
      );
      expect(
        WebUntisApi.normalizeServer(
          '  https://mese.webuntis.com/WebUntis/?school=demo#/basic/login  ',
        ),
        'mese.webuntis.com',
      );
    });
  });

  group('schoolFromUrl', () {
    test('picks the school out of a pasted URL', () {
      expect(
        WebUntisApi.schoolFromUrl(
          'https://mese.webuntis.com/WebUntis/?school=demo-school#/basic/login',
        ),
        'demo-school',
      );
    });

    test('returns null when there is nothing to pick', () {
      expect(WebUntisApi.schoolFromUrl('mese.webuntis.com'), isNull);
      expect(
        WebUntisApi.schoolFromUrl('https://mese.webuntis.com/WebUntis/'),
        isNull,
      );
    });
  });

  group('request shape', () {
    test('posts JSON-RPC to the mobile endpoint with the school', () async {
      final harness = buildApi([
        {'jsonrpc': '2.0', 'result': 'SECRET'},
      ]);

      await harness.api.fetchAppSharedSecret(
        username: 'teacher',
        password: 'hunter2',
      );

      expect(harness.urls.single.host, 'mese.webuntis.com');
      expect(harness.urls.single.path, '/WebUntis/jsonrpc_intern.do');
      expect(harness.urls.single.queryParameters['school'], 'mese');

      final request = harness.requests.single;
      expect(request['jsonrpc'], '2.0');
      expect(request['method'], 'getAppSharedSecret');
      // The mobile endpoint wants the parameter object inside a list.
      expect(request['params'], isA<List<dynamic>>());
      expect((request['params'] as List).single, {
        'userName': 'teacher',
        'password': 'hunter2',
      });
    });

    test('signs authenticated calls with a one-time password', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'result': {
            'masterData': {'timeStamp': 42, 'klassen': [], 'schoolyears': []},
            'userData': {'displayName': 'A. Teacher'},
          },
        },
      ]);

      await harness.api.fetchUserData(username: 'teacher', secret: 'GEZDGNBV');

      final params =
          (harness.requests.single['params'] as List).single
              as Map<String, dynamic>;
      final auth = params['auth'] as Map<String, dynamic>;
      expect(auth['user'], 'teacher');
      expect(auth['clientTime'], 1234567890000);
      expect(auth['otp'], isA<int>());
      expect(auth['otp'], isNot(0));
    });
  });

  group('fetchUserData', () {
    test('reads the account and the school master data', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'result': {
            'masterData': {
              'timeStamp': 1690000000000,
              'klassen': [
                {
                  'id': 11,
                  'name': '10a',
                  'longName': 'Klasse 10a',
                  'active': true,
                  'startDate': '2026-08-01',
                  'endDate': '2027-07-31',
                },
              ],
              'schoolyears': [
                {
                  'id': 5,
                  'name': '2026/2027',
                  'startDate': '2026-08-01',
                  'endDate': '2027-07-31',
                },
              ],
            },
            'userData': {
              'elemId': 7,
              'elemType': 'TEACHER',
              'displayName': 'A. Teacher',
              'schoolName': 'Demo School',
              'klassenIds': [11],
              'rights': ['R_MY_TIMETABLE'],
            },
          },
        },
      ]);

      final userData = await harness.api.fetchUserData(
        username: 'teacher',
        secret: 'GEZDGNBV',
      );

      expect(userData.displayName, 'A. Teacher');
      expect(userData.elementType, WebUntisElementType.teacher);
      expect(userData.klassenIds, [11]);
      expect(userData.masterDataTimestamp, 1690000000000);
      expect(userData.klassen.single.displayName, '10a');
      expect(userData.klassen.single.runsOn(DateTime(2026, 9, 1)), isTrue);
      expect(userData.klassen.single.runsOn(DateTime(2026, 1, 1)), isFalse);
      expect(userData.schoolYearAt(DateTime(2026, 9, 1))?.name, '2026/2027');
    });
  });

  group('fetchTimetable', () {
    test('sends the date range in the WebUntis format', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'result': {
            'timetable': {'periods': []},
          },
        },
      ]);

      await harness.api.fetchTimetable(
        username: 'teacher',
        secret: 'GEZDGNBV',
        elementId: 11,
        elementType: WebUntisElementType.klasse,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
        masterDataTimestamp: 42,
      );

      final params =
          (harness.requests.single['params'] as List).single
              as Map<String, dynamic>;
      expect(params['id'], 11);
      expect(params['type'], 'CLASS');
      expect(params['startDate'], '2026-09-01');
      expect(params['endDate'], '2026-09-30');
      expect(params['masterDataTimestamp'], 42);
    });

    test('reads lessons and the classes they are held for', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'result': {
            'timetable': {
              'periods': [
                {
                  'id': 900,
                  'lessonId': 12,
                  'startDateTime': '2026-09-01T08:00Z',
                  'endDateTime': '2026-09-01T08:45Z',
                  'elements': [
                    {'type': 'CLASS', 'id': 11},
                    {'type': 'TEACHER', 'id': 7},
                  ],
                },
              ],
            },
          },
        },
      ]);

      final periods = await harness.api.fetchTimetable(
        username: 'teacher',
        secret: 'GEZDGNBV',
        elementId: 11,
        elementType: WebUntisElementType.klasse,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 1),
      );

      expect(periods.single.id, 900);
      expect(periods.single.klasseIds, {11});
      // The trailing Z is not really UTC: it has to stay 08:00 local, or
      // lessons drift into the previous day for teachers west of Greenwich.
      expect(periods.single.startDateTime, DateTime(2026, 9, 1, 8));
      expect(periods.single.startDateTime.isUtc, isFalse);
    });
  });

  group('fetchPeriodData', () {
    test('reads the class register of the requested lessons', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'result': {
            'dataByTTId': {
              '900': {
                'ttId': 900,
                'absenceChecked': true,
                'studentIds': [1, 2],
                'absences': [
                  {
                    'id': 5,
                    'studentId': 2,
                    'klasseId': 11,
                    'startDateTime': '2026-09-01T08:00',
                    'endDateTime': '2026-09-01T08:45',
                    'excused': false,
                    'absenceReason': 'Illness',
                    'text': '',
                  },
                ],
                'can': <String>[],
              },
            },
            'referencedStudents': [
              {'id': 1, 'firstName': 'Ada', 'lastName': 'Lovelace'},
              {'id': 2, 'firstName': 'Alan', 'lastName': 'Turing'},
            ],
          },
        },
      ]);

      final result = await harness.api.fetchPeriodData(
        username: 'teacher',
        secret: 'GEZDGNBV',
        periodIds: const [900, 900],
      );

      final params =
          (harness.requests.single['params'] as List).single
              as Map<String, dynamic>;
      expect(params['ttIds'], [900], reason: 'duplicate ids are collapsed');

      expect(result.dataByTtId[900]!.studentIds, [1, 2]);
      expect(result.dataByTtId[900]!.absences.single.studentId, 2);
      expect(result.referencedStudents.map((s) => s.fullName), [
        'Ada Lovelace',
        'Alan Turing',
      ]);
    });

    test('does not call the server for an empty lesson list', () async {
      final harness = buildApi([]);

      final result = await harness.api.fetchPeriodData(
        username: 'teacher',
        secret: 'GEZDGNBV',
        periodIds: const [],
      );

      expect(harness.requests, isEmpty);
      expect(result.dataByTtId, isEmpty);
    });
  });

  group('fetchStudentAbsences', () {
    test('reads absences and their excuse state', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'result': {
            'absences': [
              {
                'id': 1,
                'studentId': 2,
                'klasseId': 11,
                'startDateTime': '2026-09-01T08:00',
                'endDateTime': '2026-09-01T13:00',
                'excused': true,
                'absenceReason': 'Illness',
                'text': 'note',
              },
              {
                // Older servers omit `excused` and only carry the excuse.
                'id': 2,
                'studentId': 3,
                'klasseId': 11,
                'startDateTime': '2026-09-02T08:00',
                'endDateTime': '2026-09-02T13:00',
                'excuse': {'id': 9, 'excuseStatusId': 4, 'number': 1},
                'absenceReason': '',
                'text': '',
              },
            ],
          },
        },
      ]);

      final absences = await harness.api.fetchStudentAbsences(
        username: 'teacher',
        secret: 'GEZDGNBV',
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 30),
      );

      expect(absences.first.excused, isTrue);
      expect(absences.last.excused, isTrue);
      expect(absences.last.studentId, 3);
    });
  });

  group('error handling', () {
    test('maps a WebUntis error code onto a translatable reason', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'error': {'code': -8504, 'message': 'bad credentials'},
        },
      ]);

      await expectLater(
        harness.api.fetchAppSharedSecret(username: 'a', password: 'b'),
        throwsA(
          isA<WebUntisException>()
              .having(
                (e) => e.errorCode,
                'errorCode',
                WebUntisErrorCode.invalidPassword,
              )
              .having(
                (e) => e.translationKey,
                'translationKey',
                'webuntis_error_credentials',
              ),
        ),
      );
    });

    test('keeps an unmapped code visible as the generic reason', () async {
      final harness = buildApi([
        {
          'jsonrpc': '2.0',
          'error': {'code': -12345},
        },
      ]);

      await expectLater(
        harness.api.fetchAppSharedSecret(username: 'a', password: 'b'),
        throwsA(
          isA<WebUntisException>()
              .having(
                (e) => e.errorCode,
                'errorCode',
                WebUntisErrorCode.unknown,
              )
              .having((e) => e.rawCode, 'rawCode', -12345),
        ),
      );
    });

    test('reports an HTTP failure as a network problem', () async {
      final harness = buildApi([503]);

      await expectLater(
        harness.api.fetchAppSharedSecret(username: 'a', password: 'b'),
        throwsA(
          isA<WebUntisException>().having(
            (e) => e.errorCode,
            'errorCode',
            WebUntisErrorCode.network,
          ),
        ),
      );
    });

    test('refuses to call anything without a server and school', () async {
      final api = WebUntisApi(server: '', school: '');

      await expectLater(
        api.fetchUserData(username: 'a', secret: 'b'),
        throwsA(
          isA<WebUntisException>().having(
            (e) => e.errorCode,
            'errorCode',
            WebUntisErrorCode.notConfigured,
          ),
        ),
      );
      api.dispose();
    });
  });
}
