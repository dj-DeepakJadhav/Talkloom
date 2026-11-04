import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import '../client.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/practice/practice_session_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/profile/profile_screen.dart';
import '../features/speak/speak_screen.dart';
import '../features/content/source_detail_screen.dart';
import '../features/content/source_activity_screen.dart';
import '../screens/sign_in_screen.dart';

abstract final class TlRoutes {
  static const onboarding = '/welcome';
  static const home = '/';
  static const lesson = '/lesson';
  static const practice = '/practice';
  static const speak = '/speak';
  static const signIn = '/sign-in';
}

/// Authentication state that can refresh routing when the session changes.
class AuthRouteState extends ChangeNotifier {
  AuthRouteState({
    required this.isAuthenticated,
    this.refreshListenable,
  }) {
    refreshListenable?.addListener(_refresh);
  }

  final bool Function() isAuthenticated;
  final Listenable? refreshListenable;

  void _refresh() => notifyListeners();

  @override
  void dispose() {
    refreshListenable?.removeListener(_refresh);
    super.dispose();
  }
}

final authRouteStateProvider = Provider<AuthRouteState>((ref) {
  final state = AuthRouteState(
    isAuthenticated: () => client.auth.isAuthenticated,
    refreshListenable: client.auth.authInfoListenable,
  );
  ref.onDispose(state.dispose);
  return state;
});

/// Slide for lateral moves (main tabs / sibling pushes), opacity + offset
/// only so it stays on the compositor. No blur or shadow in the path.
CustomTransitionPage<void> _slidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final offset = Tween<Offset>(
        begin: const Offset(0.12, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      return SlideTransition(
        position: offset,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}

/// Bottom-sheet rise for dialogs and detail pushes (content detail,
/// practice, lesson, speak, language add). Translation + fade only.
CustomTransitionPage<void> _sheetPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.disableAnimationsOf(context)) return child;
      final offset = Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOut),
      );
      return SlideTransition(
        position: offset,
        child: FadeTransition(opacity: fade, child: child),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRouteStateProvider);
  return GoRouter(
    initialLocation: TlRoutes.home,
    // Guests are authenticated automatically without registering. Only a failed
    // private-session bootstrap needs the recovery/account screen.
    refreshListenable: auth,
    redirect: (context, state) => authRedirect(
      isAuthenticated: auth.isAuthenticated(),
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: TlRoutes.onboarding,
        pageBuilder: (context, state) =>
            _slidePage(key: state.pageKey, child: const OnboardingScreen()),
      ),
      GoRoute(
        path: TlRoutes.signIn,
        pageBuilder: (context, state) =>
            _sheetPage(key: state.pageKey, child: const SignInScreen()),
      ),
      GoRoute(
        path: TlRoutes.home,
        pageBuilder: (context, state) => _slidePage(
          key: state.pageKey,
          child: AppShell(
            initialIndex:
                int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
          ),
        ),
        routes: [
          GoRoute(
            path: 'content/:id',
            pageBuilder: (context, state) => _sheetPage(
              key: state.pageKey,
              child: SourceDetailScreen(
                sourceId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
              ),
            ),
            routes: [
              GoRoute(
                path: 'vocabulary',
                pageBuilder: (context, state) => _sheetPage(
                  key: state.pageKey,
                  child: SourceActivityScope(
                    sourceId:
                        int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                    child: const VocabularyActivityScreen(),
                  ),
                ),
              ),
              GoRoute(
                path: 'grammar',
                pageBuilder: (context, state) => _sheetPage(
                  key: state.pageKey,
                  child: SourceActivityScope(
                    sourceId:
                        int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
                    child: const GrammarActivityScreen(),
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'lesson',
            pageBuilder: (context, state) =>
                _sheetPage(key: state.pageKey, child: const LessonScreen()),
          ),
          GoRoute(
            path: 'practice',
            pageBuilder: (context, state) => _sheetPage(
              key: state.pageKey,
              child: switch (state.extra) {
                final PracticeSessionArgs args => PracticeSessionScreen(
                  args: args,
                ),
                _ => const _NoPractice(),
              },
            ),
          ),
          GoRoute(
            path: 'speak',
            pageBuilder: (context, state) =>
                _sheetPage(key: state.pageKey, child: const SpeakScreen()),
          ),
          GoRoute(
            path: 'profile/languages',
            pageBuilder: (context, state) => _slidePage(
              key: state.pageKey,
              child: const LanguagesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                pageBuilder: (context, state) => _sheetPage(
                  key: state.pageKey,
                  child: const AddLanguageScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// A private guest session has the same route access as a registered account.
/// The sign-in route remains available to signed-in users as the account page.
String? authRedirect({
  required bool isAuthenticated,
  required String location,
}) {
  if (!isAuthenticated && location != TlRoutes.signIn) {
    return TlRoutes.signIn;
  }
  return null;
}

/// Shown when the practice route is opened without a session, such as after a
/// browser refresh, since a session lives only in memory.
class _NoPractice extends StatelessWidget {
  const _NoPractice();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Practice')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This practice is no longer open.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/?tab=1'),
              child: const Text('Back to My learning'),
            ),
          ],
        ),
      ),
    ),
  );
}
