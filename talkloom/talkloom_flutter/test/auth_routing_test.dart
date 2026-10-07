import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/router.dart';

void main() {
  group('authRedirect', () {
    test('failed private-session bootstrap opens guest retry/account screen', () {
      expect(
        authRedirect(isAuthenticated: false, location: TlRoutes.home),
        TlRoutes.signIn,
      );
      expect(
        authRedirect(isAuthenticated: false, location: '/content/42'),
        TlRoutes.signIn,
      );
    });

    test('keeps the sign-in/account route accessible while signed out', () {
      expect(
        authRedirect(isAuthenticated: false, location: TlRoutes.signIn),
        isNull,
      );
    });

    test('private guest sessions access all app routes without registration', () {
      expect(
        authRedirect(isAuthenticated: true, location: TlRoutes.home),
        isNull,
      );
      expect(
        authRedirect(isAuthenticated: true, location: TlRoutes.signIn),
        isNull,
      );
      for (final path in ['/content/42', TlRoutes.speak, TlRoutes.lesson]) {
        expect(authRedirect(isAuthenticated: true, location: path), isNull);
      }
    });
  });
}
