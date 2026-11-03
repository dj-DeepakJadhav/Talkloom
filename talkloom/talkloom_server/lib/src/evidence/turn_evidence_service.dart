import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../services/dual_pedagogical_agent_service.dart';
import '../services/semantic_evaluator_service.dart';
import 'recall_projection.dart';

export 'recall_projection.dart';

/// Turns one learner speaking turn into persisted, honest evidence.
///
/// Eligibility rules (all must hold for a target to count):
/// - the lesson and its source belong to the authenticated learner;
/// - the most recent tutor turn did not prompt or model an answer;
/// - the independent evaluator call succeeded with well-formed output;
/// - the evaluator judged the target used, correct, in context and
///   spontaneous, and the tutor had not said the target earlier.
///
/// Mastery needs [masteryTurnThreshold] separate eligible turns.
class TurnEvidenceService {
  final SemanticEvaluator evaluator;

  TurnEvidenceService(this.evaluator);

  /// Loads the lesson only if it and its live source belong to [userId].
  static Future<Lesson?> findOwnedLesson(
    Session session, {
    required String userId,
    required int lessonId,
  }) async {
    final lesson = await Lesson.db.findFirstRow(
      session,
      where: (t) => t.id.equals(lessonId) & t.userId.equals(userId),
    );
    if (lesson == null) return null;
    final source = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(lesson.sourceId) &
          t.userId.equals(userId) &
          t.isArchived.equals(false),
    );
    return source == null ? null : lesson;
  }

  /// Recall bars per target, computed on read from evaluated turns.
  /// No schema change: independent uses are eligible results, lapses are
  /// later incorrect uses. See [projectRecall].
  static Future<Map<String, RecallState>> recall(
    Session session, {
    required String userId,
    required String targetLanguage,
    DateTime? now,
  }) async {
    final rows = await TurnEvaluation.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.targetLanguage.equals(targetLanguage) &
          t.status.equals(TurnEvaluationStatus.evaluated),
      orderBy: (t) => t.createdAt,
      limit: 5000,
    );
    final byId = <String, List<RecallObservation>>{};
    for (final row in rows) {
      for (final r in _decodeList(row.results)) {
        if (r['used'] != true) continue;
        final id = _str(r['itemId']);
        if (id.isEmpty) continue;
        byId.putIfAbsent(id, () => []).add(
          RecallObservation(
            at: row.createdAt,
            independent: r['eligible'] == true,
            lapse: r['correct'] != true,
          ),
        );
      }
    }
    return {
      for (final e in byId.entries) e.key: projectRecall(e.value, now: now),
    };
  }

  /// Source-linked vocabulary and grammar targets of [lesson].
  static List<EvaluationTarget> lessonTargets(Lesson lesson, {int max = 60}) {
    final targets = <String, EvaluationTarget>{};
    for (final item in _decodeList(lesson.vocabulary)) {
      final lemma = _str(item['lemma'] ?? item['phrase'] ?? item['word']);
      if (lemma.isEmpty) continue;
      final itemId = (_str(item['id']).isEmpty ? lemma : _str(item['id']))
          .toLowerCase();
      targets.putIfAbsent(
        itemId,
        () => EvaluationTarget(
          itemId: itemId,
          kind: 'vocabulary',
          form: lemma,
          meaning: _str(item['meaning']),
          sourceContext: _str(item['sourceContext']),
        ),
      );
    }
    for (final item in _decodeList(lesson.grammar)) {
      final concept = _str(item['concept']);
      if (concept.isEmpty) continue;
      final itemId = 'grammar:${concept.toLowerCase()}';
      targets.putIfAbsent(
        itemId,
        () => EvaluationTarget(
          itemId: itemId,
          kind: 'grammar',
          form: concept,
          meaning: _str(item['explanation']),
          sourceContext: _str(item['sourceSentence']),
        ),
      );
    }
    return targets.values.take(max).toList();
  }

  Future<TurnEvaluation> evaluateTurn(
    Session session, {
    required String userId,
    required Lesson lesson,
    required String situation,
    required List<ConversationHistoryEntry> history,
    required String learnerUtterance,
  }) async {
    final targets = lessonTargets(lesson);
    final tutorTurns = history
        .where((t) => t.role == ConversationTurnRole.tutor)
        .toList();
    final lastTutor = tutorTurns.isEmpty ? null : tutorTurns.last;
    final now = DateTime.now().toUtc();

    TurnEvaluation row({
      required String status,
      String? provider,
      String? model,
      String? reason,
      List<Map<String, dynamic>> results = const [],
    }) => TurnEvaluation(
      userId: userId,
      targetLanguage: lesson.targetLanguage,
      lessonId: lesson.id!,
      learnerUtterance: learnerUtterance,
      status: status,
      provider: provider,
      model: model,
      reason: reason,
      results: jsonEncode(results),
      createdAt: now,
    );

    if (lastTutor != null &&
        lastTutor.assistance != ConversationAssistance.none) {
      return TurnEvaluation.db.insertRow(
        session,
        row(status: TurnEvaluationStatus.assisted, reason: 'tutor_assisted'),
      );
    }
    if (targets.isEmpty) {
      return TurnEvaluation.db.insertRow(
        session,
        row(
          status: TurnEvaluationStatus.evaluatorUnavailable,
          reason: 'no_targets',
        ),
      );
    }

    EvaluatorOutcome outcome;
    try {
      outcome = await evaluator.evaluate(
        targetLanguage: lesson.targetLanguage,
        situation: situation,
        recentTutorTurns: [
          for (final t in tutorTurns.reversed.take(6).toList().reversed)
            t.content,
        ],
        learnerUtterance: learnerUtterance,
        targets: targets,
      );
    } catch (_) {
      outcome = const EvaluatorOutcome.failure(failureReason: 'provider_error');
    }
    if (!outcome.succeeded) {
      return TurnEvaluation.db.insertRow(
        session,
        row(
          status: TurnEvaluationStatus.evaluatorUnavailable,
          provider: outcome.provider,
          model: outcome.model,
          reason: outcome.failureReason,
        ),
      );
    }

    final byId = {for (final t in targets) t.itemId: t};
    final results = <Map<String, dynamic>>[];
    final eligibleIds = <String>[];
    for (final j in outcome.judgements!) {
      final target = byId[j.itemId]!;
      final tutorSaidIt = tutorTurns.any(
        (t) => _containsWhole(t.content, target.form),
      );
      final spontaneous = j.used && j.spontaneous && !tutorSaidIt;
      final eligible = j.used && j.correct && j.inContext && spontaneous;
      if (eligible) eligibleIds.add(j.itemId);
      results.add({
        'itemId': j.itemId,
        'kind': target.kind,
        'used': j.used,
        'correct': j.used && j.correct && j.inContext,
        'inContext': j.inContext,
        'spontaneous': spontaneous,
        'eligible': eligible,
      });
    }

    final saved = await TurnEvaluation.db.insertRow(
      session,
      row(
        status: TurnEvaluationStatus.evaluated,
        provider: outcome.provider,
        model: outcome.model,
        results: results,
      ),
    );

    for (final itemId in eligibleIds) {
      await EvidenceEvent.db.insertRow(
        session,
        EvidenceEvent(
          userId: userId,
          targetLanguage: lesson.targetLanguage,
          itemId: itemId,
          activityType: 'speaking_evaluated',
          supportLevel: 'none',
          spontaneous: true,
          correct: true,
          timestamp: now,
        ),
      );
    }
    if (eligibleIds.isNotEmpty) {
      await _promoteMastered(session, userId, lesson.targetLanguage);
    }
    return saved;
  }

  /// Adds vocabulary that reached the threshold to `LearnerState.activeWords`.
  Future<void> _promoteMastered(
    Session session,
    String userId,
    String targetLanguage,
  ) async {
    final summary = await summarize(
      session,
      userId: userId,
      targetLanguage: targetLanguage,
    );
    final mastered = summary
        .where((s) => s.mastered && s.kind == 'vocabulary')
        .map((s) => s.itemId)
        .toSet();
    if (mastered.isEmpty) return;
    final existing = await LearnerState.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
    );
    final now = DateTime.now().toUtc();
    if (existing == null) {
      await LearnerState.db.insertRow(
        session,
        LearnerState(
          userId: userId,
          targetLanguage: targetLanguage,
          recognizedWords: mastered.toList(),
          activeWords: mastered.toList(),
          grammarMastery: '{}',
          updatedAt: now,
        ),
      );
    } else {
      await LearnerState.db.updateRow(
        session,
        existing.copyWith(
          recognizedWords: {...existing.recognizedWords, ...mastered}.toList(),
          activeWords: {...existing.activeWords, ...mastered}.toList(),
          updatedAt: now,
        ),
      );
    }
  }

  /// Per-target evidence for [userId], computed only from evaluated turns.
  static Future<List<WordEvidenceSummary>> summarize(
    Session session, {
    required String userId,
    required String targetLanguage,
  }) async {
    final rows = await TurnEvaluation.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.targetLanguage.equals(targetLanguage) &
          t.status.equals(TurnEvaluationStatus.evaluated),
      orderBy: (t) => t.createdAt,
      limit: 5000,
    );
    final byId = <String, _Tally>{};
    for (final row in rows) {
      for (final r in _decodeList(row.results)) {
        if (r['used'] != true) continue;
        final id = _str(r['itemId']);
        if (id.isEmpty) continue;
        final tally = byId.putIfAbsent(id, () => _Tally(_str(r['kind'])));
        if (r['eligible'] == true) {
          tally.eligible++;
          tally.last = row.createdAt;
        } else if (r['correct'] != true) {
          tally.incorrect++;
        } else {
          tally.ineligible++;
        }
      }
    }
    return [
      for (final e in byId.entries)
        WordEvidenceSummary(
          itemId: e.key,
          kind: e.value.kind,
          eligibleCorrectTurns: e.value.eligible,
          incorrectTurns: e.value.incorrect,
          ineligibleTurns: e.value.ineligible,
          threshold: masteryTurnThreshold,
          mastered: e.value.eligible >= masteryTurnThreshold,
          lastEvidenceAt: e.value.last,
        ),
    ]..sort((a, b) => a.itemId.compareTo(b.itemId));
  }

  static List<Map> _decodeList(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      return decoded is List ? decoded.whereType<Map>().toList() : const [];
    } on FormatException {
      return const [];
    }
  }

  static String _str(Object? value) => value is String ? value.trim() : '';

  static bool _containsWhole(String text, String target) {
    final t = target.trim().toLowerCase();
    if (t.isEmpty) return false;
    const d = r'[^\p{L}\p{N}]';
    return RegExp(
      '(^|$d)${RegExp.escape(t)}(\$|$d)',
      unicode: true,
    ).hasMatch(text.toLowerCase());
  }
}

class _Tally {
  final String kind;
  int eligible = 0;
  int incorrect = 0;
  int ineligible = 0;
  DateTime? last;
  _Tally(this.kind);
}
