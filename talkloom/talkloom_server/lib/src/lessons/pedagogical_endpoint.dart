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
  bool get requireLogin => false;

  /// The signed-in user's stable identifier, with graceful fallback for guests.
  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      return 'guest_learner';
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
    final userId = _requireUserId(session);
    final nebiusApiKey = session.serverpod.getPassword('nebiusApiKey') ?? '';
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey') ?? '';
    final nvidiaApiKey = session.serverpod.getPassword('nvidiaApiKey') ?? '';
    final groqApiKey = session.serverpod.getPassword('groqApiKey') ?? '';
    final aiProviderSetting =
        session.serverpod.getPassword('aiProvider')?.toLowerCase() ?? 'nvidia';

    final provider = aiProviderSetting == 'groq'
        ? AiProvider.groq
        : (aiProviderSetting == 'nvidia'
            ? AiProvider.nvidia
            : (aiProviderSetting == 'nebius'
                ? AiProvider.nebius
                : AiProvider.nvidia));

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

    // If target was detected, record an EvidenceEvent and update LearnerState
    if (telemetry.targetProducedSpontaneously &&
        telemetry.detectedTarget != null) {
      final itemKey =
          '${targetLanguage.toLowerCase()}:${telemetry.detectedTarget!.toLowerCase()}';

      // Insert Evidence
      final event = EvidenceEvent(
        userId: userId,
        targetLanguage: targetLanguage,
        itemId: itemKey,
        activityType: 'live_speech',
        supportLevel: 'none',
        spontaneous: true,
        correct: true,
        timestamp: DateTime.now(),
      );
      await EvidenceEvent.db.insertRow(session, event);

      // Update or create LearnerState
      final existingState = await LearnerState.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      );

      if (existingState != null) {
        final activeList = List<String>.from(existingState.activeWords);
        if (!activeList.contains(itemKey)) {
          activeList.add(itemKey);
        }
        existingState.activeWords = activeList;
        existingState.updatedAt = DateTime.now();
        await LearnerState.db.updateRow(session, existingState);
      } else {
        final newState = LearnerState(
          userId: userId,
          targetLanguage: targetLanguage,
          recognizedWords: [itemKey],
          activeWords: [itemKey],
          grammarMastery: jsonEncode({
            'polite_indirect_question': 'in_progress',
          }),
          updatedAt: DateTime.now(),
        );
        await LearnerState.db.insertRow(session, newState);
      }
    }

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
