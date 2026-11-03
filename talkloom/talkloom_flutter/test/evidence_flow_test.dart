import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/data/lesson_repository.dart';
import 'package:talkloom_flutter/design/components/tl_button.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/learning_session.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/features/content/source_detail_screen.dart';
import 'package:talkloom_flutter/features/speak/speak_screen.dart';
import 'package:talkloom_flutter/features/themes/themes_screen.dart';
import 'package:talkloom_flutter/features/words/words_screen.dart';

class FakeRepository extends LessonRepository {
  FakeRepository({this.status}) : super(Client('http://localhost:1/'));
  final String? status;
  final lessonIds = <int?>[];

  @override
  Future<ConversationTurn> speak({
    required LearningSession session,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String utterance,
    required double latencySec,
    int? lessonId,
  }) async {
    lessonIds.add(lessonId);
    return ConversationTurn.fromJson({
      'reply': 'Guten Tag',
      if (status != null) 'evaluation': {'status': status},
    }, latencySec);
  }
}

const _lesson = LessonContent(
  lessonId: 42,
  objectives: [],
  vocabulary: [
    VocabularyItem(id: 'haus', lemma: 'Haus', meaning: 'house'),
    VocabularyItem(id: 'tisch', lemma: 'Tisch', meaning: 'table'),
    VocabularyItem(id: 'baum', lemma: 'Baum', meaning: 'tree'),
  ],
  activities: [],
  conversation: ConversationPlan.empty,
);

class _ActiveLesson extends ActiveLessonController {
  _ActiveLesson(this.initial);
  final LessonContent? initial;
  @override
  LessonContent? build() => initial;
}

Widget _app(Widget home, List<Override> overrides) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    theme: buildTalkloomTheme(Brightness.light),
    home: Scaffold(body: home),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<FakeRepository> pumpSpeak(
    WidgetTester t, {
    LessonContent? lesson,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeRepository(status: status);
    await t.pumpWidget(
      _app(const SpeakScreen(), [
        sharedPreferencesProvider.overrideWithValue(prefs),
        lessonRepositoryProvider.overrideWithValue(repo),
        activeLessonProvider.overrideWith(() => _ActiveLesson(lesson)),
      ]),
    );
    await t.pump();
    await t.enterText(find.byType(TextField), 'Hallo');
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    return repo;
  }

  testWidgets('speak passes the active lesson id', (t) async {
    final repo = await pumpSpeak(t, lesson: _lesson);
    expect(repo.lessonIds, [42]);
  });

  test('turn without evaluation reports no evaluator status', () {
    final turn = ConversationTurn.fromJson({'reply': 'Hi'}, 1);
    expect(turn.evaluationStatus, isNull);
    expect(turn.evaluatorUnavailable, isFalse);
    expect(turn.evidenceEligible, isFalse);
  });

  testWidgets('unavailable evaluator is stated plainly', (t) async {
    await pumpSpeak(t, lesson: _lesson, status: 'evaluator_unavailable');
    expect(
      find.textContaining('could not be checked for progress'),
      findsOneWidget,
    );
  });

  testWidgets('Words shows only real evidence', (t) async {
    await t.pumpWidget(
      _app(const WordsScreen(), [
        lessonsProvider.overrideWith(
          (ref) async => [
            Lesson(
              id: 42,
              sourceId: 1,
              userId: 'u',
              targetLanguage: 'de',
              supportLanguage: 'en',
              objectives: const [],
              vocabulary:
                  '[{"id":"haus","lemma":"Haus","meaning":"house"},'
                  '{"id":"tisch","lemma":"Tisch","meaning":"table"},'
                  '{"id":"baum","lemma":"Baum","meaning":"tree"}]',
              grammar: '[]',
              activities: '[]',
              conversationPlan: '{}',
              createdAt: DateTime(2026),
            ),
          ],
        ),
        wordEvidenceProvider.overrideWith(
          (ref) async => [
            WordEvidenceSummary(
              itemId: 'haus',
              kind: 'vocabulary',
              eligibleCorrectTurns: 1,
              incorrectTurns: 0,
              ineligibleTurns: 0,
              threshold: 2,
              mastered: false,
            ),
            WordEvidenceSummary(
              itemId: 'tisch',
              kind: 'vocabulary',
              eligibleCorrectTurns: 2,
              incorrectTurns: 0,
              ineligibleTurns: 0,
              threshold: 2,
              mastered: true,
            ),
          ],
        ),
      ]),
    );
    await t.pumpAndSettle();
    expect(find.text('1 of 2 correct uses'), findsOneWidget);
    expect(find.text('Mastered'), findsOneWidget);
    expect(
      find.text('Not used in an evaluated conversation yet'),
      findsOneWidget,
    );
  });

  testWidgets('Words says plainly when evidence is unavailable', (t) async {
    await t.pumpWidget(
      _app(const WordsScreen(), [
        lessonsProvider.overrideWith(
          (ref) async => [
            Lesson(
              id: 1,
              sourceId: 1,
              userId: 'u',
              targetLanguage: 'de',
              supportLanguage: 'en',
              objectives: const [],
              vocabulary: '[{"id":"haus","lemma":"Haus","meaning":"house"}]',
              grammar: '[]',
              activities: '[]',
              conversationPlan: '{}',
              createdAt: DateTime(2026),
            ),
          ],
        ),
        wordEvidenceProvider.overrideWith((ref) async => throw Exception('x')),
      ]),
    );
    await t.pumpAndSettle();
    expect(
      find.text('Practice evidence is unavailable right now.'),
      findsOneWidget,
    );
    expect(find.textContaining('correct uses'), findsNothing);
    expect(find.text('Mastered'), findsNothing);
  });

  test('import stages each get their own message', () {
    final msgs = {
      for (final s in [
        'queued',
        'fetching',
        'transcript',
        'compiling',
        'validating',
        'saved',
        'failed',
      ])
        importStageMessage(s),
    };
    expect(msgs.length, 7);
    expect(importStageMessage('compiling'), contains('Extracting'));
  });

  testWidgets('TlButton is keyboard and semantics accessible', (t) async {
    var taps = 0;
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      _app(TlButton(label: 'Go', onPressed: () => taps++), []),
    );
    expect(find.bySemanticsLabel('Go'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('Themes clear-search is a labelled control', (t) async {
    final handle = t.ensureSemantics();
    await t.pumpWidget(_app(const ThemesScreen(), []));
    await t.enterText(find.byType(TextField), 'abc');
    await t.pump();
    expect(find.bySemanticsLabel('Clear search'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Clear search'));
    await t.pump();
    expect(find.bySemanticsLabel('Clear search'), findsNothing);
    handle.dispose();
  });
}
