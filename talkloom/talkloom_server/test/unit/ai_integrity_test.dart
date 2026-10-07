import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:talkloom_server/src/lessons/lesson_compiler_endpoint.dart';
import 'package:talkloom_server/src/lessons/pedagogical_endpoint.dart';
import 'package:talkloom_server/src/services/dual_ai_compiler_service.dart';
import 'package:talkloom_server/src/services/dual_pedagogical_agent_service.dart';
import 'package:test/test.dart';

void main() {
  group('AI provider configuration', () {
    test('maps every configured provider and defaults safely', () {
      expect(AiProvider.fromSetting('gemini'), AiProvider.gemini);
      expect(AiProvider.fromSetting('nebius'), AiProvider.nebius);
      expect(AiProvider.fromSetting('nvidia'), AiProvider.nvidia);
      expect(AiProvider.fromSetting('groq'), AiProvider.groq);
      expect(AiProvider.fromSetting('unknown'), AiProvider.nvidia);
    });

    test('lesson and learner endpoints require an authenticated user', () {
      expect(LessonCompilerEndpoint().requireLogin, isTrue);
      expect(PedagogicalEndpoint().requireLogin, isTrue);
    });
  });

  group('lesson DSL validation and bounded repair', () {
    test(
      'resolves bare lemma targets only against extracted vocabulary',
      () async {
        final lesson =
            jsonDecode(jsonEncode(_validLesson)) as Map<String, dynamic>;
        (lesson['conversation'] as Map)['hiddenTargets'] = ['lernen'];
        (lesson['activities'] as List).first['targets'] = ['German:lernen'];
        final client = _QueueClient([_groqResponse(jsonEncode(lesson))]);
        final service = DualLessonCompilerService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          client: client,
        );
        final result = await service.compileLesson(
          sourceTitle: 'German basics',
          rawText: _source,
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        );
        expect((result['conversation'] as Map)['hiddenTargets'], ['de:lernen']);
        expect((result['activities'] as List).first['targets'], ['de:lernen']);
        expect(client.requests, hasLength(1));
      },
    );
    test(
      'rejects ambiguous duplicate IDs rather than guessing target words',
      () async {
        final lesson =
            jsonDecode(jsonEncode(_validLesson)) as Map<String, dynamic>;
        for (final item in lesson['vocabulary'] as List) {
          item['id'] = 'duplicate';
        }
        (lesson['conversation'] as Map)['hiddenTargets'] = ['duplicate'];
        final client = _QueueClient([
          _groqResponse(jsonEncode(lesson)),
          _groqResponse(jsonEncode(lesson)),
        ]);
        final service = DualLessonCompilerService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          client: client,
        );
        await expectLater(
          service.compileLesson(
            sourceTitle: 'German basics',
            rawText: _source,
            targetLanguage: 'de',
            supportLanguage: 'en',
            estimatedLevel: 'A1',
          ),
          throwsA(isA<LessonCompilationException>()),
        );
        expect(client.requests, hasLength(2));
      },
    );
    test(
      'repairs vocabulary ID formatting and references without another AI call',
      () async {
        final lesson =
            jsonDecode(jsonEncode(_validLesson)) as Map<String, dynamic>;
        final oldId = (lesson['vocabulary'] as List).first['id'];
        (lesson['vocabulary'] as List).first['id'] = 'word_1';
        final conversation = lesson['conversation'] as Map;
        conversation['hiddenTargets'] = (conversation['hiddenTargets'] as List)
            .map((id) => id == oldId ? 'word_1' : id)
            .toList();
        for (final activity
            in (lesson['activities'] as List).whereType<Map>()) {
          if (activity['targets'] is List) {
            activity['targets'] = (activity['targets'] as List)
                .map((id) => id == oldId ? 'word_1' : id)
                .toList();
          }
        }
        final client = _QueueClient([_groqResponse(jsonEncode(lesson))]);
        final service = DualLessonCompilerService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          client: client,
        );
        final result = await service.compileLesson(
          sourceTitle: 'German basics',
          rawText: _source,
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        );
        expect((result['vocabulary'] as List).first['id'], oldId);
        expect(
          (result['conversation'] as Map)['hiddenTargets'],
          isNot(contains('word_1')),
        );
        expect(client.requests, hasLength(1));
      },
    );
    test(
      'accepts source evidence quoted as a punctuation-free excerpt',
      () async {
        final lesson =
            jsonDecode(jsonEncode(_validLesson)) as Map<String, dynamic>;
        (lesson['vocabulary'] as List).first['sourceContext'] =
            'ich lerne deutsch';
        final client = _QueueClient([_groqResponse(jsonEncode(lesson))]);
        final service = DualLessonCompilerService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          groqBaseUrl: 'https://groq.test/v1',
          client: client,
        );

        final result = await service.compileLesson(
          sourceTitle: 'German basics',
          rawText: _source,
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        );

        expect(result['vocabulary'], hasLength(4));
        expect(client.requests, hasLength(1));
      },
    );

    test(
      'repairs an invalid schema once and uses the selected Groq provider',
      () async {
        final rejected =
            jsonDecode(jsonEncode(_validLesson)) as Map<String, dynamic>;
        (rejected['conversation'] as Map)['hiddenTargets'] = ['not-extracted'];
        final client = _QueueClient([
          _groqResponse(jsonEncode(rejected)),
          _groqResponse(jsonEncode(_validLesson)),
        ]);
        final service = DualLessonCompilerService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          groqBaseUrl: 'https://groq.test/v1',
          client: client,
        );

        final result = await service.compileLesson(
          sourceTitle: 'German basics',
          rawText: _source,
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        );

        expect(result['vocabulary'], hasLength(4));
        expect(client.requests, hasLength(2));
        expect(client.requests.first.uri.host, 'groq.test');
        expect(client.requests.last.body, contains('REPAIR REQUIREMENTS'));
        expect(client.requests.last.body, contains('not-extracted'));
        expect(
          client.requests.last.body,
          contains('unknown_conversation_target'),
        );
      },
    );

    test(
      'stops after one repair and never returns an invalid lesson',
      () async {
        final client = _QueueClient([_groqResponse('{}'), _groqResponse('{}')]);
        final service = DualLessonCompilerService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          groqBaseUrl: 'https://groq.test/v1',
          client: client,
        );

        await expectLater(
          service.compileLesson(
            sourceTitle: 'German basics',
            rawText: _source,
            targetLanguage: 'de',
            supportLanguage: 'en',
            estimatedLevel: 'A1',
          ),
          throwsA(isA<LessonCompilationException>()),
        );
        expect(client.requests, hasLength(2));
      },
    );
  });

  group('conversation assistance and evidence integrity', () {
    test(
      'legacy history is treated as tutor assistance and fallback is degraded',
      () async {
        final agent = DualPedagogicalAgentService(provider: AiProvider.groq);
        final result = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'tutor',
          situation: 'practice',
          hiddenTargets: const ['de:kaution'],
          previousTurns: const ['Try saying Kaution in your answer.'],
          learnerUtterance: 'Die Kaution ist hoch.',
          responseLatencySec: 2,
        );

        expect(result.recognizedTargets, ['kaution']);
        expect(result.assistedTargets, ['kaution']);
        expect(result.targetProducedSpontaneously, isFalse);
        expect(result.detectedTarget, isNull);
        expect(result.responseMode, 'template_fallback');
        expect(result.evidenceEligible, isFalse);
        expect(result.toJson()['evidenceEligible'], isFalse);
        expect(result.reply, isNot(contains('Sehr gut')));
      },
    );

    test(
      'typed tutor and learner turns retain roles in provider history',
      () async {
        final client = _QueueClient([
          _chatResponse('Wie hoch ist die Miete?'),
        ]);
        final agent = DualPedagogicalAgentService(
          provider: AiProvider.groq,
          groqApiKey: 'test-only',
          groqBaseUrl: 'https://groq.test/v1',
          nvidiaApiKey: 'also-configured',
          client: client,
        );

        final result = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'landlord',
          situation: 'apartment viewing',
          hiddenTargets: const ['de:kaution'],
          previousTurns: [
            jsonEncode({
              'role': 'learner',
              'content': 'Ich suche eine Wohnung.',
              'assistance': 'none',
            }),
            jsonEncode({
              'role': 'tutor',
              'content': 'Wie viele Zimmer brauchen Sie?',
              'assistance': 'none',
            }),
          ],
          learnerUtterance: 'Ich brauche zwei Zimmer.',
          responseLatencySec: 1.8,
        );

        final request = jsonDecode(client.requests.single.body) as Map;
        final messages = (request['messages'] as List).cast<Map>();
        expect(messages.map((message) => message['role']).toList(), [
          'system',
          'user',
          'assistant',
          'user',
        ]);
        expect(result.responseMode, 'groq');
        expect(result.evidenceEligible, isFalse);
        expect(client.requests.single.uri.host, 'groq.test');
      },
    );

    test(
      'word spotting requires an exact token and prior assistance blocks spontaneity',
      () async {
        final agent = DualPedagogicalAgentService(provider: AiProvider.nvidia);
        final partial = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'tutor',
          situation: 'practice',
          hiddenTargets: const ['de:kaution'],
          previousTurns: const [],
          learnerUtterance: 'Kautionsfrei ist das Haus.',
          responseLatencySec: 2,
        );
        final assisted = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'tutor',
          situation: 'practice',
          hiddenTargets: const ['de:kaution'],
          previousTurns: [
            jsonEncode({
              'role': 'tutor',
              'content': 'Try the word Kaution.',
              'assistance': 'none',
            }),
          ],
          learnerUtterance: 'Die Kaution ist hoch.',
          responseLatencySec: 2,
        );

        expect(partial.recognizedTargets, isEmpty);
        expect(assisted.assistedTargets, ['kaution']);
        expect(assisted.targetProducedSpontaneously, isFalse);
        expect(assisted.evidenceEligible, isFalse);
      },
    );
  });
}

const _source =
    'Ich lerne Deutsch. Ich spreche Deutsch. Das ist ein Haus. Wir wohnen hier.';

final _validLesson = <String, dynamic>{
  'objectives': ['Talk about learning German'],
  'vocabulary': [
    {
      'id': 'de:lernen',
      'lemma': 'lernen',
      'article': '',
      'meaning': 'to learn',
      'sourceContext': 'Ich lerne Deutsch.',
    },
    {
      'id': 'de:sprechen',
      'lemma': 'sprechen',
      'article': '',
      'meaning': 'to speak',
      'sourceContext': 'Ich spreche Deutsch.',
    },
    {
      'id': 'de:deutsch',
      'lemma': 'Deutsch',
      'article': '',
      'meaning': 'German',
      'sourceContext': 'Ich lerne Deutsch.',
    },
    {
      'id': 'de:haus',
      'lemma': 'Haus',
      'article': 'das',
      'meaning': 'house',
      'sourceContext': 'Das ist ein Haus.',
    },
  ],
  'grammar': [
    {
      'concept': 'Present tense',
      'sourceSentence': 'Ich lerne Deutsch.',
      'explanation': 'The verb form changes with the subject.',
    },
  ],
  'activities': [
    {
      'type': 'context_choice',
      'targets': ['de:lernen'],
      'question': 'What does lernen mean?',
      'options': ['to learn', 'to speak', 'house'],
      'correctIndex': 0,
    },
    {
      'type': 'sentence_builder',
      'target': 'Ich lerne Deutsch.',
      'scrambledTokens': ['Deutsch', 'Ich', 'lerne'],
    },
    {'type': 'speak_response', 'objective': 'Say what you are learning.'},
  ],
  'conversation': {
    'role': 'conversation partner',
    'situation': 'meeting someone',
    'hiddenTargets': ['de:lernen'],
    'successCriteria': {'spontaneousTargetCount': 1},
  },
};

http.Response _groqResponse(String content) => http.Response(
  jsonEncode({
    'choices': [
      {
        'message': {'content': content},
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _chatResponse(String content) => http.Response(
  jsonEncode({
    'choices': [
      {
        'message': {'content': content},
      },
    ],
  }),
  200,
  headers: {'content-type': 'application/json'},
);

class _QueueClient extends http.BaseClient {
  final List<http.Response> _responses;
  final requests = <_CapturedRequest>[];

  _QueueClient(this._responses);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await request.finalize().bytesToString();
    requests.add(_CapturedRequest(request.url, body));
    final response = _responses.removeAt(0);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}

class _CapturedRequest {
  final Uri uri;
  final String body;
  const _CapturedRequest(this.uri, this.body);
}
