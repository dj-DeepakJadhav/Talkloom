import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import '../client.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/speak/speak_screen.dart';
import '../features/content/source_detail_screen.dart';
import '../screens/sign_in_screen.dart';

abstract final class TlRoutes {
  static const onboarding = '/welcome';
  static const home = '/';
  static const lesson = '/lesson';
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
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: TlRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: TlRoutes.home,
        builder: (context, state) => AppShell(
          initialIndex:
              int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'content/:id',
            builder: (context, state) => SourceDetailScreen(
              sourceId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
            ),
          ),
          GoRoute(
            path: 'lesson',
            builder: (context, state) => const LessonScreen(),
          ),
          GoRoute(
            path: 'speak',
            builder: (context, state) => const SpeakScreen(),
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
