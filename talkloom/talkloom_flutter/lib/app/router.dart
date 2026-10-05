import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/speak/speak_screen.dart';

// ignore: unused_import
import 'providers.dart';

abstract final class TlRoutes {
  static const onboarding = '/welcome';
  static const home = '/';
  static const lesson = '/lesson';
  static const speak = '/speak';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // Always start at home. AppShell renders immediately with the guest session.
    // The onboarding route is still reachable if we want to show it later.
    initialLocation: TlRoutes.home,
    routes: [
      GoRoute(
        path: TlRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: TlRoutes.home,
        builder: (context, state) => const AppShell(),
        routes: [
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
