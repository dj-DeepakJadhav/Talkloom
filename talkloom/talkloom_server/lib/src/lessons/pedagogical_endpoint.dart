import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/dual_pedagogical_agent_service.dart';
import '../services/semantic_evaluator_service.dart';
import '../usage/ai_quota_service.dart';
import '../evidence/turn_evidence_service.dart';

/// Builds the independent evaluator for a session. Tests replace this with a
/// fake so no live provider is called.
typedef SemanticEvaluatorFactory = SemanticEvaluator Function(Session session);

class PedagogicalEndpoint extends Endpoint {
  /// Learner state is per-user data. Identity comes from the authenticated
  /// session, never from a client-supplied parameter.
  @override
  bool get requireLogin => true;

  /// The signed-in user's stable identifier.
  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.userIdentifier;
    if (authUserId == null) {
      throw StateError('Sign in to see your learning progress.');
    }
    return authUserId.toString();
  }

  /// Overridable in tests; defaults to the configured provider.
  static SemanticEvaluatorFactory evaluatorFactory = _defaultEvaluator;

  static SemanticEvaluator _defaultEvaluator(Session session) {
    final metaKey = session.serverpod.getPassword('metaApiKey') ?? '';
    return ProviderSemanticEvaluator(metaApiKey: metaKey);
  }

  /// Runs one tutor turn. When [lessonId] names a lesson the learner owns, an
  /// independent evaluator judges the learner utterance against that lesson's
  /// targets and the result is persisted; client flags are never trusted.
  Future<String> stepConversationTurn(
    Session session,
    String targetLanguage,
    String role,
    String situation,
    List<String> hiddenTargets,
    List<String> previousTurns,
    String learnerUtterance,
    double responseLatencySec, {
    int? lessonId,
  }) async {
    final userId = _requireUserId(session);
    Lesson? lesson;
    if (lessonId != null) {
      lesson = await TurnEvidenceService.findOwnedLesson(
        session,
        userId: userId,
        lessonId: lessonId,
      );
      if (lesson == null) {
        throw ArgumentError('That lesson is not in your learning content.');
      }
    }
    if (learnerUtterance.trim().isEmpty || learnerUtterance.length > 4000) {
      throw ArgumentError(
        'A conversation turn must contain 1 to 4,000 characters.',
      );
    }
    if (hiddenTargets.length > 100 ||
        previousTurns.length > 60 ||
        previousTurns.any((turn) => turn.length > 5000)) {
      throw ArgumentError(
        'The conversation contains too much history or too many targets.',
      );
    }
    // Quota burns here, where the paid model call starts — never for
    // rejected or unowned requests above.
    await AiQuotaService.consume(session, 'turn');
    final metaApiKey = session.serverpod.getPassword('metaApiKey') ?? '';

    final agent = DualPedagogicalAgentService(metaApiKey: metaApiKey);

    final telemetry = await agent.stepConversation(
      targetLanguage: targetLanguage,
      role: role,
      situation: situation,
      hiddenTargets: hiddenTargets,
      previousTurns: previousTurns,
      learnerUtterance: learnerUtterance,
      responseLatencySec: responseLatencySec,
    );

    // Word spotting in the telemetry is never evidence. Only the independent
    // evaluator below can produce eligible evidence, and only for owned lessons.
    final json = telemetry.toJson();
    if (lesson != null) {
      final evaluation = await TurnEvidenceService(evaluatorFactory(session))
          .evaluateTurn(
            session,
            userId: userId,
            lesson: lesson,
            situation: situation,
            history: ConversationHistoryEntry.parseAll(previousTurns),
            learnerUtterance: learnerUtterance,
          );
      json['evidenceEligible'] =
          evaluation.status == TurnEvaluationStatus.evaluated &&
          evaluation.results.contains('"eligible":true');
      json['evaluation'] = {
        'id': evaluation.id,
        'status': evaluation.status,
        'provider': evaluation.provider,
        'model': evaluation.model,
        'reason': evaluation.reason,
        'results': jsonDecode(evaluation.results),
      };
    }
    return jsonEncode(json);
  }

  Future<LearnerState?> getLearnerState(
    Session session,
    String targetLanguage,
  ) async {
    final userId = _requireUserId(session);
    return await LearnerState.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
    );
  }

  Future<List<EvidenceEvent>> getEvidenceHistory(
    Session session,
    String targetLanguage, {
    int limit = 100,
  }) async {
    final userId = _requireUserId(session);
    return await EvidenceEvent.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.timestamp.desc(),
      limit: limit.clamp(1, 500),
    );
  }

  /// The learner's server-verified per-target evidence. Owner-scoped.
  Future<List<WordEvidenceSummary>> getWordEvidenceSummary(
    Session session,
    String targetLanguage,
  ) async {
    final userId = _requireUserId(session);
    return TurnEvidenceService.summarize(
      session,
      userId: userId,
      targetLanguage: targetLanguage,
    );
  }

  /// Recall bars per target (New/Fragile/Growing/Steady), computed on read
  /// from evaluated turns. No stored state, no migration.
  Future<String> getWordRecall(Session session, String targetLanguage) async {
    final userId = _requireUserId(session);
    final states = await TurnEvidenceService.recall(
      session,
      userId: userId,
      targetLanguage: targetLanguage,
    );
    return jsonEncode([
      for (final e in states.entries)
        {
          'itemId': e.key,
          'bars': e.value.bars,
          'label': e.value.label,
          'explanation': e.value.explanation,
          'dueAt': e.value.dueAt?.toIso8601String(),
          'independentUses': e.value.independentUses,
        },
    ]);
  }
}
