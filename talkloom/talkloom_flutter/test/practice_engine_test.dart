import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/domain/practice_engine.dart';

VocabularyItem _w(String lemma, String meaning, {String ctx = ''}) =>
    VocabularyItem(
      id: lemma.toLowerCase(),
      lemma: lemma,
      meaning: meaning,
      sourceContext: ctx,
    );

final _words = [
  _w('Brot', 'bread', ctx: 'Ich kaufe frisches Brot heute'),
  _w('Haus', 'house', ctx: 'Das Haus ist sehr groß'),
  _w('Wasser', 'water'),
  _w('Hund', 'dog'),
  _w('Katze', 'cat'),
];

PracticeBuilder _builder() => PracticeBuilder(random: Random(1));

void main() {
  group('PracticeBuilder', () {
    test('every choice has its correct answer among distinct options', () {
      final set = _builder().build(vocabulary: _words, length: 5);
      final choices = set.exercises.whereType<ChoiceExercise>().toList();
      expect(choices, isNotEmpty);
      for (final c in choices) {
        expect(c.options.toSet().length, c.options.length);
        expect(c.options[c.correctIndex], c.answer);
      }
    });

    test('a meaning question never offers the right meaning twice', () {
      final set = _builder().build(
        vocabulary: _words,
        mode: PracticeMode.listen,
        length: 5,
      );
      for (final c in set.exercises.whereType<ChoiceExercise>()) {
        expect(c.options.where((o) => o == c.answer), hasLength(1));
      }
    });

    test('gap blanks the word in its own source sentence', () {
      final set = _builder().build(
        vocabulary: [_words[0], ..._words.skip(2)],
        mode: PracticeMode.gap,
        length: 1,
      );
      final gap = set.exercises.single as ChoiceExercise;
      expect(gap.kind, ChoiceKind.gap);
      expect(gap.sentence, 'Ich kaufe frisches _____ heute');
      expect(gap.answer, 'Brot');
    });

    test('gap only blanks whole words', () {
      final set = _builder().build(
        vocabulary: [
          _w('Hand', 'hand', ctx: 'Die Handtasche ist neu'),
          ..._words,
        ],
        mode: PracticeMode.gap,
        length: 1,
      );
      // No whole-word match, so it falls back to a meaning question.
      expect((set.exercises.single as ChoiceExercise).kind, ChoiceKind.meaning);
    });

    test('words without a meaning are never practised', () {
      final set = _builder().build(
        vocabulary: [_w('Leer', ''), ..._words],
        length: 10,
      );
      expect(set.words.map((w) => w.lemma), isNot(contains('Leer')));
    });

    test('match pairs each word with its own meaning', () {
      final set = _builder().build(
        vocabulary: _words,
        mode: PracticeMode.match,
        length: 4,
      );
      final match = set.exercises.whereType<MatchExercise>().first;
      final meanings = {for (final w in _words) w.display: w.meaning};
      for (final pair in match.pairs) {
        expect(meanings[pair.left], pair.right);
      }
    });

    test('sentence tokens are a shuffle of the real sentence', () {
      final set = _builder().build(
        vocabulary: _words,
        grammar: const [
          GrammarRule(
            concept: 'Word order',
            sourceSentence: 'Ich gehe heute nach Hause',
            explanation: '',
          ),
        ],
        mode: PracticeMode.sentence,
        length: 5,
      );
      final sentences = set.exercises.whereType<SentenceExercise>();
      expect(sentences, isNotEmpty);
      for (final s in sentences) {
        expect(s.tokens.toList()..sort(), s.target.split(' ')..sort());
        expect(s.tokens.join(' '), isNot(s.target));
      }
    });

    test('intro mode shows each new word and asks about it straight away', () {
      final set = _builder().build(
        vocabulary: _words,
        intro: true,
        length: 3,
      );
      expect(set.exercises[0], isA<WordIntroExercise>());
      expect(set.exercises[1], isA<ChoiceExercise>());
      expect(
        (set.exercises[1] as ChoiceExercise).wordId,
        (set.exercises[0] as WordIntroExercise).word.id,
      );
    });

    test('without speech no listening question is built', () {
      final set = _builder().build(
        vocabulary: _words,
        mode: PracticeMode.listen,
        canSpeak: false,
        length: 5,
      );
      expect(
        set.exercises.whereType<ChoiceExercise>().map((c) => c.kind),
        isNot(contains(ChoiceKind.listen)),
      );
    });

    test('compiled activities are kept, speaking is left for the mission', () {
      final set = _builder().build(
        vocabulary: _words,
        activities: const [
          ContextChoiceActivity(
            question: 'Was kauft er?',
            options: ['Brot', 'Haus'],
            correctIndex: 0,
          ),
          SpeakResponseActivity(objective: 'Sag hallo'),
        ],
        length: 2,
      );
      expect(
        set.exercises.whereType<ChoiceExercise>().any(
          (c) => c.kind == ChoiceKind.context,
        ),
        isTrue,
      );
    });

    test('a single word still yields a session', () {
      final set = _builder().build(vocabulary: [_words.first], length: 5);
      expect(set.exercises, isNotEmpty);
    });
  });
}
