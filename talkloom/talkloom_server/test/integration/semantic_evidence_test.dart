import 'dart:convert';

import 'package:talkloom_server/src/generated/protocol.dart';
import 'package:talkloom_server/src/lessons/pedagogical_endpoint.dart';
import 'package:talkloom_server/src/services/semantic_evaluator_service.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

const _userA = '00000000-0000-4000-8000-0000000000a1';
const _userB = '00000000-0000-4000-8000-0000000000b2';

/// Fake evaluator: returns a scripted outcome and records calls.
class _FakeEvaluator implements SemanticEvaluator {
  EvaluatorOutcome Function(List<EvaluationTarget> targets) respond;
  int calls = 0;
  _FakeEvaluator(this.respond);

  @override
  Future<EvaluatorOutcome> evaluate({
    required String targetLanguage,
    required String situation,
    required List<String> recentTutorTurns,
    required String learnerUtterance,
    required List<EvaluationTarget> targets,
  }) async {
    calls++;
    return respond(targets);
  }
}

EvaluatorOutcome _judge(
  List<EvaluationTarget> targets, {
  Set<String> used = const {},
  bool correct = true,
  bool spontaneous = true,
}) => EvaluatorOutcome.success(
  provider: 'fake',
  model: 'fake-judge-1',
  judgements: [
    for (final t in targets)
      TargetJudgement(
        itemId: t.itemId,
        used: used.contains(t.itemId),
        correct: used.contains(t.itemId) && correct,
        inContext: used.contains(t.itemId) && correct,
        spontaneous: used.contains(t.itemId) && spontaneous,
      ),
  ],
);

String _learner(String text) =>
    jsonEncode({'role': 'learner', 'content': text, 'assistance': 'none'});
String _tutor(String text, {String assistance = 'none'}) =>
    jsonEncode({'role': 'tutor', 'content': text, 'assistance': assistance});

void main() {
  withServerpod('Given the independent semantic evaluator', (
    sessionBuilder,
    endpoints,
  ) {
    final a = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(_userA, {}),
    );
    final b = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(_userB, {}),
    );
    late int lessonA;
    late _FakeEvaluator fake;

    final defaultFactory = PedagogicalEndpoint.evaluatorFactory;
    tearDown(() => PedagogicalEndpoint.evaluatorFactory = defaultFactory);

    setUp(() async {
      fake = _FakeEvaluator((t) => _judge(t, used: {'word:bahnhof'}));
      PedagogicalEndpoint.evaluatorFactory = (_) => fake;
      final session = sessionBuilder.build();
      final source = await Source.db.insertRow(
        session,
        Source(
          userId: _userA,
          type: 'text',
          rawText: 'Ich gehe zum Bahnhof.',
          title: 'Bahnhof',
          targetLanguage: 'de',
          cefrLevel: 'A1',
          createdAt: DateTime.utc(2026),
        ),
      );
      final lesson = await Lesson.db.insertRow(
        session,
        Lesson(
          userId: _userA,
          sourceId: source.id!,
          targetLanguage: 'de',
          supportLanguage: 'en',
          objectives: const ['travel'],
          vocabulary: jsonEncode([
            {
              'id': 'word:bahnhof',
              'lemma': 'Bahnhof',
              'meaning': 'train station',
              'sourceContext': 'Ich gehe zum Bahnhof.',
            },
          ]),
          grammar: jsonEncode([
            {
              'concept': 'Dativ nach zu',
              'sourceSentence': 'Ich gehe zum Bahnhof.',
              'explanation': 'zu takes the dative',
            },
          ]),
          activities: '[]',
          conversationPlan: '{}',
          createdAt: DateTime.utc(2026),
        ),
      );
      lessonA = lesson.id!;
    });

    Future<Map<String, dynamic>> turn(
      TestSessionBuilder who,
      String utterance, {
      List<String> history = const [],
      int? lessonId,
    }) async =>
        jsonDecode(
              await endpoints.pedagogical.stepConversationTurn(
                who,
                'de',
                'Passant',
                'Directions in Berlin',
                const ['word:bahnhof'],
                history,
                utterance,
                1.0,
                lessonId: lessonId ?? lessonA,
              ),
            )
            as Map<String, dynamic>;

    Future<List<WordEvidenceSummary>> summary(TestSessionBuilder who) =>
        endpoints.pedagogical.getWordEvidenceSummary(who, 'de');

    test('when used correctly once then evidence is eligible but not yet '
        'mastered', () async {
      final r = await turn(a, 'Wo ist der Bahnhof?');
      expect(r['evaluation']['status'], 'evaluated');
      expect(r['evaluation']['provider'], 'fake');
      expect(r['evaluation']['model'], 'fake-judge-1');
      expect(r['evidenceEligible'], isTrue);
      final s = (await summary(a)).single;
      expect(s.itemId, 'word:bahnhof');
      expect(s.eligibleCorrectTurns, 1);
      expect(s.mastered, isFalse);
      expect(
        await endpoints.learnerState.getLearnerState(a, 'de'),
        isNull,
      );
    });

    test('when correct across two separate turns then threshold reached and '
        'word becomes active', () async {
      await turn(a, 'Wo ist der Bahnhof?');
      await turn(a, 'Ich fahre zum Bahnhof.', history: [_learner('Hallo')]);
      final s = (await summary(a)).single;
      expect(s.eligibleCorrectTurns, 2);
      expect(s.threshold, masteryTurnThreshold);
      expect(s.mastered, isTrue);
      final state = await endpoints.learnerState.getLearnerState(a, 'de');
      expect(state!.activeWords, contains('word:bahnhof'));
    });

    test(
      'when used wrongly then counted as incorrect, never eligible',
      () async {
        fake.respond = (t) => _judge(t, used: {'word:bahnhof'}, correct: false);
        final r = await turn(a, 'Ich esse den Bahnhof.');
        expect(r['evidenceEligible'], isFalse);
        final s = (await summary(a)).single;
        expect(s.incorrectTurns, 1);
        expect(s.eligibleCorrectTurns, 0);
      },
    );

    test('when the tutor assisted the previous turn then status is assisted '
        'and the evaluator is not consulted', () async {
      final r = await turn(
        a,
        'Bahnhof',
        history: [_tutor('Sag: der Bahnhof', assistance: 'modelled')],
      );
      expect(r['evaluation']['status'], 'assisted');
      expect(r['evidenceEligible'], isFalse);
      expect(fake.calls, 0);
      expect(await summary(a), isEmpty);
    });

    test(
      'when the tutor said the word earlier then use is not spontaneous',
      () async {
        final r = await turn(
          a,
          'Der Bahnhof ist dort.',
          history: [_tutor('Suchst du den Bahnhof?')],
        );
        expect(r['evaluation']['status'], 'evaluated');
        expect(r['evidenceEligible'], isFalse);
        expect((await summary(a)).single.ineligibleTurns, 1);
      },
    );

    test(
      'when the evaluator fails then status is evaluator_unavailable',
      () async {
        fake.respond = (_) => throw StateError('network down');
        final r = await turn(a, 'Wo ist der Bahnhof?');
        expect(r['evaluation']['status'], 'evaluator_unavailable');
        expect(r['evaluation']['reason'], 'provider_error');
        expect(r['evidenceEligible'], isFalse);
        expect(await summary(a), isEmpty);
      },
    );

    test('when no provider key is configured then status is '
        'evaluator_unavailable with no_provider_key', () async {
      PedagogicalEndpoint.evaluatorFactory = (_) => ProviderSemanticEvaluator(
        metaApiKey: '',
      );
      final r = await turn(a, 'Wo ist der Bahnhof?');
      expect(r['evaluation']['status'], 'evaluator_unavailable');
      expect(r['evaluation']['reason'], 'no_provider_key');
      expect(await summary(a), isEmpty);
    });

    test(
      'when evaluator output is malformed then nothing is guessed',
      () async {
        fake.respond = (targets) {
          try {
            parseEvaluatorOutput(
              '{"targets":[{"itemId":"word:bahnhof"}]}',
              targets,
            );
          } on FormatException {
            return const EvaluatorOutcome.failure(
              failureReason: 'malformed_output',
              provider: 'fake',
              model: 'fake-judge-1',
            );
          }
          fail('malformed output was accepted');
        };
        final r = await turn(a, 'Wo ist der Bahnhof?');
        expect(r['evaluation']['status'], 'evaluator_unavailable');
        expect(r['evaluation']['reason'], 'malformed_output');
        expect(await summary(a), isEmpty);
      },
    );

    test('when another user targets the lesson then it is rejected and '
        'summaries stay isolated', () async {
      await turn(a, 'Wo ist der Bahnhof?');
      await expectLater(turn(b, 'Wo ist der Bahnhof?'), throwsA(anything));
      expect(await summary(b), isEmpty);
      expect(await summary(a), hasLength(1));
    });

    test('client correctness flags are still never trusted', () async {
      final e = await endpoints.learnerState.recordEvidenceEvent(
        a,
        targetLanguage: 'de',
        itemId: 'word:bahnhof',
        activityType: 'speaking',
        supportLevel: 'none',
        spontaneous: true,
        correct: true,
      );
      expect(e.correct, isFalse);
      expect(await summary(a), isEmpty);
    });
  });

  group('parseEvaluatorOutput', () {
    const targets = [
      EvaluationTarget(
        itemId: 'word:bahnhof',
        kind: 'vocabulary',
        form: 'Bahnhof',
        meaning: 'train station',
        sourceContext: '',
      ),
    ];
    test('accepts fenced well-formed JSON', () {
      final j = parseEvaluatorOutput(
        '```json\n{"targets":[{"itemId":"word:bahnhof","used":true,'
        '"correct":true,"inContext":true,"spontaneous":true}]}\n```',
        targets,
      );
      expect(j.single.correct, isTrue);
    });
    for (final bad in [
      'not json',
      '{"targets":[]}',
      '{"targets":[{"itemId":"word:other","used":true,"correct":true,'
          '"inContext":true,"spontaneous":true}]}',
      '{"targets":[{"itemId":"word:bahnhof","used":"yes","correct":true,'
          '"inContext":true,"spontaneous":true}]}',
    ]) {
      test('rejects $bad', () {
        expect(
          () => parseEvaluatorOutput(bad, targets),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });
}
