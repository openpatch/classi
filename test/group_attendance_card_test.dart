import 'package:classi/core/database/app_database.dart';
import 'package:classi/core/providers/app_providers.dart';
import 'package:classi/features/attendance/group_attendance_card.dart';
import 'package:classi/features/students/student_sorting.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  final date = DateTime(2026, 9, 7);
  Student student(int id, String firstName, String lastName) => Student(
    id: id,
    firstName: firstName,
    lastName: lastName,
    groupId: 1,
    createdAt: date,
    updatedAt: date,
  );
  AttendanceLog log(int id, int studentId, int period, {bool absent = false}) =>
      AttendanceLog(
        id: id,
        studentId: studentId,
        date: date,
        periodStart: period,
        isAbsent: absent,
        isExcused: false,
        isLate: false,
        isActivity: false,
        isExam: false,
        createdAt: date,
        updatedAt: date,
      );

  testWidgets('shows the class rate and who missed the most first', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentSortFieldProvider.overrideWith(
            (ref) => StudentSortField.firstName,
          ),
          groupTimeframesProvider(1).overrideWith((ref) => Stream.value([])),
          groupAttendanceProvider(1).overrideWith(
            (ref) => Stream.value([
              log(1, 1, 1),
              log(2, 2, 1, absent: true),
              log(3, 2, 2, absent: true),
            ]),
          ),
        ],
        child: EasyLocalization(
          supportedLocales: const [Locale('en')],
          fallbackLocale: const Locale('en'),
          path: 'assets/translations',
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: GroupAttendanceCard(
                    groupId: 1,
                    students: [
                      student(1, 'Ada', 'Lovelace'),
                      student(2, 'Alan', 'Turing'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 lessons'), findsOneWidget);
    expect(find.text('Ø 50 % present'), findsOneWidget);
    expect(find.text('2 absences, 0 excused'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Alan Turing')).dy,
      lessThan(tester.getTopLeft(find.text('Ada Lovelace')).dy),
    );
  });
}
