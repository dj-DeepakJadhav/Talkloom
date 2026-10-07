import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';

class LearnerStateEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      throw StateError('Sign in to access your learning progress.');
    }
    return authUserId.toString();
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
    final normalizedItemId = _normalizeItemId(targetLanguage, itemId);
    if (normalizedItemId.isEmpty || normalizedItemId.length > 120) {
      throw ArgumentError('Choose a valid vocabulary or grammar item.');
    }
    const allowedActivities = {
      'conversation',
      'flashcard',
      'grammar',
      'mini_game',
      'pronunciation',
      'speaking',
      'vocabulary',
    };
    if (!allowedActivities.contains(activityType)) {
      throw ArgumentError('Unsupported learning activity.');
    }
    if (!await _ownsLearningItem(
      session,
      userId: userId,
      targetLanguage: targetLanguage,
      normalizedItemId: normalizedItemId,
    )) {
      throw ArgumentError('That item is not in your active learning content.');
    }

    // The client currently submits correctness and spontaneity flags without
    // providing a verifiable answer attempt. Preserve attempts for analytics,
    // but never turn client assertions into mastery evidence.
    final verifiedCorrect = false;
    final verifiedSpontaneous = false;

    final event = EvidenceEvent(
      userId: userId,
      targetLanguage: targetLanguage,
      itemId: normalizedItemId,
      activityType: activityType,
      supportLevel: supportLevel,
      spontaneous: verifiedSpontaneous,
      correct: verifiedCorrect,
      timestamp: DateTime.now(),
    );

    final savedEvent = await EvidenceEvent.db.insertRow(session, event);

    return savedEvent;
  }

  String _normalizeItemId(String targetLanguage, String itemId) {
    final item = itemId.trim().toLowerCase();
    final prefix = '${targetLanguage.trim().toLowerCase()}:';
    return item.startsWith(prefix) ? item.substring(prefix.length) : item;
  }

  Future<bool> _ownsLearningItem(
    Session session, {
    required String userId,
    required String targetLanguage,
    required String normalizedItemId,
  }) async {
    final lessons = await Lesson.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: 500,
    );
    for (final lesson in lessons) {
      final source = await Source.db.findFirstRow(
        session,
        where: (t) =>
            t.id.equals(lesson.sourceId) &
            t.userId.equals(userId) &
            t.isArchived.equals(false),
      );
      if (source == null) continue;
      if (_containsItem(lesson.vocabulary, normalizedItemId, const {
            'id',
            'lemma',
            'phrase',
            'word',
          }) ||
          _containsItem(lesson.grammar, normalizedItemId, const {
            'id',
            'concept',
          })) {
        return true;
      }
    }
    return false;
  }

  bool _containsItem(String encoded, String requested, Set<String> keys) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return false;
      return decoded.whereType<Map>().any((item) {
        return keys.any((key) {
          final value = item[key]?.toString().trim().toLowerCase() ?? '';
          return value == requested;
        });
      });
    } on FormatException {
      return false;
    }
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
