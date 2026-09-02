import 'package:classi/core/database/app_database.dart';
import 'package:classi/features/groups/group_repository.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mimics the isolate-backed connection the app runs on: once it is closed,
/// every statement fails with "the connection was closed" instead of quietly
/// doing nothing, the way an in-process database would.
class _ClosedConnectionFails extends QueryInterceptor {
  bool isClosed = false;

  Never _closed() {
    throw StateError(
      'Tried to send Request over isolate channel, '
      'but the connection was closed!',
    );
  }

  @override
  Future<void> close(QueryExecutor inner) async {
    isClosed = true;
    await inner.close();
  }

  @override
  Future<bool> ensureOpen(QueryExecutor executor, QueryExecutorUser user) {
    if (isClosed) _closed();
    return executor.ensureOpen(user);
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isClosed) _closed();
    return executor.runSelect(statement, args);
  }
}

void main() {
  test('query streams stay quiet once the library is closed', () async {
    final database = AppDatabase.test(
      NativeDatabase.memory().interceptWith(_ClosedConnectionFails()),
    );
    final repository = GroupRepository(database);
    await database.customSelect('SELECT 1').getSingle();

    await database.close();

    // A screen that rebuilds while the library is being torn down still asks
    // the closed database for its groups; that select is the one whose failure
    // reached the teacher as an error report.
    final errors = <Object>[];
    final subscription = repository
        .watchActiveGroups(schoolYearId: 1)
        .listen((_) {}, onError: errors.add);
    await pumpEventQueue();
    await subscription.cancel();

    expect(errors, isEmpty);
  });

  test(
    'query streams still report failures while the library is open',
    () async {
      final database = AppDatabase.test(NativeDatabase.memory());
      addTearDown(database.close);

      final stream = database
          .customSelect('SELECT * FROM table_that_does_not_exist')
          .watch();

      await expectLater(stream, emitsError(isA<Object>()));
    },
  );
}
