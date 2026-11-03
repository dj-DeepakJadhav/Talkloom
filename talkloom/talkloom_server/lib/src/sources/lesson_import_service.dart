import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/dual_ai_compiler_service.dart';
import '../services/ingestion_service.dart';
import 'link_classifier.dart';
import 'safe_url_policy.dart';
import 'content_hygiene_service.dart';
import 'target_language_guard.dart';

/// Progress stage names shared by the import pipeline, the background Future
/// Call and the owner-scoped progress stream.
abstract final class ImportStage {
  static const queued = 'queued';
  static const fetching = 'fetching';
  static const transcript = 'transcript';
  static const compiling = 'compiling';
  static const validating = 'validating';
  static const saved = 'saved';
  static const failed = 'failed';

  static bool isTerminal(String stage) => stage == saved || stage == failed;
}

typedef ImportStageCallback =
    FutureOr<void> Function(String stage, {int? sourceId});

/// The source-to-lesson pipeline. Used by the synchronous endpoint method and
/// by the background import Future Call.
class LessonImportService {
  LessonImportService({IngestionService? ingestionService})
    : _ingestionService = ingestionService ?? IngestionService();

  final IngestionService _ingestionService;

  /// Imports of one link and language pair that are running in this process.
  /// A second learner submitting the same link waits for the first compile and
  /// then reads its cached result instead of paying for another one.
  final Map<String, Future<void>> _inFlight = {};

  /// Turns every extraction failure into an [ImportException]. Serverpod masks
  /// ordinary errors as a bare 500, which leaves the learner with no next step.
  Future<String> ingestUrlOrExplain(
    String url, {
    String? userScopeId,
    Session? session,
  }) async {
    try {
      return await _ingestionService.ingestUrl(
        url,
        userScopeId: userScopeId,
        session: session,
      );
    } on ImportException {
      rethrow;
    } on ArgumentError catch (e) {
      throw ImportException(
        code: 'unsupported_link',
        message: e.message?.toString() ?? 'This link is not supported.',
      );
    } on StateError catch (e) {
      throw ImportException(code: 'unreadable', message: e.message);
    } on TimeoutException {
      throw ImportException(
        code: 'timeout',
        message:
            'The link took too long to respond. Try again, or paste the text.',
      );
    } on Exception {
      throw ImportException(
        code: 'unreachable',
        message:
            'Talkloom could not open this link. Check it, or paste the text.',
      );
    }
  }

  /// Reads [type] content, saves it as a [Source] and compiles a [Lesson].
  ///
  /// [onStage] is told when the pipeline enters fetching, transcript,
  /// compiling and validating, plus the saved source id once it exists.
  Future<Lesson> importSource(
    Session session, {
    required String userId,
    required String type, // 'url', 'text', 'document', 'image', 'ocr'
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? rawContent,
    ImportStageCallback? onStage,
  }) async {
    Future<Lesson> run() => _importSource(
      session,
      userId: userId,
      type: type,
      title: title,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      cefrLevel: cefrLevel,
      url: url,
      rawContent: rawContent,
      onStage: onStage,
    );
    final cacheKey = _cacheKey(type, url, rawContent);
    if (cacheKey == null) return run();

    final key = '$cacheKey|$targetLanguage|$supportLanguage|$cefrLevel';
    for (var pending = _inFlight[key]; pending != null;) {
      try {
        await pending;
      } catch (_) {}
      pending = _inFlight[key];
    }
    final done = Completer<void>();
    _inFlight[key] = done.future;
    try {
      return await run();
    } finally {
      unawaited(_inFlight.remove(key));
      done.complete();
    }
  }

  Future<Lesson> _importSource(
    Session session, {
    required String userId,
    required String type,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? rawContent,
    ImportStageCallback? onStage,
  }) async {
    Future<void> stage(String name, {int? sourceId}) async =>
        onStage?.call(name, sourceId: sourceId);

    final normalizedUrl = type == 'url' && url != null
        ? normalizeUrl(url)
        : null;
    if (normalizedUrl != null) {
      final saved = await _findSavedUrl(
        session,
        userId,
        targetLanguage,
        normalizedUrl,
      );
      if (saved != null) return saved;

      final analysis = await _findAnalysis(
        session,
        normalizedUrl,
        targetLanguage,
        supportLanguage,
        cefrLevel,
      );
      if (analysis != null) {
        final copied = await _copyCachedLesson(
          session,
          (
            source: _sourceOf(analysis),
            lesson: _lessonOf(analysis, userId, supportLanguage),
          ),
          userId: userId,
          title: title,
          url: normalizedUrl,
          supportLanguage: supportLanguage,
          platform: analysis.platform,
          creator: analysis.creator,
        );
        await _archiveIncompleteSavedUrls(
          session,
          userId: userId,
          targetLanguage: targetLanguage,
          url: normalizedUrl,
          keepSourceId: copied.sourceId,
        );
        return copied;
      }

      // Lessons imported before the shared cache existed live in `sources`.
      final cached = await _findCachedUrl(
        session,
        normalizedUrl,
        targetLanguage,
        supportLanguage,
        cefrLevel,
      );
      if (cached != null) {
        final classification = LinkClassifier.classify(
          normalizedUrl,
          transcript: cached.source.rawText,
        );
        final copied = await _copyCachedLesson(
          session,
          cached,
          userId: userId,
          title: title,
          url: normalizedUrl,
          supportLanguage: supportLanguage,
          platform: classification.platform,
          creator: classification.creator,
        );
        await _storeAnalysis(
          session,
          url: normalizedUrl,
          source: cached.source,
          lesson: cached.lesson,
          classification: classification,
        );
        await _archiveIncompleteSavedUrls(
          session,
          userId: userId,
          targetLanguage: targetLanguage,
          url: normalizedUrl,
          keepSourceId: copied.sourceId,
        );
        return copied;
      }
    }

    // Pasted text, documents and images are shared by content, so identical
    // material is analysed (and OCR'd) once.
    final contentKey = normalizedUrl == null
        ? _cacheKey(type, null, rawContent)
        : null;
    if (contentKey != null) {
      final analysis = await _findAnalysis(
        session,
        contentKey,
        targetLanguage,
        supportLanguage,
        cefrLevel,
      );
      if (analysis != null) {
        return _copyCachedLesson(
          session,
          (
            source: _sourceOf(analysis),
            lesson: _lessonOf(analysis, userId, supportLanguage),
          ),
          userId: userId,
          title: title,
          type: type,
          supportLanguage: supportLanguage,
          platform: analysis.platform,
          creator: null,
        );
      }
    }

    final metaApiKey = session.serverpod.getPassword('metaApiKey') ?? '';

    await stage(ImportStage.fetching);
    String textContent = rawContent ?? '';
    // True when textContent came from a stored row rather than a live
    // fetch. A poisoned cache (e.g. an English shell saved before the
    // embedded resolver existed) must not fail forever: on a guard miss
    // we refetch live once before giving up.
    var textFromCache = false;
    if (type == 'url' && url != null && url.isNotEmpty) {
      // Transcript reuse is independent of lesson level/completeness. Failed
      // lesson generation must not trigger another video retrieval.
      final shared = await _findSharedTranscript(
        session,
        normalizedUrl ?? url,
        targetLanguage,
      );
      final candidates = shared != null
          ? const <Source>[]
          : await Source.db.find(
              session,
              where: (t) =>
                  t.url.equals(normalizedUrl ?? url) &
                  t.targetLanguage.equals(targetLanguage),
              orderBy: (t) => t.createdAt.desc(),
              limit: 100,
            );
      final transcript = candidates.where(_isReusableSource).firstOrNull;
      textFromCache = shared != null || transcript != null;
      textContent =
          shared ??
          transcript?.rawText ??
          await ingestUrlOrExplain(
            normalizedUrl ?? url,
            userScopeId: userId,
            session: session,
          );
    } else if ((type == 'document' || type == 'image' || type == 'ocr') &&
        rawContent != null &&
        (rawContent.startsWith('data:image') ||
            rawContent.startsWith('data:text/') ||
            rawContent.startsWith('data:application') ||
            rawContent.length > 500 && !rawContent.contains(' '))) {
      // Base64 document or image data. A stored reading of the same file
      // (possibly at another level) saves the OCR call.
      textContent =
          (contentKey == null
              ? null
              : await _findSharedTranscript(
                  session,
                  contentKey,
                  targetLanguage,
                )) ??
          await _ingestionService.extractTextFromMedia(
            base64Data: rawContent,
            mimeType: rawContent.startsWith('data:')
                ? rawContent.split(';').first.replaceFirst('data:', '')
                : 'image/jpeg',
            metaApiKey: metaApiKey,
          );
    }

    if (textContent.trim().isEmpty) {
      throw ArgumentError(
        'Could not read any usable text from this source. '
        'Check the link, or paste the text directly.',
      );
    }

    // No target-language content means no lesson — fail before the paid
    // compile step so the learner keeps their daily allowance.
    void judge(String text) {
      TargetLanguageGuard.checkText(
        text: text,
        targetLanguage: targetLanguage,
      );
      final shellDefects = ContentHygieneService.scanText(text);
      if (shellDefects.isNotEmpty) {
        session.log(
          'Hygiene defects in $type url=$url: $shellDefects',
          level: LogLevel.warning,
        );
      }
      if (ContentHygieneService.isPoisoned(text)) {
        throw ImportException(
          code: 'unreadable',
          message:
              'This page shows Talkloom only its shell, not its content. '
              'Open it in your browser and paste the text instead.',
        );
      }
    }

    try {
      judge(textContent);
    } on ImportException catch (e) {
      session.log(
        'Language guard rejected type=$type url=$url '
        'textLen=${textContent.length} fromCache=$textFromCache '
        'head=${textContent.substring(0, textContent.length > 160 ? 160 : textContent.length).replaceAll(RegExp(r'\s+'), ' ')}',
        level: LogLevel.warning,
      );
      // A cached shell from before the embedded resolver existed must
      // not fail forever: refetch live once, then judge the fresh text.
      if (textFromCache &&
          (e.code == 'wrong_language' || e.code == 'unreadable') &&
          type == 'url' &&
          url != null &&
          url.isNotEmpty) {
        session.log(
          'Language guard retrying live fetch for $url',
          level: LogLevel.warning,
        );
        textContent = await ingestUrlOrExplain(
          normalizedUrl ?? url,
          userScopeId: userId,
          session: session,
        );
        textFromCache = false;
        judge(textContent);
      } else {
        rethrow;
      }
    }

    String effectiveTitle = title;
    if (effectiveTitle == 'YouTube Video Lesson' ||
        effectiveTitle == 'Authentic Web Source' ||
        effectiveTitle.isEmpty) {
      final headerMatch = RegExp(
        r'^\[(?:YouTube Video|Social Media|Instagram|TikTok|Facebook):\s*([^\]]+)\]',
        multiLine: true,
      ).firstMatch(textContent);
      if (headerMatch != null) {
        effectiveTitle = headerMatch.group(1)?.trim() ?? effectiveTitle;
      }
    }

    final classification = normalizedUrl != null
        ? LinkClassifier.classify(normalizedUrl, transcript: textContent)
        : (contentKey == null
              ? null
              : LinkClassification(platform: _contentPlatform(type)));
    final savedSource = await Source.db.insertRow(
      session,
      Source(
        userId: userId,
        type: type,
        url: normalizedUrl ?? url,
        rawText: textContent,
        title: effectiveTitle,
        targetLanguage: targetLanguage,
        cefrLevel: cefrLevel,
        createdAt: DateTime.now(),
        platform: classification?.platform,
        creator: classification?.creator,
      ),
    );

    await stage(ImportStage.transcript, sourceId: savedSource.id);

    late final Map<String, dynamic> lessonDsl;
    try {
      await stage(ImportStage.compiling, sourceId: savedSource.id);

      final compiler = DualLessonCompilerService(metaApiKey: metaApiKey);

      lessonDsl = await compiler.compileLesson(
        sourceTitle: effectiveTitle,
        rawText: textContent,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        estimatedLevel: cefrLevel,
      );
    } catch (_) {
      // Preserve the extracted source in the shared database, but don't leave
      // a failed or incomplete import in the learner's active content list.
      savedSource.isArchived = true;
      await Source.db.updateRow(session, savedSource);
      rethrow;
    }

    await stage(ImportStage.validating, sourceId: savedSource.id);
    final savedLesson = await Lesson.db.insertRow(
      session,
      Lesson(
        userId: userId,
        sourceId: savedSource.id!,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        objectives:
            (lessonDsl['objectives'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        vocabulary: jsonEncode(lessonDsl['vocabulary'] ?? const []),
        grammar: jsonEncode(lessonDsl['grammar'] ?? const []),
        activities: jsonEncode(lessonDsl['activities'] ?? const []),
        conversationPlan: jsonEncode(lessonDsl['conversation'] ?? const {}),
        createdAt: DateTime.now(),
      ),
    );
    if (contentKey != null) {
      await _storeAnalysis(
        session,
        url: contentKey,
        source: savedSource,
        lesson: savedLesson,
        classification: classification!,
      );
    }
    if (normalizedUrl != null) {
      await _storeAnalysis(
        session,
        url: normalizedUrl,
        source: savedSource,
        lesson: savedLesson,
        classification: classification!,
      );
      await _archiveIncompleteSavedUrls(
        session,
        userId: userId,
        targetLanguage: targetLanguage,
        url: normalizedUrl,
        keepSourceId: savedSource.id!,
      );
    }
    return savedLesson;
  }

  /// Recompiles one owned source with the current lesson compiler and
  /// writes the improved lesson back to the shared analysis, so every
  /// learner who imports the same material afterwards benefits.
  /// Curation propagation without a schema change: the learner's own rows
  /// are updated in place, and the shared row is overwritten like any
  /// fresh import.
  Future<Lesson> refreshLesson(
    Session session, {
    required String userId,
    required int sourceId,
    bool refetch = false,
  }) async {
    final source = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(sourceId) &
          t.userId.equals(userId) &
          t.isArchived.equals(false),
    );
    if (source == null) {
      throw ArgumentError('That source is not in your learning content.');
    }
    // Poisoned shell rows (saved before the embedded resolver existed)
    // recompile from live content instead of the stale shell.
    if (refetch && source.url != null && source.type == 'url') {
      session.log('Refresh refetching live content for source ${source.id}');
      source.rawText = await ingestUrlOrExplain(
        normalizeUrl(source.url!),
        userScopeId: userId,
        session: session,
      );
      await Source.db.updateRow(session, source);
    }
    if (source.rawText.trim().isEmpty) {
      throw ArgumentError(
        'There is no saved text to rebuild this lesson from.',
      );
    }
    TargetLanguageGuard.checkText(
      text: source.rawText,
      targetLanguage: source.targetLanguage,
    );
    final metaApiKey = session.serverpod.getPassword('metaApiKey') ?? '';
    final owned = await Lesson.db.findFirstRow(
      session,
      where: (t) => t.sourceId.equals(source.id!) & t.userId.equals(userId),
    );
    final supportLanguage = owned?.supportLanguage ?? 'en';
    final lessonDsl = await DualLessonCompilerService(metaApiKey: metaApiKey)
        .compileLesson(
          sourceTitle: source.title,
          rawText: source.rawText,
          targetLanguage: source.targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: source.cefrLevel,
        )
        .timeout(const Duration(minutes: 10));

    final savedLesson = owned == null
        ? await Lesson.db.insertRow(
            session,
            Lesson(
              userId: userId,
              sourceId: source.id!,
              targetLanguage: source.targetLanguage,
              supportLanguage: supportLanguage,
              objectives:
                  (lessonDsl['objectives'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  const [],
              vocabulary: jsonEncode(lessonDsl['vocabulary'] ?? const []),
              grammar: jsonEncode(lessonDsl['grammar'] ?? const []),
              activities: jsonEncode(lessonDsl['activities'] ?? const []),
              conversationPlan: jsonEncode(
                lessonDsl['conversation'] ?? const {},
              ),
              createdAt: DateTime.now(),
            ),
          )
        : await Lesson.db.updateRow(
            session,
            owned
              ..objectives =
                  (lessonDsl['objectives'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  const []
              ..vocabulary = jsonEncode(lessonDsl['vocabulary'] ?? const [])
              ..grammar = jsonEncode(lessonDsl['grammar'] ?? const [])
              ..activities = jsonEncode(lessonDsl['activities'] ?? const [])
              ..conversationPlan = jsonEncode(
                lessonDsl['conversation'] ?? const {},
              ),
          );

    final normalizedUrl = source.url;
    final classification = normalizedUrl == null
        ? LinkClassification(platform: _contentPlatform(source.type))
        : LinkClassifier.classify(normalizedUrl);
    await _storeAnalysis(
      session,
      url:
          normalizedUrl ??
          _cacheKey(source.type, null, source.rawText) ??
          source.url ??
          'source:${source.id}',
      source: source,
      lesson: savedLesson,
      classification: classification,
    );
    return savedLesson;
  }

  /// The shared analysis for this exact link, language pair and level, or null
  /// when there is none, it has expired, or it no longer passes validation.
  /// A hit is counted.
  Future<LinkAnalysis?> _findAnalysis(
    Session session,
    String url,
    String targetLanguage,
    String supportLanguage,
    String cefrLevel,
  ) async {
    final row = await LinkAnalysis.db.findFirstRow(
      session,
      where: (t) =>
          t.normalizedUrl.equals(url) &
          t.targetLanguage.equals(targetLanguage) &
          t.supportLanguage.equals(supportLanguage) &
          t.cefrLevel.equals(cefrLevel),
    );
    if (row == null || _isExpired(row)) return null;
    if (!_isReusableText(row.transcript) ||
        !_hasCompleteContent(
          row.vocabulary,
          row.grammar,
          row.transcript,
          relaxedGrammar: true,
        )) {
      return null;
    }
    final now = DateTime.now();
    row
      ..hitCount += 1
      ..lastUsedAt = now;
    return LinkAnalysis.db.updateRow(session, row);
  }

  /// A stored transcript for this link in any level or support language, so a
  /// new level only pays for compilation, not for fetching the video again.
  Future<String?> _findSharedTranscript(
    Session session,
    String url,
    String targetLanguage,
  ) async {
    final rows = await LinkAnalysis.db.find(
      session,
      where: (t) =>
          t.normalizedUrl.equals(url) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: 20,
    );
    for (final row in rows) {
      if (!_isExpired(row) && _isReusableText(row.transcript)) {
        return row.transcript;
      }
    }
    return null;
  }

  bool _isExpired(LinkAnalysis row) =>
      row.expiresAt != null && row.expiresAt!.isBefore(DateTime.now());

  Source _sourceOf(LinkAnalysis row) => Source(
    userId: '',
    type: 'url',
    url: row.normalizedUrl.startsWith('content:') ? null : row.normalizedUrl,
    rawText: row.transcript,
    title: row.title,
    targetLanguage: row.targetLanguage,
    cefrLevel: row.cefrLevel,
    createdAt: row.createdAt,
    platform: row.platform,
    creator: row.creator,
  );

  Lesson _lessonOf(LinkAnalysis row, String userId, String supportLanguage) =>
      Lesson(
        userId: userId,
        sourceId: 0,
        targetLanguage: row.targetLanguage,
        supportLanguage: supportLanguage,
        objectives: row.objectives,
        vocabulary: row.vocabulary,
        grammar: row.grammar,
        activities: row.activities,
        conversationPlan: row.conversationPlan,
        createdAt: row.createdAt,
      );

  /// Records a validated lesson as the shared analysis for its link. Only
  /// complete, evidence-backed lessons are shared. Never fails the import: a
  /// lost race on the unique key means another import stored it first.
  Future<void> _storeAnalysis(
    Session session, {
    required String url,
    required Source source,
    required Lesson lesson,
    required LinkClassification classification,
  }) async {
    if (!_isReusableSource(source) ||
        !_hasCompleteContent(
          lesson.vocabulary,
          lesson.grammar,
          source.rawText,
          relaxedGrammar: true,
        )) {
      return;
    }
    final now = DateTime.now();
    final ttl = classification.timeToLive;
    try {
      final existing = await LinkAnalysis.db.findFirstRow(
        session,
        where: (t) =>
            t.normalizedUrl.equals(url) &
            t.targetLanguage.equals(source.targetLanguage) &
            t.supportLanguage.equals(lesson.supportLanguage) &
            t.cefrLevel.equals(source.cefrLevel),
      );
      final row =
          (existing ??
                LinkAnalysis(
                  normalizedUrl: url,
                  platform: classification.platform,
                  title: source.title,
                  targetLanguage: source.targetLanguage,
                  supportLanguage: lesson.supportLanguage,
                  cefrLevel: source.cefrLevel,
                  transcript: source.rawText,
                  contentHash: '',
                  objectives: lesson.objectives,
                  vocabulary: lesson.vocabulary,
                  grammar: lesson.grammar,
                  activities: lesson.activities,
                  conversationPlan: lesson.conversationPlan,
                  createdAt: now,
                  lastUsedAt: now,
                ))
            ..platform = classification.platform
            ..creator = classification.creator
            ..creatorKey = classification.creatorKey
            ..title = source.title
            ..transcript = source.rawText
            ..contentHash = _contentHash(source.rawText)
            ..objectives = lesson.objectives
            ..vocabulary = lesson.vocabulary
            ..grammar = lesson.grammar
            ..activities = lesson.activities
            ..conversationPlan = lesson.conversationPlan
            ..expiresAt = ttl == null ? null : now.add(ttl);
      if (existing == null) {
        await LinkAnalysis.db.insertRow(session, row);
      } else {
        await LinkAnalysis.db.updateRow(session, row);
      }
    } on DatabaseException catch (e, st) {
      session.log(
        'Could not store link analysis for $url: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );
    }
  }

  /// The shared-cache key: the normalised link, or `content:<hash>` for pasted
  /// text and uploaded files. Null when there is nothing to key on.
  String? _cacheKey(String type, String? url, String? rawContent) {
    if (type == 'url') return url == null ? null : normalizeUrl(url);
    if (rawContent == null || rawContent.trim().isEmpty) return null;
    // Base64 is case-sensitive, so only pasted text is normalised.
    final hash = type == 'text'
        ? _contentHash(rawContent)
        : sha256.convert(utf8.encode(rawContent)).toString();
    return 'content:$hash';
  }

  String _contentPlatform(String type) => switch (type) {
    'document' => LinkPlatform.document,
    'image' || 'ocr' => LinkPlatform.image,
    _ => LinkPlatform.text,
  };

  String _contentHash(String text) => sha256
      .convert(
        utf8.encode(text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim()),
      )
      .toString();

  Future<Lesson?> _findSavedUrl(
    Session session,
    String userId,
    String targetLanguage,
    String url,
  ) async {
    var sources = await Source.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.targetLanguage.equals(targetLanguage) &
          t.isArchived.equals(false) &
          t.type.equals('url') &
          t.url.equals(url),
      orderBy: (t) => t.createdAt.desc(),
      limit: 100,
    );
    if (sources.isEmpty) {
      sources = await Source.db.find(
        session,
        where: (t) =>
            t.userId.equals(userId) &
            t.targetLanguage.equals(targetLanguage) &
            t.isArchived.equals(false) &
            t.type.equals('url'),
        orderBy: (t) => t.createdAt.desc(),
        limit: 500,
      );
    }
    for (final source in sources) {
      if (normalizeUrl(source.url ?? '') != url || source.id == null) continue;
      final lesson = await Lesson.db.findFirstRow(
        session,
        where: (t) => t.sourceId.equals(source.id!) & t.userId.equals(userId),
      );
      if (lesson == null) continue;
      if (_hasCompleteTakeaways(lesson, source.rawText)) return lesson;

      // Leave the old lesson available until a replacement compiles successfully.
    }
    return null;
  }

  Future<({Source source, Lesson lesson})?> _findCachedUrl(
    Session session,
    String url,
    String targetLanguage,
    String supportLanguage,
    String cefrLevel,
  ) async {
    var sources = await Source.db.find(
      session,
      where: (t) => t.url.equals(url) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: 100,
    );
    if (sources.isEmpty) {
      sources = await Source.db.find(
        session,
        where: (t) =>
            t.targetLanguage.equals(targetLanguage) & t.type.equals('url'),
        orderBy: (t) => t.createdAt.desc(),
        limit: 1000,
      );
    }
    for (final source in sources) {
      if (normalizeUrl(source.url ?? '') != url || source.id == null) continue;
      if (source.cefrLevel != cefrLevel) continue;
      if (!_isReusableSource(source)) continue;
      final lesson = await Lesson.db.findFirstRow(
        session,
        where: (t) =>
            t.sourceId.equals(source.id!) &
            t.targetLanguage.equals(targetLanguage) &
            t.supportLanguage.equals(supportLanguage),
      );
      if (lesson != null && _hasCompleteTakeaways(lesson, source.rawText)) {
        return (source: source, lesson: lesson);
      }
    }
    return null;
  }

  Future<Lesson> _copyCachedLesson(
    Session session,
    ({Source source, Lesson lesson}) cached, {
    required String userId,
    required String title,
    String type = 'url',
    String? url,
    required String supportLanguage,
    String? platform,
    String? creator,
  }) async {
    final now = DateTime.now();
    final source = await Source.db.insertRow(
      session,
      Source(
        userId: userId,
        type: type,
        url: url,
        rawText: cached.source.rawText,
        title: title.trim().isEmpty ? cached.source.title : title.trim(),
        targetLanguage: cached.source.targetLanguage,
        cefrLevel: cached.source.cefrLevel,
        createdAt: now,
        platform: platform,
        creator: creator,
      ),
    );
    return Lesson.db.insertRow(
      session,
      Lesson(
        userId: userId,
        sourceId: source.id!,
        targetLanguage: cached.lesson.targetLanguage,
        supportLanguage: supportLanguage,
        objectives: cached.lesson.objectives,
        vocabulary: cached.lesson.vocabulary,
        grammar: cached.lesson.grammar,
        activities: cached.lesson.activities,
        conversationPlan: cached.lesson.conversationPlan,
        createdAt: now,
      ),
    );
  }

  Future<void> _archiveIncompleteSavedUrls(
    Session session, {
    required String userId,
    required String targetLanguage,
    required String url,
    required int keepSourceId,
  }) async {
    final sources = await Source.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.targetLanguage.equals(targetLanguage) &
          t.type.equals('url') &
          t.isArchived.equals(false),
      orderBy: (t) => t.createdAt.desc(),
      limit: 500,
    );
    for (final source in sources) {
      if (source.id == keepSourceId ||
          normalizeUrl(source.url ?? '') != url ||
          source.id == null) {
        continue;
      }
      final lessons = await Lesson.db.find(
        session,
        where: (t) => t.sourceId.equals(source.id!) & t.userId.equals(userId),
      );
      final hasCompleteLesson = lessons.any(
        (lesson) => _hasCompleteTakeaways(lesson, source.rawText),
      );
      if (!hasCompleteLesson) {
        source.isArchived = true;
        await Source.db.updateRow(session, source);
      }
    }
  }

  String normalizeUrl(String input) {
    final parsed = SafeUrlPolicy.parsePublicWebUrl(input);
    final host = parsed.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host == 'youtu.be' || host == 'youtube.com') {
      final videoId = host == 'youtu.be'
          ? parsed.pathSegments.firstOrNull
          : parsed.queryParameters['v'] ??
                (parsed.pathSegments.length > 1 &&
                        ['shorts', 'embed'].contains(parsed.pathSegments.first)
                    ? parsed.pathSegments[1]
                    : null);
      if (videoId != null && videoId.isNotEmpty) {
        return 'https://www.youtube.com/watch?v=$videoId';
      }
    }
    final query = Map<String, String>.from(parsed.queryParameters)
      ..removeWhere(
        (key, _) =>
            key.toLowerCase().startsWith('utm_') ||
            {'fbclid', 'gclid', 'si', 'feature'}.contains(key.toLowerCase()),
      );
    final sortedQuery = Map.fromEntries(
      query.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final path = parsed.path.replaceFirst(RegExp(r'/$'), '');
    return Uri(
      scheme: parsed.scheme.toLowerCase(),
      host: host,
      port: parsed.hasPort && parsed.port != 443 && parsed.port != 80
          ? parsed.port
          : null,
      path: path,
      queryParameters: sortedQuery.isEmpty ? null : sortedQuery,
    ).toString();
  }

  bool _isReusableSource(Source source) => _isReusableText(source.rawText);

  bool _isReusableText(String rawText) {
    final text = rawText.toLowerCase();
    const syntheticMarkers = [
      'inspired by this video',
      'authentic conversational material',
      'real-world conversational content and spoken language discussion',
      'extracted web content from',
      'daily social media commentary and cultural discussion',
    ];
    return rawText.trim().length >= 40 && !syntheticMarkers.any(text.contains);
  }

  bool _hasCompleteTakeaways(Lesson lesson, String sourceText) =>
      _hasCompleteContent(lesson.vocabulary, lesson.grammar, sourceText);

  /// Whether the lesson's vocabulary and grammar are backed by the source.
  ///
  /// [relaxedGrammar] still requires every counted item to quote the source
  /// and still requires enough vocabulary, but accepts a single grammar
  /// pattern however long the text. A page may simply contain little grammar,
  /// and re-compiling it can never produce more.
  bool _hasCompleteContent(
    String vocabularyJson,
    String grammarJson,
    String sourceText, {
    bool relaxedGrammar = false,
  }) {
    List<dynamic> decodeList(String value) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? decoded : const [];
      } catch (_) {
        return const [];
      }
    }

    final length = sourceText.trim().length;
    final minimumVocabulary = length >= 6000
        ? 15
        : (length >= 2500 ? 8 : (length >= 500 ? 4 : 1));
    var minimumGrammar = length >= 6000
        ? 3
        : (length >= 2500 ? 2 : (length >= 500 ? 1 : 0));
    if (relaxedGrammar && minimumGrammar > 1) minimumGrammar = 1;
    final normalizedSource = _normalizeEvidence(sourceText);
    final vocabulary = decodeList(vocabularyJson)
        .whereType<Map>()
        .where((item) {
          final lemma = item['lemma']?.toString().trim() ?? '';
          final meaning = item['meaning']?.toString().trim() ?? '';
          final context = _normalizeEvidence(
            item['sourceContext']?.toString() ?? '',
          );
          return lemma.isNotEmpty &&
              meaning.isNotEmpty &&
              context.isNotEmpty &&
              normalizedSource.contains(context);
        })
        .map((item) => item['lemma'].toString().trim().toLowerCase())
        .toSet();
    final grammar = decodeList(grammarJson)
        .whereType<Map>()
        .where((item) {
          final concept = item['concept']?.toString().trim() ?? '';
          final explanation = item['explanation']?.toString().trim() ?? '';
          final sentence = _normalizeEvidence(
            item['sourceSentence']?.toString() ?? '',
          );
          return concept.isNotEmpty &&
              explanation.isNotEmpty &&
              sentence.isNotEmpty &&
              normalizedSource.contains(sentence);
        })
        .map((item) => item['concept'].toString().trim().toLowerCase())
        .toSet();
    return vocabulary.length >= minimumVocabulary &&
        grammar.length >= minimumGrammar;
  }

  String _normalizeEvidence(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
