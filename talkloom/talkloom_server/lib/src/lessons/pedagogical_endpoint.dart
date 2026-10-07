import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';
import '../services/dual_ai_compiler_service.dart';
import '../services/dual_pedagogical_agent_service.dart';

class PedagogicalEndpoint extends Endpoint {
  /// Learner state is per-user data. Identity comes from the authenticated
  /// session, never from a client-supplied parameter.
  @override
  bool get requireLogin => true;

  /// The signed-in user's stable identifier.
  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      throw StateError('Sign in to access learner progress.');
    }
    return authUserId.toString();
  }

  Future<String> stepConversationTurn(
    Session session,
    String targetLanguage,
    String role,
    String situation,
    List<String> hiddenTargets,
    List<String> previousTurns,
    String learnerUtterance,
    double responseLatencySec,
  ) async {
    _requireUserId(session);
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
    final nebiusApiKey = session.serverpod.getPassword('nebiusApiKey') ?? '';
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey') ?? '';
    final nvidiaApiKey = session.serverpod.getPassword('nvidiaApiKey') ?? '';
    final groqApiKey = session.serverpod.getPassword('groqApiKey') ?? '';
    final provider = AiProvider.fromSetting(
      session.serverpod.getPassword('aiProvider'),
    );

    final agent = DualPedagogicalAgentService(
      provider: provider,
      geminiApiKey: geminiApiKey,
      nebiusApiKey: nebiusApiKey,
      nvidiaApiKey: nvidiaApiKey,
      groqApiKey: groqApiKey,
    );

    final telemetry = await agent.stepConversation(
      targetLanguage: targetLanguage,
      role: role,
      situation: situation,
      hiddenTargets: hiddenTargets,
      previousTurns: previousTurns,
      learnerUtterance: learnerUtterance,
      responseLatencySec: responseLatencySec,
    );

    // Word spotting is not semantic assessment. Until an evaluator checks the
    // learner's intended meaning and context, this endpoint never writes mastery.

    return jsonEncode(telemetry.toJson());
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
}
