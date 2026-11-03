import 'package:test/test.dart';
import 'package:talkloom_server/src/services/dual_ai_compiler_service.dart';

/// Failure modes from the production screenshots: a sentence builder whose
/// answer is "- die Spaghetti (Plural): spaghetti" and grammar entries like
/// "Ins for destination" with tautological explanations.
Map<String, dynamic> validLesson() => {
  'objectives': ['Greet people politely'],
  'vocabulary': [
    {
      'id': 'de:zentrum',
      'lemma': 'Zentrum',
      'article': 'das',
      'meaning': 'city center',
      'sourceContext': 'Ins Zentrum bitte.',
      'learnerState': 'recognized_not_active',
    },
  ],
  'grammar': [
    {
      'concept': 'Wechselpräpositionen mit Akkusativ',
      'sourceSentence': 'Fahren Sie bitte ins Zentrum der Stadt.',
      'explanation':
          'Nach Wechselpräpositionen wie "in" steht der Akkusativ, wenn eine Richtung oder ein Ziel beschrieben wird.',
    },
  ],
  'activities': [
    {
      'type': 'sentence_builder',
      'target': 'Fahren Sie bitte ins Zentrum',
      'scrambledTokens': ['Zentrum', 'Fahren', 'ins', 'bitte', 'Sie'],
    },
  ],
  'conversation': {
    'role': 'taxi driver',
    'situation': 'ride into the city',
    'hiddenTargets': ['de:zentrum'],
    'culturalNotes': ['Greet the driver first.'],
    'successCriteria': {'spontaneousTargetCount': 1},
  },
};

String codeOf(void Function() fn) {
  try {
    fn();
  } on LessonDslValidationException catch (e) {
    return e.code;
  }
  return 'passed';
}

void main() {
  group('validateDslShape quality gates', () {
    test('accepts a clean lesson', () {
      expect(
        codeOf(
          () => DualLessonCompilerService(
            metaApiKey: '',
          ).validateDslShape(validLesson()),
        ),
        'passed',
      );
    });

    test('rejects the screenshot sentence builder', () {
      final lesson = validLesson();
      (lesson['activities'] as List).first = {
        'type': 'sentence_builder',
        'target': '- die Spaghetti (Plural): spaghetti',
        'scrambledTokens': ['-', 'Spaghetti', 'die', 'spaghetti', '(Plural):'],
      };
      expect(
        codeOf(
          () => DualLessonCompilerService(
            metaApiKey: '',
          ).validateDslShape(lesson),
        ),
        anyOf('dirty_builder_target', 'junk_builder_token'),
      );
    });

    test('rejects tokens that do not match the target', () {
      final lesson = validLesson();
      (lesson['activities'] as List).first = {
        'type': 'sentence_builder',
        'target': 'Fahren Sie bitte ins Zentrum',
        'scrambledTokens': ['Fahren', 'Sie', 'bitte', 'Kartoffel'],
      };
      expect(
        codeOf(
          () => DualLessonCompilerService(
            metaApiKey: '',
          ).validateDslShape(lesson),
        ),
        'builder_tokens_mismatch',
      );
    });

    test('rejects tautological grammar', () {
      final lesson = validLesson();
      (lesson['grammar'] as List).first = {
        'concept': 'Ins for destination',
        'sourceSentence': 'Ins Zentrum bitte',
        'explanation': 'Ins names the destination.',
      };
      expect(
        codeOf(
          () => DualLessonCompilerService(
            metaApiKey: '',
          ).validateDslShape(lesson),
        ),
        anyOf(
          'thin_grammar_explanation',
          'short_grammar_sentence',
          'grammar_is_vocabulary',
        ),
      );
    });

    test('rejects lemma repeated as meaning', () {
      final lesson = validLesson();
      ((lesson['vocabulary'] as List).first as Map)['lemma'] = 'Spaghetti';
      ((lesson['vocabulary'] as List).first as Map)['meaning'] = 'spaghetti';
      expect(
        codeOf(
          () => DualLessonCompilerService(
            metaApiKey: '',
          ).validateDslShape(lesson),
        ),
        'trivial_vocabulary_meaning',
      );
    });
  });
}
