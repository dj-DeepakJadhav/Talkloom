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
    this.responseMode = 'unknown',
    this.evidenceEligible = false,
    this.detectedTarget,
  });

  final String reply;
  final String mission;
  final String tactic;
  final String cognitiveLoad;
  final double latencySec;
  final bool producedSpontaneously;
  final String responseMode;
  final bool evidenceEligible;
  bool get isTemplateFallback => responseMode == 'template_fallback';
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
      responseMode: json['responseMode'] as String? ?? 'unknown',
      evidenceEligible: json['evidenceEligible'] as bool? ?? false,
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

  Future<T> _guard<T>(
    Future<T> Function() action, {
    String? serverErrorMessage,
  }) async {
    try {
      return await action();
    } catch (error) {
      if (error is ServerpodClientInternalServerError &&
          serverErrorMessage != null) {
        throw Failure(serverErrorMessage, cause: error);
      }
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
    void Function(String)? onProgress,
  }) {
    return _guard(
      () async {
        final startedAt = DateTime.now().toUtc().subtract(
          const Duration(seconds: 2),
        );
        var polling = false;
        var active = true;
        final completion = Completer<Lesson>();
        Future<Map<String, dynamic>?> status() async {
          if (polling) return null;
          polling = true;
          try {
            final raw = await _client.ingestion
                .getImportStatus(url, session.target.code, startedAt)
                .timeout(const Duration(seconds: 5));
            final data = jsonDecode(raw) as Map<String, dynamic>;
            if (active) onProgress?.call(data['stage'] as String);
            if (active && !completion.isCompleted && data['stage'] == 'ready') {
              final lesson = await lessonForSource(
                data['sourceId'] as int,
              ).timeout(const Duration(seconds: 10));
              if (active && !completion.isCompleted && lesson != null) {
                completion.complete(lesson);
              }
            }
            if (active &&
                !completion.isCompleted &&
                data['stage'] == 'failed') {
              completion.completeError(
                const Failure(
                  'We saved the source transcript, but could not prepare a complete lesson. Try again; the video will not need to be reread.',
                ),
              );
            }
            return data;
          } catch (_) {
            return null;
          } finally {
            polling = false;
          }
        }

        final timer = Timer.periodic(
          const Duration(seconds: 2),
          (_) => status(),
        );
        try {
          final request = _client.ingestion.processSourceAndCompile(
            'url',
            title,
            session.target.code,
            session.support.code,
            session.level.code,
            url,
            null,
          );
          final lesson = await Future.any([
            request,
            completion.future,
          ]).timeout(_compileTimeout);
          onProgress?.call('ready');
          return lesson;
        } on TimeoutException {
          // A client timeout does not cancel the server's AI work. Recover the
          // saved result instead of requiring a duplicate import.
          // Long transcripts plus a provider repair/failover can exceed three
          // minutes. Keep observing the same job rather than abandon it and
          // encourage another costly compilation while it is still running.
          final deadline = DateTime.now().add(const Duration(minutes: 6));
          while (DateTime.now().isBefore(deadline)) {
            final update = await status();
            if (update?['stage'] == 'ready') {
              final lesson = await lessonForSource(update!['sourceId'] as int);
              if (lesson != null) return lesson;
            }
            if (update?['stage'] == 'failed') {
              throw const Failure(
                'We saved the source transcript, but could not prepare a complete lesson. Try again; the video will not need to be reread.',
              );
            }
            await Future<void>.delayed(const Duration(seconds: 2));
          }
          throw const Failure(
            'Preparation is taking longer than expected. Check My content before importing again.',
          );
        } on ServerpodClientInternalServerError catch (error) {
          // Serverpod masks exception details for internal errors. The
          // owner-scoped status endpoint tells us whether text was saved.
          Map<String, dynamic>? update;
          final statusDeadline = DateTime.now().add(
            const Duration(seconds: 4),
          );
          while (DateTime.now().isBefore(statusDeadline) && update == null) {
            update = await status();
            if (update == null) {
              await Future<void>.delayed(const Duration(milliseconds: 300));
            }
          }
          if (update?['stage'] == 'failed' || update?['stage'] == 'retrieved') {
            throw Failure(
              'We saved the source transcript, but could not prepare a complete lesson. Try again; the video will not need to be reread.',
              cause: error,
            );
          }
          rethrow;
        } finally {
          active = false;
          timer.cancel();
        }
      },
      serverErrorMessage:
          'Talkloom could not prepare this link. It may not expose readable captions; try again or paste the transcript.',
    );
  }

  Future<List<Source>> listSources(
    LearningSession session, {
    int limit = 100,
  }) async {
    return _guard(
      () => _client.ingestion
          .listSources(
            session.target.code,
            limit: limit,
            offset: 0,
          )
          .timeout(_turnTimeout),
    );
  }

  Future<List<Lesson>> listLessons(LearningSession session) => _guard(
    () => _client.ingestion
        .listLessons(session.target.code, limit: 100, offset: 0)
        .timeout(_turnTimeout),
  );

  Future<void> removeSource(int sourceId) => _guard(() async {
    final removed = await _client.ingestion.removeSource(sourceId);
    if (!removed) {
      throw const Failure('This item is no longer in your content.');
    }
  });

  Future<void> restoreSource(int sourceId) => _guard(() async {
    final restored = await _client.ingestion.restoreSource(sourceId);
    if (!restored) throw const Failure('This item can no longer be restored.');
  });

  Future<Lesson?> lessonForSource(int sourceId) {
    return _guard(() => _client.ingestion.getLessonBySourceId(sourceId));
  }

  Future<LearnerState?> learnerState(LearningSession session) async {
    return _guard(
      () => _client.pedagogical
          .getLearnerState(session.target.code)
          .timeout(_turnTimeout),
    );
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
