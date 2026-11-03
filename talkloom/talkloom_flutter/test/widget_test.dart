import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/data/lesson_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_flutter/domain/language.dart';

void main() {
  test(
    'language switching retains the first language and independent explanation setting',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final controller = container.read(learningSessionProvider.notifier);
      final german = container.read(learningSessionProvider).target;
      final spanish = LanguageCatalog.byCode('es');
      final french = LanguageCatalog.byCode('fr');
      await controller.switchTarget(spanish);
      expect(
        prefs.getStringList('talkloom.languages.v1'),
        containsAll([german.code, 'es']),
      );
      await controller.save(
        container.read(learningSessionProvider).copyWith(support: french),
      );
      await controller.switchTarget(german);
      expect(container.read(learningSessionProvider).support, french);
    },
  );
  test('Editorial palette supports light and dark appearance', () {
    expect(TlColors.light.canvas, TlPalette.warmPaper);
    expect(TlColors.light.primary, TlPalette.espresso);
    expect(TlColors.dark.primary, TlPalette.coralLight);
  });

  test('Appearance starts light and persists after switching', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(appThemeProvider), ThemeMode.light);
    container.read(appThemeProvider.notifier).toggle();
    expect(container.read(appThemeProvider), ThemeMode.dark);
    expect(prefs.getBool('talkloom.dark-mode'), isTrue);
    container.read(appThemeProvider.notifier).toggle();
    expect(container.read(appThemeProvider), ThemeMode.light);
  });

  test('Conversation turns require explicit server evidence eligibility', () {
    final legacy = ConversationTurn.fromJson(
      {
        'reply': 'Gut gemacht.',
        'targetProducedSpontaneously': true,
        'detectedTarget': 'de:mitnehmen',
      },
      1,
    );
    expect(legacy.producedSpontaneously, isTrue);
    expect(legacy.evidenceEligible, isFalse);
    expect(legacy.responseMode, 'unknown');

    final fallback = ConversationTurn.fromJson(
      {
        'reply': 'Sag noch etwas dazu.',
        'targetProducedSpontaneously': true,
        'detectedTarget': 'de:mitnehmen',
        'responseMode': 'template_fallback',
        'evidenceEligible': false,
      },
      1,
    );
    expect(fallback.isTemplateFallback, isTrue);
    expect(fallback.evidenceEligible, isFalse);
  });
}
