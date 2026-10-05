import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/language.dart';
import 'package:talkloom_flutter/domain/learning_session.dart';
import 'package:talkloom_flutter/features/vault/lexicon_vault_screen.dart';

void main() {
  testWidgets('LexiconVaultScreen renders vault tabs and lemma cards correctly',
      (WidgetTester tester) async {
    // Provide a standard phone test viewport (400 x 800)
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const fakeSession = LearningSession(
      target: Language(
        code: 'de',
        englishName: 'German',
        endonym: 'Deutsch',
        flag: '🇩🇪',
      ),
      support: Language(
        code: 'en',
        englishName: 'English',
        endonym: 'English',
        flag: '🇬🇧',
      ),
      level: CefrLevel.b1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningSessionProvider.overrideWith(
            () => _FakeLearningSessionController(fakeSession),
          ),
        ],
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.dark),
          home: const Scaffold(
            body: LexiconVaultScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Subtitle are present
    expect(find.text('Lexicon & Vault'), findsOneWidget);
    expect(
      find.text('CEFR vocabulary categorized by Recognized vs Spontaneously Produced mastery.'),
      findsOneWidget,
    );

    // Verify Tab headers
    expect(find.text('Vocabulary Lexicon'), findsOneWidget);
    expect(find.text('Grammar Schemas'), findsOneWidget);

    // Verify sample lemmas render properly
    expect(find.text('die Kaution'), findsOneWidget);
    expect(find.textContaining('security deposit'), findsOneWidget);
  });

  test('Design tokens conform to 100x Luxury Dark Palette', () {
    expect(TlPalette.obsidian, const Color(0xFF0B0D11));
    expect(TlPalette.brassGold, const Color(0xFFE5A93C));
    expect(TlColors.dark.canvas, const Color(0xFF0B0D11));
    expect(TlColors.dark.primary, const Color(0xFFE5A93C));
  });
}

class _FakeLearningSessionController extends LearningSessionController {
  _FakeLearningSessionController(this._initial);
  final LearningSession _initial;

  @override
  LearningSession build() => _initial;
}
