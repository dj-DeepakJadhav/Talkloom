import 'package:talkloom_client/talkloom_client.dart';
import '../../core/platform/web_voice_service.dart';
import '../../domain/lesson_content.dart';
import '../../domain/practice_engine.dart';
import '../../domain/word_tracking_analytics.dart';
import 'practice_session_screen.dart';

/// Builds practice sessions from what the learner has already imported. No
/// session calls an AI: the words, sentences and grammar are the ones the
/// lesson compiler stored.
abstract final class PracticeLauncher {
  /// Words that were seen again but never practised come first, then new
  /// words, then those already practised.
  static int _priority(WordTrackingStatus status) => switch (status) {
    WordTrackingStatus.repeated => 0,
    WordTrackingStatus.newWord => 1,
    WordTrackingStatus.practiced => 2,
    WordTrackingStatus.mastered => 3,
  };

  static List<VocabularyItem> _ordered(
    LessonContent lesson,
    WordTrackingAnalytics analytics,
  ) {
    final words = [...lesson.vocabulary];
    words.sort(
      (a, b) => _priority(
        analytics.getStatus(a, sourceId: lesson.sourceId),
      ).compareTo(_priority(analytics.getStatus(b, sourceId: lesson.sourceId))),
    );
    return words;
  }

  /// Practice across every link the learner has imported.
  static PracticeSessionArgs? forAllWords(
    List<Lesson> lessons,
    WordTrackingAnalytics analytics, {
    PracticeMode mode = PracticeMode.mix,
  }) {
    final contents = lessons.map(LessonContent.fromLesson).toList();
    final words = [for (final c in contents) ..._ordered(c, analytics)];
    final grammar = [for (final c in contents) ...c.grammar];
    if (words.isEmpty) return null;
    return _args(
      title: mode == PracticeMode.mix ? 'All my words' : mode.label,
      words: words,
      grammar: grammar,
      mode: mode,
      length: 10,
    );
  }

  /// Practice limited to one link's own words and grammar.
  static PracticeSessionArgs? forLesson(
    LessonContent lesson,
    WordTrackingAnalytics analytics, {
    required String title,
    PracticeMode mode = PracticeMode.mix,
  }) {
    final words = _ordered(lesson, analytics);
    if (words.isEmpty && lesson.activities.isEmpty) return null;
    return _args(
      title: title,
      words: words,
      grammar: lesson.grammar,
      activities: lesson.activities,
      mode: mode,
      length: 10,
    );
  }

  /// The guided lesson for a new link: each word is introduced, asked about,
  /// then mixed practice, and the session closes with the speaking mission.
  static PracticeSessionArgs? lessonFlow(
    LessonContent lesson,
    WordTrackingAnalytics analytics, {
    required String title,
    required String speakRoute,
  }) {
    final words = _ordered(lesson, analytics);
    if (words.isEmpty && lesson.activities.isEmpty) return null;
    return _args(
      title: title,
      words: words,
      grammar: lesson.grammar,
      activities: lesson.activities,
      length: 8,
      intro: true,
      finishLabel: 'Start speaking',
      finishRoute: speakRoute,
    );
  }

  static PracticeSessionArgs? _args({
    required String title,
    required List<VocabularyItem> words,
    required List<GrammarRule> grammar,
    List<LessonActivity> activities = const [],
    PracticeMode mode = PracticeMode.mix,
    int length = 10,
    bool intro = false,
    String? finishLabel,
    String? finishRoute,
  }) {
    final set = PracticeBuilder().build(
      vocabulary: words,
      grammar: grammar,
      activities: activities,
      mode: mode,
      length: length,
      intro: intro,
      canSpeak: WebVoiceService.instance.canSpeak,
    );
    if (set.exercises.isEmpty) return null;
    return PracticeSessionArgs(
      title: title,
      set: set,
      finishLabel: finishLabel,
      finishRoute: finishRoute,
    );
  }
}
