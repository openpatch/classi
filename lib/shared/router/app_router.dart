import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/session/app_session_controller.dart';
import '../../features/groups/group_detail_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/lessons/lesson_mode_screen.dart';
import '../../features/lessons/lesson_support.dart';
import '../../features/lists/list_detail_screen.dart';
import '../../features/lists/lists_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/setup/recover_access_screen.dart';
import '../../features/setup/recovery_key_screen.dart';
import '../../features/setup/setup_screen.dart';
import '../../features/setup/unlock_screen.dart';
import '../../features/students/student_detail_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/startup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(appSessionProvider);

  final router = GoRouter(
    initialLocation: '/loading',
    refreshListenable: session,
    redirect: (context, state) {
      switch (session.status) {
        case AppSessionStatus.loading:
          return state.matchedLocation == '/loading' ? null : '/loading';
        case AppSessionStatus.needsSetup:
          return state.matchedLocation == '/setup' ? null : '/setup';
        case AppSessionStatus.locked:
          return state.matchedLocation == '/unlock' ||
                  state.matchedLocation == '/recover'
              ? null
              : '/unlock';
        case AppSessionStatus.ready:
          if (session.hasPendingRecoveryKey) {
            return state.matchedLocation == '/setup/recovery'
                ? null
                : '/setup/recovery';
          }
          if (state.matchedLocation == '/loading' ||
              state.matchedLocation == '/setup' ||
              state.matchedLocation == '/setup/recovery' ||
              state.matchedLocation == '/unlock' ||
              state.matchedLocation == '/recover' ||
              state.matchedLocation == '/') {
            return '/groups';
          }
          return null;
        case AppSessionStatus.error:
          return state.matchedLocation == '/loading' ? null : '/loading';
      }
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/loading'),
      GoRoute(
        path: '/loading',
        builder: (context, state) => const StartupScreen(),
      ),
      GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
      GoRoute(
        path: '/setup/recovery',
        builder: (context, state) => const RecoveryKeyScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const UnlockScreen(),
      ),
      GoRoute(
        path: '/recover',
        builder: (context, state) => const RecoverAccessScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: ':groupId',
                builder: (_, state) => GroupDetailScreen(
                  groupId: int.parse(state.pathParameters['groupId']!),
                ),
                routes: [
                  GoRoute(
                    path: 'lesson',
                    builder: (_, state) => LessonModeScreen(
                      groupId: int.parse(state.pathParameters['groupId']!),
                      initialDate: parseLessonDateOrToday(
                        state.uri.queryParameters['date'],
                      ),
                      initialSessionLabel: state.uri.queryParameters['session'],
                      initialCategoryId: state.uri.queryParameters['category'],
                    ),
                  ),
                  GoRoute(
                    path: 'grade-entry',
                    redirect: (_, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final date = state.uri.queryParameters['date'];
                      final session = state.uri.queryParameters['session'];
                      final category = state.uri.queryParameters['category'];
                      final query = <String, String>{
                        if (date != null && date.isNotEmpty) 'date': date,
                        if (session != null && session.isNotEmpty)
                          'session': session,
                        if (category != null && category.isNotEmpty)
                          'category': category,
                      };
                      final uri = Uri(
                        path: '/groups/$groupId/lesson',
                        queryParameters: query.isEmpty ? null : query,
                      );
                      return uri.toString();
                    },
                  ),
                  GoRoute(
                    path: 'tracking',
                    redirect: (_, state) {
                      final groupId = state.pathParameters['groupId']!;
                      final date = state.uri.queryParameters['date'];
                      final session = state.uri.queryParameters['session'];
                      final category = state.uri.queryParameters['category'];
                      final query = <String, String>{
                        if (date != null && date.isNotEmpty) 'date': date,
                        if (session != null && session.isNotEmpty)
                          'session': session,
                        if (category != null && category.isNotEmpty)
                          'category': category,
                      };
                      final uri = Uri(
                        path: '/groups/$groupId/lesson',
                        queryParameters: query.isEmpty ? null : query,
                      );
                      return uri.toString();
                    },
                  ),
                  GoRoute(
                    path: 'lists',
                    builder: (_, state) => ListsScreen(
                      groupId: int.parse(state.pathParameters['groupId']!),
                    ),
                    routes: [
                      GoRoute(
                        path: ':listId',
                        builder: (_, state) => ListDetailScreen(
                          listId: int.parse(state.pathParameters['listId']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/lists',
            builder: (context, state) => const ListsScreen(),
            routes: [
              GoRoute(
                path: ':listId',
                builder: (_, state) => ListDetailScreen(
                  listId: int.parse(state.pathParameters['listId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/students/:studentId',
            builder: (_, state) => StudentDetailScreen(
              studentId: int.parse(state.pathParameters['studentId']!),
            ),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
