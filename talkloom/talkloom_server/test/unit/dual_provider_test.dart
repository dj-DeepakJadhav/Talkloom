import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/dual_ai_compiler_service.dart';
import 'package:talkloom_server/src/services/dual_pedagogical_agent_service.dart';
import 'package:talkloom_server/src/services/ingestion_service.dart';
import 'package:talkloom_server/src/generated/protocol.dart'
    show ImportException;

void main() {
  group('Meta Lesson Compiler completeness', () {
    test(
      'uses Meta Model API and Muse Spark Contributor for lesson creation',
      () async {
        final lesson = _lessonDsl(vocabularyCount: 18, grammarCount: 4);
        late Uri requestUrl;
        late Map<String, dynamic> requestBody;
        final compiler = DualLessonCompilerService(
          metaApiKey: 'meta-test-key',
          client: MockClient((request) async {
            requestUrl = request.url;
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': jsonEncode(lesson)},
                  },
                ],
              }),
              200,
            );
          }),
        );

        final compiled = await compiler.compileLesson(
          sourceTitle: 'German basics',
          rawText: 'Ich lerne Deutsch und spreche über Berlin.',
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        );

        expect(requestUrl.host, 'api.meta.ai');
        expect(requestUrl.path, '/v1/chat/completions');
        expect(requestBody['model'], 'muse-spark-1.3');
        // Direct-answer task: keep reasoning light so the token budget
        // serves visible output, not hidden chain-of-thought.
        expect(requestBody['reasoning_effort'], 'low');
        final messages = requestBody['messages'] as List;
        final instructions = messages.map((m) => m['content']).join('\n');
        expect(instructions, contains('Learner-facing writing rules:'));
        expect(instructions, contains('Preserve transcripts'));
        expect(instructions, contains('requested explanation language'));
        expect((compiled['vocabulary'] as List), hasLength(18));
      },
    );

    test('rejects a lesson without vocabulary evidence', () async {
      final compiler = DualLessonCompilerService(
        metaApiKey: 'test-key',
        client: _metaMockClient(
          _lessonDsl(vocabularyCount: 0, grammarCount: 2),
        ),
      );

      await expectLater(
        compiler.compileLesson(
          sourceTitle: 'German A1 crash course',
          rawText: List.filled(
            300,
            'Ich lerne Deutsch und spreche über Berlin.',
          ).join(' '),
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'accepts a complete lesson and asks for full source coverage',
      () async {
        late Map<String, dynamic> requestBody;
        final lesson = _lessonDsl(vocabularyCount: 18, grammarCount: 4);
        final compiler = DualLessonCompilerService(
          metaApiKey: 'test-key',
          client: MockClient((request) async {
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': jsonEncode(lesson)},
                  },
                ],
              }),
              200,
            );
          }),
        );

        final compiled = await compiler.compileLesson(
          sourceTitle: 'German A1 crash course',
          rawText: List.filled(
            300,
            'Ich lerne Deutsch und spreche über Berlin.',
          ).join(' '),
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        );

        expect((compiled['vocabulary'] as List), hasLength(18));
        expect((compiled['grammar'] as List), hasLength(4));
        final userContent =
            (requestBody['messages'] as List).last['content'] as String;
        expect(userContent, contains('there is no upper ceiling'));
        expect(requestBody['max_tokens'], 8192);
      },
    );

    test(
      'does not manufacture a lesson when the Meta key is not configured',
      () async {
      final compiler = DualLessonCompilerService();

        await expectLater(
          compiler.compileLesson(
            sourceTitle: 'German A1 crash course',
            rawText: 'Ich lerne Deutsch.',
            targetLanguage: 'de',
            supportLanguage: 'en',
            estimatedLevel: 'A1',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Meta Pedagogical Agent State Machine & Telemetry Tests', () {
    test(
      'detects spontaneous production of target vocabulary with template fallback',
      () async {
        final agent = DualPedagogicalAgentService(
          metaApiKey: '',
        );
        final telemetry = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'landlord',
          situation: 'apartment viewing in Berlin',
          hiddenTargets: ['de:kaution', 'de:nebenkosten', 'de:einziehen'],
          previousTurns: [],
          learnerUtterance: 'Wie hoch ist die Kaution für die Wohnung?',
          responseLatencySec: 1.2,
        );

        expect(telemetry.targetProducedSpontaneously, isFalse);
        expect(telemetry.detectedTarget, isNull);
        expect(telemetry.responseMode, 'template_fallback');
        expect(telemetry.evidenceEligible, isFalse);
        expect(telemetry.recognizedTargets, contains('kaution'));
        expect(telemetry.cognitiveLoad, contains('Low'));
        expect(telemetry.activeMission.toLowerCase(), contains('kaution'));
        expect(telemetry.reply.isNotEmpty, isTrue);
      },
    );

    test(
      'adapts tactic when hesitation/latency is elevated with template fallback',
      () async {
        final agent = DualPedagogicalAgentService(
          metaApiKey: '',
        );
        final telemetry = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'landlord',
          situation: 'apartment viewing in Berlin',
          hiddenTargets: ['de:kaution', 'de:nebenkosten'],
          previousTurns: [],
          learnerUtterance: 'Ich... äh... weiß nicht genau.',
          responseLatencySec: 4.5,
        );

        expect(telemetry.targetProducedSpontaneously, isFalse);
        expect(telemetry.cognitiveLoad, contains('High'));
        expect(telemetry.activeTactic, contains('Simplify'));
      },
    );

    test(
      'steers conversation accurately with template fallback',
      () async {
        final agent = DualPedagogicalAgentService(
          metaApiKey: '',
        );
        final telemetry = await agent.stepConversation(
          targetLanguage: 'de',
          role: 'landlord',
          situation: 'apartment viewing in Berlin',
          hiddenTargets: ['de:kaution'],
          previousTurns: [],
          learnerUtterance: 'Die Kaution ist bezahlt.',
          responseLatencySec: 1.0,
        );

        expect(telemetry.targetProducedSpontaneously, isFalse);
        expect(telemetry.detectedTarget, isNull);
        expect(telemetry.responseMode, 'template_fallback');
        expect(telemetry.evidenceEligible, isFalse);
        expect(telemetry.recognizedTargets, contains('kaution'));
        expect(telemetry.reply.isNotEmpty, isTrue);
      },
    );
  });

  group('Universal Ingestion Pipeline Tests (YouTube & Multimodal OCR)', () {
    test(
      'extracts textual content from document and image media via fallback and Base64',
      () async {
        final ingestion = IngestionService();
        final base64Doc =
            'Mietvertrag für Wohnräume. Kaution: 3 Monatskaltmieten.';
        final encoded = base64Encode(utf8.encode(base64Doc));

        final extracted = await ingestion.extractTextFromMedia(
          base64Data: encoded,
          mimeType: 'text/plain',
        );

        expect(extracted.isNotEmpty, isTrue);
        expect(
          extracted.contains('Mietvertrag') || extracted.contains('Kaution'),
          isTrue,
        );
      },
    );

    test(
      'unreadable media raises ImportException, never sample text',
      () async {
        final ingestion = IngestionService();
        final binary = base64Encode(List<int>.generate(64, (i) => i % 32));

        await expectLater(
          ingestion.extractTextFromMedia(
            base64Data: binary,
            mimeType: 'image/jpeg',
          ),
          throwsA(
            isA<ImportException>().having((e) => e.code, 'code', 'unreadable'),
          ),
        );
      },
    );

    test('extracts YouTube transcript structure from video link', () async {
      final ingestion = IngestionService();
      final transcript = await ingestion.ingestUrl(
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );

      expect(transcript.isNotEmpty, isTrue);
      expect(
        transcript.contains('YouTube') ||
            transcript.contains('Video') ||
            transcript.contains('Transcript'),
        isTrue,
      );
    });
  });
}

MockClient _metaMockClient(Map<String, dynamic> lesson) => MockClient(
  (_) async => http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {'content': jsonEncode(lesson)},
        },
      ],
    }),
    200,
  ),
);

Map<String, dynamic> _lessonDsl({
  required int vocabularyCount,
  required int grammarCount,
}) => {
  'objectives': ['Understand the source'],
  'vocabulary': List.generate(
    vocabularyCount,
    (index) => {
      'id': 'de:wort$index',
      'lemma': 'Wort$index',
      'article': '',
      'meaning': 'Word $index',
      'sourceContext': 'Ich lerne Deutsch und spreche über Berlin.',
      'learnerState': 'recognized_not_active',
    },
  ),
  'grammar': List.generate(
    grammarCount,
    (index) => {
      'concept': 'Grammar pattern $index',
      'sourceSentence': 'Ich lerne Deutsch und spreche über Berlin.',
      'explanation': 'A source-grounded explanation.',
    },
  ),
  'activities': [
    {
      'type': 'context_choice',
      'targets': ['de:wort0'],
      'question': 'Choose the matching meaning.',
      'options': ['word', 'sentence', 'grammar'],
      'correctIndex': 0,
    },
  ],
  'conversation': {
    'role': 'German tutor',
    'situation': 'Discuss the source',
    'hiddenTargets': ['de:wort0'],
    'successCriteria': {'spontaneousTargetCount': 1},
  },
};
