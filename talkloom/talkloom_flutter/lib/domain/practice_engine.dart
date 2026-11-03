import 'dart:math';
import 'package:flutter/foundation.dart';
import 'lesson_content.dart';

/// The game a practice session is built around.
enum PracticeMode {
  mix('Mixed practice'),
  match('Word match'),
  listen('Listening'),
  gap('Fill the gap'),
  sentence('Build sentences');

  const PracticeMode(this.label);
  final String label;
}

/// One step of a session. Built from the learner's own vocabulary, grammar and
/// source sentences, so no step needs an AI call and none is invented.
sealed class PracticeExercise {
  const PracticeExercise();
}

/// A new word shown before it is asked about.
class WordIntroExercise extends PracticeExercise {
  const WordIntroExercise(this.word);
  final VocabularyItem word;
}

enum ChoiceKind { meaning, reverse, listen, gap, context }

/// Pick one answer. [options] is shuffled; [correctIndex] points into it.
class ChoiceExercise extends PracticeExercise {
  const ChoiceExercise({
    required this.kind,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.audioText,
    this.sentence,
    this.hint,
    this.wordId,
  });

  final ChoiceKind kind;
  final String prompt;

  /// Text to speak. For [ChoiceKind.listen] it is the question itself.
  final String? audioText;

  /// The sentence with a blank, for [ChoiceKind.gap].
  final String? sentence;
  final String? hint;
  final List<String> options;
  final int correctIndex;

  /// The word this tests, to report which words were practised.
  final String? wordId;

  String get answer => options[correctIndex];
}

/// Match each German word to its meaning.
class MatchExercise extends PracticeExercise {
  const MatchExercise(this.pairs);
  final List<({String left, String right})> pairs;
}

/// Put the words of a real sentence from the source into order.
class SentenceExercise extends PracticeExercise {
  const SentenceExercise({
    required this.target,
    required this.tokens,
    this.hint,
  });

  final String target;
  final List<String> tokens;
  final String? hint;
}

@immutable
class PracticeSet {
  const PracticeSet({required this.exercises, required this.words});
  final List<PracticeExercise> exercises;

  /// Words the session touches, for the summary.
  final List<VocabularyItem> words;
}

/// Turns vocabulary, grammar and compiled activities into a session.
///
/// Pass [vocabulary] with the words that most need practice first; the builder
/// takes words from the front when there are more than fit.
class PracticeBuilder {
  PracticeBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _maxOptions = 4;
  static const _matchSize = 4;

  PracticeSet build({
    required List<VocabularyItem> vocabulary,
    List<GrammarRule> grammar = const [],
    List<LessonActivity> activities = const [],
    PracticeMode mode = PracticeMode.mix,
    int length = 10,
    bool intro = false,
    bool canSpeak = true,
  }) {
    final words = _usable(vocabulary);
    final exercises = <PracticeExercise>[];

    switch (mode) {
      case PracticeMode.match:
        exercises.addAll(_matchRounds(words, rounds: max(1, length ~/ 4)));
      case PracticeMode.listen:
        for (final word in _take(words, length)) {
          exercises.add(
            canSpeak ? _listen(word, words) : _meaning(word, words),
          );
        }
      case PracticeMode.gap:
        for (final word in _take(words, length)) {
          exercises.add(_gap(word, words) ?? _meaning(word, words));
        }
      case PracticeMode.sentence:
        exercises.addAll(_sentences(words, grammar, length));
      case PracticeMode.mix:
        exercises.addAll(
          _mix(
            words,
            grammar,
            length: length,
            intro: intro,
            canSpeak: canSpeak,
          ),
        );
    }

    if (mode == PracticeMode.mix || intro) {
      exercises.addAll(_fromActivities(activities));
    }

    return PracticeSet(exercises: exercises, words: _take(words, length));
  }

  List<PracticeExercise> _mix(
    List<VocabularyItem> words,
    List<GrammarRule> grammar, {
    required int length,
    required bool intro,
    required bool canSpeak,
  }) {
    final out = <PracticeExercise>[];
    final focus = _take(words, length);
    var i = 0;

    if (intro) {
      // Each new word is shown and asked about straight away, then the rest
      // of the session mixes the formats.
      for (final word in focus.take(5)) {
        out
          ..add(WordIntroExercise(word))
          ..add(_meaning(word, words));
      }
    }

    final rest = <PracticeExercise>[];
    for (final word in focus) {
      final form = i++ % 4;
      rest.add(switch (form) {
        0 => _reverse(word, words),
        1 => canSpeak ? _listen(word, words) : _meaning(word, words),
        2 => _gap(word, words) ?? _meaning(word, words),
        _ => _meaning(word, words),
      });
    }
    rest.shuffle(_random);
    out.addAll(rest);

    if (words.length >= 3) out.insert(min(out.length, 4), _match(words));
    out.addAll(_sentences(words, grammar, 2));
    return out;
  }

  List<MatchExercise> _matchRounds(
    List<VocabularyItem> words, {
    int rounds = 2,
  }) {
    if (words.length < 3) return const [];
    final shuffled = [...words]..shuffle(_random);
    final out = <MatchExercise>[];
    for (var r = 0; r < rounds; r++) {
      final start = (r * _matchSize) % shuffled.length;
      final group = <VocabularyItem>[
        for (var k = 0; k < min(_matchSize, shuffled.length); k++)
          shuffled[(start + k) % shuffled.length],
      ];
      out.add(_match(group));
    }
    return out;
  }

  MatchExercise _match(List<VocabularyItem> words) {
    final picked = _take(_shuffled(words), _matchSize);
    return MatchExercise([
      for (final w in picked) (left: w.display, right: w.meaning),
    ]);
  }

  ChoiceExercise _meaning(VocabularyItem word, List<VocabularyItem> pool) {
    final (options, index) = _options(
      correct: word.meaning,
      distractors: [
        for (final w in pool)
          if (w.id != word.id && w.meaning != word.meaning) w.meaning,
      ],
    );
    return ChoiceExercise(
      kind: ChoiceKind.meaning,
      prompt: 'What does this mean?',
      sentence: word.display,
      audioText: word.display,
      options: options,
      correctIndex: index,
      wordId: word.id,
    );
  }

  ChoiceExercise _reverse(VocabularyItem word, List<VocabularyItem> pool) {
    final (options, index) = _options(
      correct: word.display,
      distractors: [
        for (final w in pool)
          if (w.id != word.id && w.display != word.display) w.display,
      ],
    );
    return ChoiceExercise(
      kind: ChoiceKind.reverse,
      prompt: 'How do you say this in German?',
      sentence: word.meaning,
      options: options,
      correctIndex: index,
      wordId: word.id,
    );
  }

  ChoiceExercise _listen(VocabularyItem word, List<VocabularyItem> pool) {
    final (options, index) = _options(
      correct: word.display,
      distractors: [
        for (final w in pool)
          if (w.id != word.id && w.display != word.display) w.display,
      ],
    );
    return ChoiceExercise(
      kind: ChoiceKind.listen,
      prompt: 'Tap what you hear',
      audioText: word.display,
      options: options,
      correctIndex: index,
      wordId: word.id,
    );
  }

  /// A cloze from the word's own sentence in the source, or null when that
  /// sentence does not contain the word.
  ChoiceExercise? _gap(VocabularyItem word, List<VocabularyItem> pool) {
    final blanked = _blank(word.sourceContext, word.lemma);
    if (blanked == null) return null;
    final (options, index) = _options(
      correct: word.lemma,
      distractors: [
        for (final w in pool)
          if (w.id != word.id &&
              w.lemma.toLowerCase() != word.lemma.toLowerCase())
            w.lemma,
      ],
    );
    return ChoiceExercise(
      kind: ChoiceKind.gap,
      prompt: 'Fill in the missing word',
      sentence: blanked,
      hint: word.meaning.isEmpty ? null : '“${word.meaning}”',
      options: options,
      correctIndex: index,
      wordId: word.id,
    );
  }

  /// Replaces the first whole-word occurrence of [lemma] with a blank.
  static String? _blank(String sentence, String lemma) {
    if (sentence.trim().isEmpty || lemma.trim().isEmpty) return null;
    final match = RegExp(
      '(?<![\\p{L}])${RegExp.escape(lemma)}(?![\\p{L}])',
      caseSensitive: false,
      unicode: true,
    ).firstMatch(sentence);
    if (match == null) return null;
    return sentence.replaceRange(match.start, match.end, '_____').trim();
  }

  List<SentenceExercise> _sentences(
    List<VocabularyItem> words,
    List<GrammarRule> grammar,
    int count,
  ) {
    final candidates = <({String sentence, String? hint})>[
      for (final g in grammar)
        if (g.sourceSentence.trim().isNotEmpty)
          (
            sentence: g.sourceSentence.trim(),
            hint: g.concept.isEmpty ? null : g.concept,
          ),
      for (final w in words)
        if (w.sourceContext.trim().isNotEmpty)
          (
            sentence: w.sourceContext.trim(),
            hint: w.meaning.isEmpty ? null : w.meaning,
          ),
    ];
    final seen = <String>{};
    final out = <SentenceExercise>[];
    candidates.shuffle(_random);
    for (final c in candidates) {
      if (out.length >= count) break;
      final tokens = c.sentence.split(RegExp(r'\s+'));
      if (tokens.length < 3 || tokens.length > 12) continue;
      if (!seen.add(c.sentence.toLowerCase())) continue;
      out.add(
        SentenceExercise(
          target: tokens.join(' '),
          tokens: _scramble(tokens),
          hint: c.hint,
        ),
      );
    }
    return out;
  }

  /// Compiled activities from the lesson, kept so the AI-written context
  /// questions and sentence puzzles still appear in the session.
  List<PracticeExercise> _fromActivities(List<LessonActivity> activities) {
    final out = <PracticeExercise>[];
    for (final activity in activities) {
      switch (activity) {
        case ContextChoiceActivity():
          out.add(
            ChoiceExercise(
              kind: ChoiceKind.context,
              prompt: activity.question,
              options: activity.options,
              correctIndex: activity.correctIndex,
            ),
          );
        case SentenceBuilderActivity():
          out.add(
            SentenceExercise(
              target: activity.target,
              tokens: activity.scrambledTokens,
            ),
          );
        case SpeakResponseActivity():
          break; // Speaking is the closing mission, not a tap exercise.
      }
    }
    return out;
  }

  List<VocabularyItem> _usable(List<VocabularyItem> input) {
    final seen = <String>{};
    return [
      for (final w in input)
        if (w.lemma.trim().isNotEmpty &&
            w.meaning.trim().isNotEmpty &&
            seen.add(w.display.toLowerCase()))
          w,
    ];
  }

  List<T> _take<T>(List<T> items, int n) => items.take(n).toList();

  List<T> _shuffled<T>(List<T> items) => [...items]..shuffle(_random);

  (List<String>, int) _options({
    required String correct,
    required List<String> distractors,
  }) {
    final unique = <String>{...distractors}..remove(correct);
    final picked = (unique.toList()..shuffle(_random)).take(_maxOptions - 1);
    final options = [correct, ...picked]..shuffle(_random);
    return (options, options.indexOf(correct));
  }

  List<String> _scramble(List<String> tokens) {
    final out = [...tokens];
    for (var attempt = 0; attempt < 6; attempt++) {
      out.shuffle(_random);
      if (!listEquals(out, tokens)) break;
    }
    return out;
  }
}
