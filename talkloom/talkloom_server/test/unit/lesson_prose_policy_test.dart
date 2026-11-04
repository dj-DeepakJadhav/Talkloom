import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/dual_ai_compiler_service.dart';
import 'package:talkloom_server/src/services/plain_language_policy.dart';

const _source =
    'Ich trinke jeden Morgen einen Kaffee. Die Katze schläft auf dem Sofa.';

Map<String, dynamic> _emojiLesson() => {
  'objectives': ['🎯 Learn morning words ✨'],
  'vocabulary': [
    {
      'id': 'de:kaffee',
      'lemma': 'Kaffee',
      'article': 'der',
      'meaning': 'coffee ☕ fresh and hot',
      'sourceContext': 'Ich trinke jeden Morgen einen Kaffee.',
      'learnerState': 'recognized_not_active',
    },
    {
      'id': 'de:katze',
      'lemma': 'Katze',
      'article': 'die',
      'meaning': 'cat',
      'sourceContext': 'Die Katze schläft auf dem Sofa.',
      'learnerState': 'recognized_not_active',
    },
  ],
  'grammar': [],
  'activities': [
    {
      'type': 'context_choice',
      'targets': ['de:kaffee'],
      'question': 'What did he drink? 🤔',
      'options': ['Kaffee 🎉', 'Tee', 'Wasser'],
      'correctIndex': 0,
    },
    {
      'type': 'speak_response',
      'objective': 'Order a coffee politely 🗣️',
    },
  ],
  'conversation': {
    'role': 'Barista ☕',
    'situation': 'ordering at a café',
    'hiddenTargets': ['de:kaffee'],
    'culturalNotes': ['Germans love their Kaffee ☕'],
    'successCriteria': {'spontaneousTargetCount': 1},
  },
};

void main() {
  group('stripDecorativeSymbols', () {
    test('removes emojis but keeps German letters', () {
      expect(
        stripDecorativeSymbols('Kaffee ☕ trinken! Grüße aus München 🎉'),
        'Kaffee trinken! Grüße aus München',
      );
    });

    test('leaves plain text untouched', () {
      expect(
        stripDecorativeSymbols('Die Katze schläft.'),
        'Die Katze schläft.',
      );
    });
  });

  group('sanitizeLessonProse', () {
    test('cleans generated fields, keeps evidence verbatim', () {
      final lesson = _emojiLesson();
      DualLessonCompilerService.sanitizeLessonProse(lesson);

      expect(lesson['objectives'], ['Learn morning words']);
      final vocab = lesson['vocabulary'] as List;
      expect(
        (vocab[0] as Map)['meaning'],
        'coffee fresh and hot',
      );
      // Evidence keeps the source exactly as written.
      expect(
        (vocab[0] as Map)['sourceContext'],
        'Ich trinke jeden Morgen einen Kaffee.',
      );
      final activities = lesson['activities'] as List;
      expect(
        (activities[0] as Map)['question'],
        'What did he drink?',
      );
      expect((activities[0] as Map)['options'], ['Kaffee', 'Tee', 'Wasser']);
      final conversation = lesson['conversation'] as Map;
      expect(conversation['role'], 'Barista');
      expect(
        conversation['culturalNotes'],
        ['Germans love their Kaffee'],
      );
    });
  });

  group('compileLesson', () {
    test('returns emoji-free prose from a decorated model response', () async {
      final compiler = DualLessonCompilerService(
        metaApiKey: 'test-key',
        client: MockClient(
          (request) async => http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': jsonEncode(_emojiLesson())},
                  },
                ],
              }),
            ),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final lesson = await compiler.compileLesson(
        sourceTitle: 'Morning',
        rawText: _source,
        targetLanguage: 'de',
        supportLanguage: 'en',
        estimatedLevel: 'A1',
      );

      final vocab = lesson['vocabulary'] as List;
      expect(
        (vocab[0] as Map)['meaning'],
        isNot(contains('☕')),
      );
      expect(
        (vocab[0] as Map)['sourceContext'],
        'Ich trinke jeden Morgen einen Kaffee.',
      );
      expect(
        (lesson['conversation'] as Map)['role'],
        'Barista',
      );
    });
  });
}
