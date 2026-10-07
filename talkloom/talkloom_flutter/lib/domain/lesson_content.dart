import 'dart:convert';
import 'package:talkloom_client/talkloom_client.dart';

/// One step in a lesson. The compiler emits these in `Lesson.activities`;
/// previously the client persisted them and then rendered a hardcoded German
/// sentence instead.
sealed class LessonActivity {
  const LessonActivity();

  /// Returns null for entries the client does not recognise, so one unknown
  /// activity type from the model cannot break the whole lesson.
  static LessonActivity? fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) =>
        (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

    return switch (json['type'] as String?) {
      'context_choice' => () {
        final options = strings(json['options']);
        final question = json['question'] as String? ?? '';
        if (options.length < 2 || question.isEmpty) return null;
        final index = (json['correctIndex'] as num?)?.toInt() ?? 0;
        return ContextChoiceActivity(
          question: question,
          options: options,
          correctIndex: index.clamp(0, options.length - 1),
          targets: strings(json['targets']),
        );
      }(),
      'sentence_builder' => () {
        final target = (json['target'] as String? ?? '').trim();
        final tokens = strings(json['scrambledTokens']);
        if (target.isEmpty || tokens.length < 2) return null;
        return SentenceBuilderActivity(target: target, scrambledTokens: tokens);
      }(),
      'speak_response' => () {
        final objective = json['objective'] as String? ?? '';
        if (objective.isEmpty) return null;
        return SpeakResponseActivity(objective: objective);
      }(),
      _ => null,
    };
  }
}

class ContextChoiceActivity extends LessonActivity {
  const ContextChoiceActivity({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.targets = const [],
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final List<String> targets;
}

class SentenceBuilderActivity extends LessonActivity {
  const SentenceBuilderActivity({
    required this.target,
    required this.scrambledTokens,
  });

  final String target;
  final List<String> scrambledTokens;
}

class SpeakResponseActivity extends LessonActivity {
  const SpeakResponseActivity({required this.objective});

  final String objective;
}

/// The plan for the speaking mission that closes a lesson.
@immutable
class ConversationPlan {
  const ConversationPlan({
    required this.role,
    required this.situation,
    required this.hiddenTargets,
    required this.culturalNotes,
  });

  final String role;
  final String situation;

  /// Deliberately not shown to the learner before the conversation — revealing
  /// them defeats the point of eliciting them spontaneously.
  final List<String> hiddenTargets;

  final List<String> culturalNotes;

  static const empty = ConversationPlan(
    role: 'conversation partner',
    situation: 'an everyday conversation',
    hiddenTargets: [],
    culturalNotes: [],
  );
}

/// A compiled lesson, decoded once at the boundary.
@immutable
class LessonContent {
  const LessonContent({
    required this.lessonId,
    this.sourceId,
    required this.objectives,
    required this.vocabulary,
    this.grammar = const [],
    required this.activities,
    required this.conversation,
  });

  final int? lessonId;
  final int? sourceId;
  final List<String> objectives;
  final List<VocabularyItem> vocabulary;
  final List<GrammarRule> grammar;
  final List<LessonActivity> activities;
  final ConversationPlan conversation;

  bool get hasActivities => activities.isNotEmpty;

  static LessonContent fromLesson(Lesson lesson) {
    return LessonContent(
      lessonId: lesson.id,
      sourceId: lesson.sourceId,
      objectives: lesson.objectives,
      vocabulary: _decodeList(
        lesson.vocabulary,
      ).map(VocabularyItem.fromJson).nonNulls.toList(),
      grammar: _decodeList(
        lesson.grammar,
      ).map(GrammarRule.fromJson).nonNulls.toList(),
      activities: _decodeList(
        lesson.activities,
      ).map(LessonActivity.fromJson).nonNulls.toList(),
      conversation: _decodeConversation(lesson.conversationPlan),
    );
  }

  static List<Map<String, dynamic>> _decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } on FormatException {
      return const [];
    }
  }

  static ConversationPlan _decodeConversation(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return ConversationPlan.empty;
      List<String> strings(Object? value) =>
          (value as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList();
      return ConversationPlan(
        role: decoded['role'] as String? ?? ConversationPlan.empty.role,
        situation:
            decoded['situation'] as String? ?? ConversationPlan.empty.situation,
        hiddenTargets: strings(decoded['hiddenTargets']),
        culturalNotes: strings(decoded['culturalNotes']),
      );
    } on FormatException {
      return ConversationPlan.empty;
    }
  }
}

@immutable
class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.lemma,
    required this.meaning,
    this.article = '',
    this.sourceContext = '',
  });

  final String id;
  final String lemma;
  final String meaning;
  final String article;
  final String sourceContext;

  String get display => article.isEmpty ? lemma : '$article $lemma';

  static VocabularyItem? fromJson(Map<String, dynamic> json) {
    final lemma = json['lemma'] as String? ?? '';
    if (lemma.isEmpty) return null;
    return VocabularyItem(
      id: json['id'] as String? ?? lemma.toLowerCase(),
      lemma: lemma,
      meaning: json['meaning'] as String? ?? '',
      article: json['article'] as String? ?? '',
      sourceContext: json['sourceContext'] as String? ?? '',
    );
  }
}

@immutable
class GrammarRule {
  const GrammarRule({
    required this.concept,
    required this.sourceSentence,
    required this.explanation,
  });

  final String concept;
  final String sourceSentence;
  final String explanation;

  static GrammarRule? fromJson(Map<String, dynamic> json) {
    final concept = json['concept'] as String? ?? '';
    if (concept.isEmpty) return null;
    return GrammarRule(
      concept: concept,
      sourceSentence: json['sourceSentence'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
