import 'dart:async';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../generated/future_calls.dart';
import '../usage/ai_quota_service.dart';
import 'import_job_runner.dart';
import 'lesson_import_service.dart';
import 'link_classifier.dart';
import 'target_language_guard.dart';

class IngestionEndpoint extends Endpoint {
  final LessonImportService _importService = LessonImportService();

  /// Sources, lessons and import jobs belong to a learner, so every method
  /// here is scoped to the authenticated session.
  @override
  bool get requireLogin => true;

  static const _importTypes = {'url', 'text', 'document', 'image', 'ocr'};
  static const _maxRawContentLength = 15 * 1024 * 1024;

  /// How long a progress stream stays open without hearing a terminal stage.
  static const _streamLifetime = Duration(minutes: 15);

  /// Without Redis, server events are local to one instance; re-reading the
  /// row this often keeps a stream correct when the job runs elsewhere.
  static const _streamRecheck = Duration(seconds: 10);

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.userIdentifier;
    if (authUserId == null) {
      throw StateError('Sign in to manage your learning content.');
    }
    return authUserId.toString();
  }

  /// Synchronous import kept for older clients. New clients use
  /// [startImport] and [watchImportJob].
  Future<Lesson> processSourceAndCompile(
    Session session,
    String type, // 'url', 'text', 'document'
    String title,
    String targetLanguage,
    String supportLanguage,
    String cefrLevel,
    String? url,
    String? rawContent,
  ) async {
    _checkPastedLanguage(
      type: type,
      rawContent: rawContent,
      targetLanguage: targetLanguage,
    );
    _checkNoProfilePage(type: type, url: url);
    await AiQuotaService.consume(session, 'import');
    return _importService.importSource(
      session,
      userId: _requireUserId(session),
      type: type,
      title: title,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      cefrLevel: cefrLevel,
      url: url,
      rawContent: rawContent,
    );
  }

  /// Validates the request, records an [ImportJob] and hands compilation to
  /// a Future Call. Returns at once; follow it with [watchImportJob].
  Future<ImportJob> startImport(
    Session session,
    String type,
    String title,
    String targetLanguage,
    String supportLanguage,
    String cefrLevel,
    String? url,
    String? rawContent,
  ) async {
    _checkPastedLanguage(
      type: type,
      rawContent: rawContent,
      targetLanguage: targetLanguage,
    );
    _checkNoProfilePage(type: type, url: url);
    await AiQuotaService.consume(session, 'import');
    final userId = _requireUserId(session);
    if (!_importTypes.contains(type)) {
      throw ImportException(
        code: 'unsupported_link',
        message: 'This kind of source is not supported.',
      );
    }
    String? normalizedUrl;
    if (type == 'url') {
      if (url == null || url.trim().isEmpty) {
        throw ImportException(
          code: 'unsupported_link',
          message: 'Enter a complete video or web link.',
        );
      }
      try {
        // Applies the SSRF policy before anything is queued.
        normalizedUrl = _importService.normalizeUrl(url.trim());
      } on ArgumentError catch (e) {
        throw ImportException(
          code: 'unsupported_link',
          message: e.message?.toString() ?? 'This link is not supported.',
        );
      } on FormatException {
        throw ImportException(
          code: 'unsupported_link',
          message: 'This link is not supported.',
        );
      }
    } else if (rawContent == null || rawContent.trim().isEmpty) {
      throw ImportException(
        code: 'no_text',
        message: 'Add some text or choose a file first.',
      );
    } else if (rawContent.length > _maxRawContentLength) {
      throw ImportException(
        code: 'unreadable',
        message: 'This source is too large. Try a shorter text or file.',
      );
    }

    final now = DateTime.now();
    final job = await ImportJob.db.insertRow(
      session,
      ImportJob(
        userId: userId,
        type: type,
        title: title,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        cefrLevel: cefrLevel,
        url: normalizedUrl,
        rawContent: type == 'url' ? null : rawContent,
        stage: ImportStage.queued,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await session.serverpod.futureCalls
        .callWithDelay(Duration.zero, identifier: 'import-job-${job.id}')
        .importJob
        .compile(job.id!);
    return job;
  }

  /// The caller's own job, or null for a missing or foreign id.
  Future<ImportJob?> getImportJob(Session session, int jobId) {
    final userId = _requireUserId(session);
    return _ownedJob(session, userId, jobId);
  }

  /// Pushes progress for one of the caller's import jobs: the current state
  /// first, then each stage until saved or failed. Another learner's job id
  /// fails exactly like a missing one.
  Stream<ImportJobProgress> watchImportJob(Session session, int jobId) async* {
    final userId = _requireUserId(session);
    final initial = await _ownedJob(session, userId, jobId);
    if (initial == null) {
      throw ImportException(
        code: 'not_found',
        message: 'This import is no longer available.',
      );
    }

    // Subscribe before yielding the snapshot so no stage is missed between.
    const recheck = -1;
    final updates = session.messages
        .createStream<ImportJobProgress>(ImportJobRunner.channel(jobId))
        .timeout(
          _streamRecheck,
          onTimeout: (sink) =>
              sink.add(ImportJobProgress(jobId: recheck, stage: '')),
        );

    var last = ImportJobRunner.progressOf(initial);
    yield last;
    if (ImportStage.isTerminal(last.stage)) return;

    final deadline = DateTime.now().add(_streamLifetime);
    await for (var update in updates) {
      if (update.jobId == recheck) {
        final current = await _ownedJob(session, userId, jobId);
        if (current == null) return;
        update = ImportJobRunner.progressOf(current);
      }
      if (update.jobId != jobId) continue;
      if (update.stage != last.stage || update.sourceId != last.sourceId) {
        last = update;
        yield update;
      }
      if (ImportStage.isTerminal(update.stage)) return;
      if (DateTime.now().isAfter(deadline)) return;
    }
  }

  /// Profile/account pages hold no single lesson. Fail fast with guidance
  /// instead of burning quota and returning a login wall as "content".
  static void _checkNoProfilePage({
    required String type,
    required String? url,
  }) {
    if (type != 'url' || url == null || url.trim().isEmpty) return;
    final account = LinkClassifier.profileAccount(url.trim());
    if (account == null) return;
    throw ImportException(
      code: 'unsupported_link',
      message:
          'This is @$account\u2019s profile page, not a single post. '
          'Open the reel or post you want to learn from and share that link instead.',
    );
  }

  /// Upfront language check for pasted text: rejects wrong-language content
  /// before quota is consumed. Links and media are checked after extraction
  /// inside the import pipeline instead.
  static void _checkPastedLanguage({
    required String type,
    required String? rawContent,
    required String targetLanguage,
  }) {
    final text = rawContent;
    if (type != 'text' || text == null || text.trim().isEmpty) return;
    if (TargetLanguageGuard.isOpaqueMedia(text)) return;
    TargetLanguageGuard.checkText(text: text, targetLanguage: targetLanguage);
  }

  Future<ImportJob?> _ownedJob(Session session, String userId, int jobId) =>
      ImportJob.db.findFirstRow(
        session,
        where: (t) => t.id.equals(jobId) & t.userId.equals(userId),
      );

  Future<List<Source>> listSources(
    Session session,
    String targetLanguage, {
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _requireUserId(session);
    return await Source.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.targetLanguage.equals(targetLanguage) &
          t.isArchived.equals(false),
      orderBy: (t) => t.createdAt.desc(),
      limit: limit.clamp(1, 100),
      offset: offset < 0 ? 0 : offset,
    );
  }

  Future<Lesson?> getLessonBySourceId(Session session, int sourceId) async {
    final userId = _requireUserId(session);
    final source = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(sourceId) &
          t.userId.equals(userId) &
          t.isArchived.equals(false),
    );
    if (source == null) return null;
    return await Lesson.db.findFirstRow(
      session,
      where: (t) => t.sourceId.equals(sourceId) & t.userId.equals(userId),
    );
  }

  /// Recompiles one owned source with the current lesson compiler and
  /// writes the improved lesson back to the shared analysis, so future
  /// importers of the same material benefit too.
  Future<Lesson> refreshLesson(Session session, int sourceId) async {
    await AiQuotaService.consume(session, 'import');
    final userId = _requireUserId(session);
    return _importService.refreshLesson(
      session,
      userId: userId,
      sourceId: sourceId,
    );
  }

  Future<List<Lesson>> listLessons(
    Session session,
    String targetLanguage, {
    int limit = 50,
    int offset = 0,
  }) async {
    final userId = _requireUserId(session);
    final visibleSources = await Source.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.targetLanguage.equals(targetLanguage) &
          t.isArchived.equals(false),
      limit: 1000,
    );
    final visibleSourceIds = visibleSources.map((source) => source.id).toSet();
    final lessons = await Lesson.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: limit.clamp(1, 100),
      offset: offset < 0 ? 0 : offset,
    );
    return lessons
        .where((lesson) => visibleSourceIds.contains(lesson.sourceId))
        .toList();
  }

  Future<bool> removeSource(Session session, int sourceId) async {
    final userId = _requireUserId(session);
    final source = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(sourceId) &
          t.userId.equals(userId) &
          t.isArchived.equals(false),
    );
    if (source == null) return false;
    source.isArchived = true;
    await Source.db.updateRow(session, source);
    return true;
  }

  Future<bool> restoreSource(Session session, int sourceId) async {
    final userId = _requireUserId(session);
    final source = await Source.db.findFirstRow(
      session,
      where: (t) => t.id.equals(sourceId) & t.userId.equals(userId),
    );
    if (source == null || !source.isArchived) return false;
    source.isArchived = false;
    await Source.db.updateRow(session, source);
    return true;
  }
}
