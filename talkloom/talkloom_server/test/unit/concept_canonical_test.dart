import 'package:test/test.dart';
import 'package:talkloom_server/src/knowledge/concept_canonical_service.dart';

void main() {
  group('canonical keys', () {
    test('vocab id is lang + lowercase lemma', () {
      expect(canonicalVocabId('de', 'Kaution'), 'de:kaution');
      expect(canonicalVocabId(' DE ', '  Neben Kosten '), 'de:neben kosten');
    });

    test('grammar key slugifies variants to one key', () {
      expect(
        canonicalGrammarKey('polite_indirect_question'),
        canonicalGrammarKey('Polite Indirect Question!'),
      );
      expect(
        canonicalGrammarKey('polite indirect inquiry'),
        isNot('polite_indirect_question'),
      );
    });
  });

  group('canonicalizeLessonDsl', () {
    test('repairs drift in place without touching content', () {
      final lesson = {
        'vocabulary': [
          {'id': 'WRONG', 'lemma': 'Kaution', 'meaning': 'security deposit'},
        ],
        'grammar': [
          {'concept': 'Polite Indirect Question!'},
        ],
      };
      canonicalizeLessonDsl(lesson, 'de');
      final vocab = (lesson['vocabulary'] as List).first as Map;
      expect(vocab['id'], 'de:kaution');
      expect(vocab['meaning'], 'security deposit');
      final grammar = (lesson['grammar'] as List).first as Map;
      expect(grammar['concept'], 'polite_indirect_question');
      expect(grammar['label'], 'Polite Indirect Question!');
    });
  });

  group('grouping', () {
    test('same word from two lessons merges with both sources', () {
      final groups = groupVocab([
        (
          id: 'de:kaution',
          lemma: 'Kaution',
          article: 'die',
          meaning: 'security deposit',
          sourceContext: 'ctx1',
          lessonId: 1,
          sourceId: 10,
          lessonTitle: 'Short',
        ),
        (
          id: 'de:kaution',
          lemma: 'Kaution',
          article: 'die',
          meaning: 'security deposit',
          sourceContext: 'ctx2',
          lessonId: 2,
          sourceId: 20,
          lessonTitle: 'Long',
        ),
      ]);
      expect(groups.length, 1);
      expect(groups['de:kaution']!.occurrences.length, 2);
    });
  });
}
