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
import '../../features/students/student_summary_screen.dart';
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
          // Stay on /unlock during an unlock attempt so the `from` query
          // parameter is preserved across the loading → ready transition.
          if (state.matchedLocation == '/unlock') return null;
          return state.matchedLocation == '/loading' ? null : '/loading';
        case AppSessionStatus.needsSetup:
          return state.matchedLocation == '/setup' ? null : '/setup';
        case AppSessionStatus.locked:
          if (state.matchedLocation == '/unlock' ||
              state.matchedLocation == '/recover') {
            return null;
          }
          // Capture the current location so it can be restored after unlock.
          // Strip fragments (client-side only, not meaningful across auth).
          final currentUri = state.uri.removeFragment();
          return Uri(
            path: '/unlock',
            queryParameters: {'from': currentUri.toString()},
          ).toString();
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
            // Restore the location the user was at before the app locked.
            final from = state.uri.queryParameters['from'];
            if (from != null && from.isNotEmpty) {
              final fromUri = Uri.tryParse(from);
              // Only allow relative paths (no scheme or host) to prevent open
              // redirect attacks. Explicitly reject protocol-relative URLs
              // (e.g. //evil.com) as a defense-in-depth measure before
              // parsing, since Uri.parse may handle them unexpectedly.
              if (!from.startsWith('//') &&
                  fromUri != null &&
                  fromUri.scheme.isEmpty &&
                  fromUri.host.isEmpty &&
                  fromUri.path.startsWith('/')) {
                return from;
              }
            }
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
            routes: [
              GoRoute(
                path: 'summary',
                builder: (_, state) => StudentSummaryScreen(
                  studentId: int.parse(state.pathParameters['studentId']!),
                ),
              ),
            ],
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
