import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../core/failure.dart';
import '../domain/learning_session.dart';
import '../domain/source_reading.dart';

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
    this.evaluationStatus,
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

  /// Server evaluator status (`evaluated`, `evaluator_unavailable`,
  /// `assisted`), or null when no lesson was active so nothing was evaluated.
  final String? evaluationStatus;

  /// True only when the server says its independent evaluator could not run.
  bool get evaluatorUnavailable => evaluationStatus == 'evaluator_unavailable';

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
      evaluationStatus: (json['evaluation'] is Map)
          ? (json['evaluation'] as Map)['status'] as String?
          : null,
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

  static const _startTimeout = Duration(seconds: 30);
  static const _jobDeadline = Duration(minutes: 15);
  static const _reconnectDelay = Duration(seconds: 2);
  static const _maxReconnects = 5;
  static const _turnTimeout = Duration(seconds: 45);

  Stream<SourceReadingBatch> readSource({
    required int sourceId,
    required String supportLanguage,
    required String mode,
  }) async* {
    try {
      await for (final raw
          in _client.sourceReading
              .readSource(sourceId, supportLanguage, mode)
              .timeout(const Duration(seconds: 120))) {
        yield SourceReadingBatch.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
    } catch (error) {
      throw Failure.from(error);
    }
  }

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
    void Function(String stage)? onProgress,
  }) => _importInBackground(
    session: session,
    type: 'text',
    title: title,
    rawContent: text,
    onProgress: onProgress,
  );

  Future<Lesson> compileFromMedia({
    required LearningSession session,
    required String title,
    required String base64Content,
    String type = 'document',
    void Function(String stage)? onProgress,
  }) => _importInBackground(
    session: session,
    type: type,
    title: title,
    rawContent: base64Content,
    onProgress: onProgress,
  );

  Future<Lesson> compileFromUrl({
    required LearningSession session,
    required String title,
    required String url,
    void Function(String stage)? onProgress,
  }) => _importInBackground(
    session: session,
    type: 'url',
    title: title,
    url: url,
    onProgress: onProgress,
    serverErrorMessage:
        'Talkloom could not prepare this link. It may not expose readable captions; try again or paste the transcript.',
  );

  /// Queues a server-side import job (a Serverpod Future Call compiles it in
  /// the background) and follows its owner-scoped progress stream.
  @visibleForTesting
  Future<ImportJob> startImportJob({
    required LearningSession session,
    required String type,
    required String title,
    String? url,
    String? rawContent,
  }) => _client.ingestion.startImport(
    type,
    title,
    session.target.code,
    session.support.code,
    session.level.code,
    url,
    rawContent,
  );

  /// Server-pushed stages: queued, fetching, transcript, compiling,
  /// validating, then saved or failed. The first event is the current state.
  @visibleForTesting
  Stream<ImportJobProgress> watchImportJob(int jobId) =>
      _client.ingestion.watchImportJob(jobId);

  Future<Lesson> _importInBackground({
    required LearningSession session,
    required String type,
    required String title,
    String? url,
    String? rawContent,
    void Function(String stage)? onProgress,
    String? serverErrorMessage,
  }) {
    return _guard(() async {
      final job = await startImportJob(
        session: session,
        type: type,
        title: title,
        url: url,
        rawContent: rawContent,
      ).timeout(_startTimeout);
      final jobId = job.id;
      if (jobId == null) {
        throw const Failure('The import could not be started. Try again.');
      }
      onProgress?.call(job.stage);

      // The job keeps running on the server if the socket drops, and every
      // new subscription starts with the current state, so reconnecting is
      // enough to recover; nothing is imported twice.
      final deadline = DateTime.now().add(_jobDeadline);
      var reconnects = 0;
      while (true) {
        try {
          await for (final progress in watchImportJob(jobId)) {
            onProgress?.call(progress.stage);
            if (progress.stage == 'saved') return await _savedLesson(progress);
            if (progress.stage == 'failed') throw _jobFailure(progress);
          }
        } on Failure {
          rethrow;
        } on ImportException {
          rethrow;
        } catch (_) {
          if (++reconnects > _maxReconnects ||
              DateTime.now().isAfter(deadline)) {
            rethrow;
          }
        }
        if (DateTime.now().isAfter(deadline)) {
          throw const Failure(
            'Preparation is taking longer than expected. Check My content before importing again.',
          );
        }
        await Future<void>.delayed(_reconnectDelay);
      }
    }, serverErrorMessage: serverErrorMessage);
  }

  Future<Lesson> _savedLesson(ImportJobProgress progress) async {
    final sourceId = progress.sourceId;
    final lesson = sourceId == null
        ? null
        : await lessonForSource(sourceId).timeout(_turnTimeout);
    if (lesson == null) {
      throw const Failure(
        'The lesson was saved but could not be opened. Check My content.',
      );
    }
    return lesson;
  }

  static Failure _jobFailure(ImportJobProgress progress) => Failure.from(
    ImportException(
      code: progress.errorCode ?? 'unreadable',
      message:
          progress.errorMessage ??
          'Talkloom could not prepare this source. Try again, or paste the text.',
    ),
  );

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
    int? lessonId,
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
            lessonId: lessonId,
          )
          .timeout(_turnTimeout);

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const Failure('The tutor sent back an unreadable response.');
      }
      return ConversationTurn.fromJson(decoded, latencySec);
    });
  }

  /// Transcribes learner audio with Muse Voice Transcribe (Meta Model API).
  /// [base64Audio] must be mono 16-bit PCM WAV. [vocabulary] biases
  /// recognition toward the lesson's target words. Returns the transcript.
  Future<String> transcribeLearnerAudio({
    required LearningSession session,
    required String base64Audio,
    List<String>? vocabulary,
  }) {
    return _guard(() async {
      final raw = await _client.speech
          .transcribe(
            base64Audio,
            session.target.code,
            vocabulary: vocabulary,
          )
          .timeout(_turnTimeout);

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const Failure('The transcription came back unreadable.');
      }
      final text = decoded['text'];
      if (text is! String || text.trim().isEmpty) {
        throw const Failure('Muse heard no speech. Try again.');
      }
      return text.trim();
    });
  }

  /// Agent-Reach channel catalog: which connected sources this server can
  /// read (YouTube, Reddit, Web, ...). Drives the "Connected sources" UI.
  /// Returns channel names in catalog order; empty when unreachable.
  Future<List<String>> connectedChannels() async {
    try {
      final raw = await _client.agentReach.channels().timeout(_turnTimeout);
      final decoded = jsonDecode(raw);
      final channels = decoded is Map ? decoded['channels'] : null;
      if (channels is! List) return const [];
      return [
        for (final entry in channels)
          if (entry is Map && entry['name'] is String)
            (entry['name'] as String).toLowerCase(),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Recompiles one owned source with the current lesson compiler and
  /// writes the improved lesson back to the shared analysis.
  Future<Lesson> refreshLesson({
    required LearningSession session,
    required int sourceId,
  }) {
    // Recompilation takes minutes on Contributor models; reuse the import
    // job deadline rather than the short turn timeout.
    return _guard(
      () => _client.ingestion.refreshLesson(sourceId).timeout(_jobDeadline),
    );
  }

  /// Repairs the learner's own saved lessons against the current quality
  /// gates. Returns (repaired, failed, clean) counts for the dialog.
  Future<({int repaired, int failed, int clean})> repairLessons(
    LearningSession session,
  ) {
    return _guard(() async {
      final raw = await _client.knowledge
          .repairMyLessons(session.target.code, maxRepairs: 5)
          .timeout(_jobDeadline);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const Failure('The repair came back unreadable.');
      }
      return (
        repaired: (decoded['repaired'] as List?)?.length ?? 0,
        failed: (decoded['failed'] as List?)?.length ?? 0,
        clean: (decoded['clean'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// Shared cross-language word art, keyed by lemma. Returns base64 bytes
  /// or null when unavailable (callers show no art rather than a placeholder).
  Future<String?> wordArt({
    required String lemma,
    required String language,
    String? meaning,
  }) {
    final clean = lemma.trim();
    if (clean.isEmpty) return Future.value();
    return _guard(() async {
      final raw = await _client.illustration
          .wordArt(clean, language, meaning: meaning)
          .timeout(_turnTimeout);
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final image = decoded['image'];
      return image is String && image.isNotEmpty ? image : null;
    }).catchError((_) => null);
  }

  /// House-style scene art for a source, via Muse Image (Meta Model API).  /// Returns base64 image bytes, or null when illustration is unavailable
  /// (callers fall back to the designed sticker banner).
  Future<String?> illustrateSource(String subject) {
    final clean = subject.trim();
    if (clean.isEmpty) return Future.value();
    return _guard(() async {
      final raw = await _client.illustration
          .illustrate(clean.length > 200 ? clean.substring(0, 200) : clean)
          .timeout(_turnTimeout);

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final image = decoded['image'];
      if (image is! String || image.isEmpty) return null;
      return image;
    }).catchError((_) => null);
  }

  /// Server-verified per-target evidence for the learner's words and grammar.
  Future<List<WordEvidenceSummary>> wordEvidence(LearningSession session) {
    return _guard(
      () => _client.pedagogical
          .getWordEvidenceSummary(session.target.code)
          .timeout(_turnTimeout),
    );
  }
}
