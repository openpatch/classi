import 'dart:convert';
import 'dart:io';

import 'package:classi/core/security/key_service.dart';
import 'package:classi/core/storage/database_path_service.dart';
import 'package:classi/features/webuntis/webuntis_api.dart';
import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/webuntis/webuntis_lesson_day.dart';
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
  @override
  Future<WebUntisConnectionSettings?> read() async =>
      const WebUntisConnectionSettings(
        server: 'mese.webuntis.com',
        school: 'mese',
        username: 'lehrer',
      );
}

void main() {
  group('readWebUntisTopic', () {
    test('reads the topic as an object with text', () {
      expect(
        readWebUntisTopic({
          'topic': {'text': ' Bruchrechnung '},
        }),
        'Bruchrechnung',
      );
    });

    test('treats missing, null and blank as no topic', () {
      expect(readWebUntisTopic({}), isNull);
      expect(readWebUntisTopic({'topic': null}), isNull);
      expect(
        readWebUntisTopic({
          'topic': {'text': '  '},
        }),
        isNull,
      );
    });
  });

  group('webUntisTopicAsLessonTopic', () {
    test('collapses line breaks into one line', () {
      expect(
        webUntisTopicAsLessonTopic(['Diskussion\nReferatsthemen']),
        'Diskussion Referatsthemen',
      );
    });

    test('joins several topics', () {
      expect(webUntisTopicAsLessonTopic(['A', 'B']), 'A / B');
    });

    test('cuts to what a lesson can store', () {
      final topic = webUntisTopicAsLessonTopic(['x' * 300]);
      expect(topic.length, 120);
      expect(topic.endsWith('…'), isTrue);
    });
  });

  group('loadLessonDay', () {
    const teacherId = 77;
    const klasseId = 5;
    const otherKlasseId = 6;

    Map<String, dynamic> period(int id, int klasse, String start) => {
      'id': id,
      'lessonId': id,
      'startDateTime': start,
      'endDateTime': start,
      'elements': [
        {'type': 'CLASS', 'id': klasse},
        {'type': 'TEACHER', 'id': teacherId},
      ],
    };

    ({WebUntisService service, List<Map<String, dynamic>> requests})
    buildService({required Map<String, dynamic> periodData}) {
      final requests = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        final body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        requests.add(body);
        final result = switch (body['method']) {
          'getUserData2017' => {
            'userData': {'elemType': 'TEACHER', 'elemId': teacherId},
            'masterData': {'timeStamp': 42},
          },
          'getTimetable2017' => {
            'timetable': {
              'periods': [
                // Out of order on purpose: topics follow lesson order.
                period(2, klasseId, '2026-09-25T09:45Z'),
                period(1, klasseId, '2026-09-25T08:00Z'),
                period(3, otherKlasseId, '2026-09-25T10:45Z'),
                {
                  ...period(4, klasseId, '2026-09-25T12:00Z'),
                  'is': ['CANCELLED'],
                },
              ],
            },
          },
          'getPeriodData2017' => periodData,
          _ => null,
        };
        return http.Response(
          jsonEncode({'jsonrpc': '2.0', 'id': 'x', 'result': result}),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final service = WebUntisService(
        keyService: _FakeKeyService(),
        databasePathService: _FakeDatabasePathService(),
        settingsService: _FakeSettingsService(),
        apiFactory: ({required server, required school}) =>
            WebUntisApi(server: server, school: school, httpClient: client),
      );
      return (service: service, requests: requests);
    }

    test(
      "reads the teacher's own timetable and only this class's lessons",
      () async {
        final built = buildService(
          periodData: {
            'dataByTTId': {
              '1': {
                'ttId': 1,
                'topic': {'text': 'Brüche'},
              },
              '2': {
                'ttId': 2,
                'topic': {'text': 'Brüche'},
              },
            },
          },
        );

        final day = await built.service.loadLessonDay(
          link: const WebUntisGroupLink.klasse(klasseId),
          date: DateTime(2026, 9, 25, 13),
        );

        expect(day.lessonCount, 2);
        expect(day.topics, ['Brüche']);

        final timetable = built.requests.firstWhere(
          (r) => r['method'] == 'getTimetable2017',
        );
        final params = (timetable['params'] as List).single as Map;
        expect(params['id'], teacherId);
        expect(params['type'], 'TEACHER');
        expect(params['startDate'], '2026-09-25');
        expect(params['endDate'], '2026-09-25');

        final periodData = built.requests.firstWhere(
          (r) => r['method'] == 'getPeriodData2017',
        );
        final ids = ((periodData['params'] as List).single as Map)['ttIds'];
        expect(ids, unorderedEquals([1, 2]));
      },
    );

    test('keeps distinct topics in lesson order', () async {
      final built = buildService(
        periodData: {
          'dataByTTId': {
            '1': {
              'ttId': 1,
              'topic': {'text': 'Erste Stunde'},
            },
            '2': {
              'ttId': 2,
              'topic': {'text': 'Zweite Stunde'},
            },
          },
        },
      );

      final day = await built.service.loadLessonDay(
        link: const WebUntisGroupLink.klasse(klasseId),
        date: DateTime(2026, 9, 25),
      );

      expect(day.topics, ['Erste Stunde', 'Zweite Stunde']);
    });

    test('is empty when the register has no topic', () async {
      final built = buildService(
        periodData: {
          'dataByTTId': {
            '1': {'ttId': 1},
          },
        },
      );

      final day = await built.service.loadLessonDay(
        link: const WebUntisGroupLink.klasse(klasseId),
        date: DateTime(2026, 9, 25),
      );
      expect(day.topics, isEmpty);
      expect(day.attendanceTaken, isFalse);
    });

    test('a course link reads only that course', () async {
      final built = buildService(
        periodData: {
          'dataByTTId': {
            '2': {
              'ttId': 2,
              'topic': {'text': 'Nur Stunde 2'},
            },
          },
        },
      );

      final day = await built.service.loadLessonDay(
        // period() gives lessonId == id; lesson 2 is one of the two for 5.
        link: const WebUntisGroupLink.course({2}),
        date: DateTime(2026, 9, 25),
      );

      expect(day.lessonCount, 1);
      expect(day.topics, ['Nur Stunde 2']);
      final periodData = built.requests.firstWhere(
        (r) => r['method'] == 'getPeriodData2017',
      );
      expect(((periodData['params'] as List).single as Map)['ttIds'], [2]);
    });

    test('folds the absences of both lessons into the day', () async {
      final built = buildService(
        periodData: {
          'dataByTTId': {
            '1': {
              'ttId': 1,
              'absenceChecked': true,
              'absences': [
                {'id': 1, 'studentId': 100, 'excused': true},
                {'id': 2, 'studentId': 101, 'excused': true},
              ],
            },
            '2': {
              'ttId': 2,
              'absenceChecked': true,
              'absences': [
                // Excused in the first lesson only: the day is not.
                {'id': 3, 'studentId': 101, 'excused': false},
              ],
            },
          },
        },
      );

      final day = await built.service.loadLessonDay(
        link: const WebUntisGroupLink.klasse(klasseId),
        date: DateTime(2026, 9, 25),
      );

      expect(day.attendanceTaken, isTrue);
      expect(day.absences, {100: true, 101: false});
    });
  });

  group('attendance for a group', () {
    Student student(int id, int? webUntisId) => Student(
      id: id,
      firstName: 'S$id',
      lastName: 'L$id',
      groupId: 1,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      webuntisStudentId: webUntisId,
    );

    final students = [student(1, 100), student(2, 101), student(3, null)];
    const day = WebUntisLessonDay(
      lessonCount: 1,
      topics: [],
      attendanceTaken: true,
      absences: {100: true, 999: false},
    );

    test('maps absences onto the group by WebUntis id', () {
      final attendance = webUntisAttendanceForGroup(day, students);
      expect(attendance.linkedStudentIds, {1, 2});
      expect(attendance.absences, {1: true});
      expect(attendance.unmatchedAbsences, 1);
    });

    test('matches only when linked students agree', () {
      final attendance = webUntisAttendanceForGroup(day, students);

      expect(
        webUntisAttendanceMatches(
          attendance,
          absentStudents: {1},
          excusedStudents: {1},
        ),
        isTrue,
      );
      // An unlinked student's absence is not WebUntis's business.
      expect(
        webUntisAttendanceMatches(
          attendance,
          absentStudents: {1, 3},
          excusedStudents: {1},
        ),
        isTrue,
      );
      expect(
        webUntisAttendanceMatches(
          attendance,
          absentStudents: {1},
          excusedStudents: const {},
        ),
        isFalse,
      );
      expect(
        webUntisAttendanceMatches(
          attendance,
          absentStudents: {1, 2},
          excusedStudents: {1},
        ),
        isFalse,
      );
    });
  });
}
