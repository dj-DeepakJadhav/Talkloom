import 'dart:async';
import 'dart:convert';
import 'package:talkloom_client/talkloom_client.dart';
import '../core/failure.dart';
import '../domain/learning_session.dart';

/// Result of one conversation turn, decoded from the agent's telemetry.
///
/// The endpoint still returns a JSON string; decoding is contained here so no
/// widget ever calls `jsonDecode`.
class ConversationTurn {
  const ConversationTurn({
    required this.reply,
    required this.mission,
    required this.tactic,
    required this.cognitiveLoad,
    required this.latencySec,
    required this.producedSpontaneously,
    this.detectedTarget,
  });

  final String reply;
  final String mission;
  final String tactic;
  final String cognitiveLoad;
  final double latencySec;
  final bool producedSpontaneously;
  final String? detectedTarget;

  static ConversationTurn fromJson(
    Map<String, dynamic> json,
    double fallbackLatency,
  ) {
    return ConversationTurn(
      reply: json['reply'] as String? ?? '',
      mission: json['activeMission'] as String? ?? '',
      tactic: json['activeTactic'] as String? ?? 'Listening',
      cognitiveLoad: json['cognitiveLoad'] as String? ?? 'Normal',
      latencySec:
          (json['estimatedLatencySec'] as num?)?.toDouble() ?? fallbackLatency,
      producedSpontaneously:
          json['targetProducedSpontaneously'] as bool? ?? false,
      detectedTarget: json['detectedTarget'] as String?,
    );
  }
}

/// The only place the app talks to the Serverpod client.
///
/// Widgets depend on this, not on generated endpoints, so the transport can
/// change without touching the UI.
class LessonRepository {
  LessonRepository(this._client);

  final Client _client;

  static const _compileTimeout = Duration(seconds: 90);
  static const _turnTimeout = Duration(seconds: 45);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw Failure.from(error);
    }
  }

  Future<Lesson> compileFromText({
    required LearningSession session,
    required String title,
    required String text,
  }) {
    return _guard(
      () => _client.ingestion
          .processSourceAndCompile(
            'text',
            title,
            session.target.code,
            session.support.code,
            session.level.code,
            null,
            text,
          )
          .timeout(_compileTimeout),
    );
  }

  Future<Lesson> compileFromMedia({
    required LearningSession session,
    required String title,
    required String base64Content,
    String type = 'document',
  }) {
    return _guard(
      () => _client.ingestion
          .processSourceAndCompile(
            type,
            title,
            session.target.code,
            session.support.code,
            session.level.code,
            null,
            base64Content,
          )
          .timeout(_compileTimeout),
    );
  }

  Future<Lesson> compileFromUrl({
    required LearningSession session,
    required String title,
    required String url,
  }) {
    return _guard(
      () => _client.ingestion
          .processSourceAndCompile(
            'url',
            title,
            session.target.code,
            session.support.code,
            session.level.code,
            url,
            null,
          )
          .timeout(_compileTimeout),
    );
  }

  Future<List<Source>> listSources(LearningSession session, {int limit = 30}) async {
    try {
      return await _client.ingestion.listSources(
        session.target.code,
        limit: limit,
        offset: 0,
      );
    } catch (_) {
      return const [];
    }
  }

  Future<Lesson?> lessonForSource(int sourceId) {
    return _guard(() => _client.ingestion.getLessonBySourceId(sourceId));
  }

  Future<LearnerState?> learnerState(LearningSession session) async {
    try {
      return await _client.pedagogical.getLearnerState(session.target.code);
    } catch (_) {
      return null;
    }
  }

  Future<ConversationTurn> speak({
    required LearningSession session,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String utterance,
    required double latencySec,
  }) {
    return _guard(() async {
      final raw = await _client.pedagogical
          .stepConversationTurn(
            session.target.code,
            role,
            situation,
            hiddenTargets,
            previousTurns,
            utterance,
            latencySec,
          )
          .timeout(_turnTimeout);

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const Failure('The tutor sent back an unreadable response.');
      }
      return ConversationTurn.fromJson(decoded, latencySec);
    });
  }
}
