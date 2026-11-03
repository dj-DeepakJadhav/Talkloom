import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/domain/practice_engine.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/practice/practice_session_screen.dart';

const _brot = VocabularyItem(id: 'brot', lemma: 'Brot', meaning: 'bread');

Future<Widget> _app(List<PracticeExercise> exercises) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    child: MaterialApp(
      theme: buildTalkloomTheme(Brightness.light),
      home: PracticeSessionScreen(
        args: PracticeSessionArgs(
          title: 'Test link',
          set: PracticeSet(exercises: exercises, words: const [_brot]),
        ),
      ),
    ),
  );
}

const _question = ChoiceExercise(
  kind: ChoiceKind.meaning,
  prompt: 'What does this mean?',
  sentence: 'Brot',
  options: ['bread', 'water'],
  correctIndex: 0,
  wordId: 'brot',
);

Future<void> _tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Check stays disabled until an answer is chosen', (tester) async {
    await tester.pumpWidget(await _app([_question]));
    await tester.pumpAndSettle();

    // Tapping Check with nothing chosen does nothing.
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Nice!'), findsNothing);
    expect(find.text('Not quite'), findsNothing);

    await tester.tap(find.text('bread'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Check');
    expect(find.text('Nice!'), findsOneWidget);
  });

  testWidgets('a wrong answer shows the right one and the question returns', (
    tester,
  ) async {
    await tester.pumpWidget(await _app([_question]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('water'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Check');
    expect(find.text('Not quite'), findsOneWidget);
    expect(find.text('Answer: bread'), findsOneWidget);

    // The missed question is asked once more before the session ends.
    await _tapButton(tester, 'Continue');
    expect(find.text('What does this mean?'), findsOneWidget);
    expect(find.text('Practice complete'), findsNothing);

    await tester.tap(find.text('bread'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Check');
    await _tapButton(tester, 'Continue');
    expect(find.text('Practice complete'), findsOneWidget);
    // One right of two asked: the miss counts, the retry counts.
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('a new word is introduced, not scored', (tester) async {
    await tester.pumpWidget(
      await _app([const WordIntroExercise(_brot), _question]),
    );
    await tester.pumpAndSettle();

    expect(find.text('New word'), findsOneWidget);
    expect(find.text('Brot'), findsOneWidget);
    await _tapButton(tester, 'Got it');

    await tester.tap(find.text('bread'));
    await tester.pumpAndSettle();
    await _tapButton(tester, 'Check');
    await _tapButton(tester, 'Continue');
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('sentence builder checks the order the learner built', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _app([
        const SentenceExercise(
          target: 'Ich esse Brot',
          tokens: ['Brot', 'Ich', 'esse'],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    for (final word in ['Ich', 'esse', 'Brot']) {
      await tester.tap(find.text(word).last);
      await tester.pumpAndSettle();
    }
    await _tapButton(tester, 'Check');
    expect(find.text('Nice!'), findsOneWidget);
  });

  testWidgets('word match is complete only when every pair is matched', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _app([
        const MatchExercise([
          (left: 'Brot', right: 'bread'),
          (left: 'Haus', right: 'house'),
        ]),
      ]),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.text('Nice!'), findsNothing);

    for (final pair in [('Brot', 'bread'), ('Haus', 'house')]) {
      await tester.tap(find.text(pair.$1));
      await tester.tap(find.text(pair.$2));
      await tester.pumpAndSettle();
    }
    await _tapButton(tester, 'Check');
    expect(find.text('Nice!'), findsOneWidget);
  });
}
