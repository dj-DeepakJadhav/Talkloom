import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';

class LearnerStateEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    return authUserId?.toString() ?? 'guest_learner';
  }

  /// Retrieves the current vocabulary mastery state (recognized vs active/spoken words)
  /// for the authenticated user and target language.
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

  /// Records an EvidenceEvent (e.g. mini-game completion or spoken target word)
  /// and updates the user's LearnerState (recognized vs active words).
  Future<EvidenceEvent> recordEvidenceEvent(
    Session session, {
    required String targetLanguage,
    required String itemId,
    required String activityType,
    required String supportLevel,
    required bool spontaneous,
    required bool correct,
  }) async {
    final userId = _requireUserId(session);

    final event = EvidenceEvent(
      userId: userId,
      targetLanguage: targetLanguage,
      itemId: itemId,
      activityType: activityType,
      supportLevel: supportLevel,
      spontaneous: spontaneous,
      correct: correct,
      timestamp: DateTime.now(),
    );

    final savedEvent = await EvidenceEvent.db.insertRow(session, event);

    if (correct) {
      final itemKey = itemId.contains(':')
          ? itemId.toLowerCase()
          : '${targetLanguage.toLowerCase()}:${itemId.toLowerCase()}';

      final existingState = await LearnerState.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      );

      if (existingState != null) {
        final recList = List<String>.from(existingState.recognizedWords);
        final actList = List<String>.from(existingState.activeWords);

        if (!recList.contains(itemKey)) {
          recList.add(itemKey);
        }
        if (spontaneous && !actList.contains(itemKey)) {
          actList.add(itemKey);
        }

        existingState.recognizedWords = recList;
        existingState.activeWords = actList;
        existingState.updatedAt = DateTime.now();
        await LearnerState.db.updateRow(session, existingState);
      } else {
        final newState = LearnerState(
          userId: userId,
          targetLanguage: targetLanguage,
          recognizedWords: [itemKey],
          activeWords: spontaneous ? [itemKey] : [],
          grammarMastery: jsonEncode({}),
          updatedAt: DateTime.now(),
        );
        await LearnerState.db.insertRow(session, newState);
      }
    }

    return savedEvent;
  }

  /// Fetches historical evidence events for tracking learner progress over time.
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
