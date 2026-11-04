import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/profile/profile_screen.dart';

void main() {
  testWidgets(
    'Profile chooses System, Light and Dark and follows device changes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(800, 1700);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Consumer(
            builder: (context, ref, _) => MaterialApp(
              theme: buildTalkloomTheme(Brightness.light),
              darkTheme: buildTalkloomTheme(Brightness.dark),
              themeMode: ref.watch(appThemeProvider),
              home: const Scaffold(body: ProfileScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Brightness appearance() =>
          Theme.of(tester.element(find.byType(ProfileScreen))).brightness;
      expect(appearance(), Brightness.dark);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpAndSettle();
      expect(appearance(), Brightness.light);

      for (final label in ['Dark', 'Light', 'System']) {
        await tester.ensureVisible(find.text('Appearance'));
        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();
        expect(find.text('Follow your device’s appearance'), findsOneWidget);
        await tester.tap(find.widgetWithText(ListTile, label).last);
        await tester.pumpAndSettle();
        expect(prefs.getString('talkloom.appearance.v1'), label.toLowerCase());
        expect(
          appearance(),
          label == 'Dark' ? Brightness.dark : Brightness.light,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
}
