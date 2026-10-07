import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/data/lesson_repository.dart';

void main() {
  test('Editorial palette supports light and dark appearance', () {
    expect(TlColors.light.canvas, TlPalette.paper);
    expect(TlColors.light.primary, TlPalette.coral);
    expect(TlColors.dark.primary, TlPalette.coralLight);
  });

  test('Appearance starts light and can switch back from dark', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(appThemeProvider), ThemeMode.light);
    container.read(appThemeProvider.notifier).toggle();
    expect(container.read(appThemeProvider), ThemeMode.dark);
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
