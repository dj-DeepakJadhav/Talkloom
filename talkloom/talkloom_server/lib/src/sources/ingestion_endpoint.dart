import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';
import '../services/ingestion_service.dart';
import '../services/tavily_service.dart';
import '../services/dual_ai_compiler_service.dart';
import 'safe_url_policy.dart';

class IngestionEndpoint extends Endpoint {
  /// Only reports this learner's import, never another owner's cache rows.
  Future<String> getImportStatus(
    Session session,
    String url,
    String targetLanguage,
    DateTime startedAt,
  ) async {
    final owner = _requireUserId(session);
    final source = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(owner) &
          t.url.equals(_normalizeUrl(url)) &
          t.targetLanguage.equals(targetLanguage) &
          t.createdAt.between(startedAt, DateTime.now()),
      orderBy: (t) => t.createdAt.desc(),
    );
    if (source == null) return jsonEncode({'stage': 'reading'});
    final lesson = await Lesson.db.findFirstRow(
      session,
      where: (t) => t.sourceId.equals(source.id!) & t.userId.equals(owner),
    );
    return jsonEncode({
      'stage': lesson != null
          ? 'ready'
          : source.isArchived
          ? 'failed'
          : 'retrieved',
      'sourceId': source.id,
    });
  }

  final IngestionService _ingestionService = IngestionService();

  /// Sources and lessons belong to a learner, so every method here is scoped
  /// to the authenticated session.
  @override
  bool get requireLogin => true;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      throw StateError('Sign in to manage your learning content.');
    }
    return authUserId.toString();
  }

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
    final userId = _requireUserId(session);

    final normalizedUrl = type == 'url' && url != null
        ? _normalizeUrl(url)
        : null;
    if (normalizedUrl != null) {
      final saved = await _findSavedUrl(
        session,
        userId,
        targetLanguage,
        normalizedUrl,
      );
      if (saved != null) return saved;

      final cached = await _findCachedUrl(
        session,
        normalizedUrl,
        targetLanguage,
        supportLanguage,
        cefrLevel,
      );
      if (cached != null) {
        final copied = await _copyCachedLesson(
          session,
          cached,
          userId: userId,
          title: title,
          url: normalizedUrl,
          supportLanguage: supportLanguage,
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

    final nebiusApiKey = session.serverpod.getPassword('nebiusApiKey') ?? '';
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey') ?? '';
    final nvidiaApiKey = session.serverpod.getPassword('nvidiaApiKey') ?? '';
    final groqApiKey = session.serverpod.getPassword('groqApiKey') ?? '';
    final aiProviderSetting =
        session.serverpod.getPassword('aiProvider')?.toLowerCase() ?? 'gemini';

    final provider = aiProviderSetting == 'groq'
        ? AiProvider.groq
        : (aiProviderSetting == 'nvidia'
              ? AiProvider.nvidia
              : (aiProviderSetting == 'nebius'
                    ? AiProvider.nebius
                    : AiProvider.gemini));

    String textContent = rawContent ?? '';
    if (type == 'url' && url != null && url.isNotEmpty) {
      // Transcript reuse is independent of lesson level/completeness. Failed
      // lesson generation must not trigger another video retrieval.
      final candidates = await Source.db.find(
        session,
        where: (t) =>
            t.url.equals(normalizedUrl ?? url) &
            t.targetLanguage.equals(targetLanguage),
        orderBy: (t) => t.createdAt.desc(),
        limit: 100,
      );
      final transcript = candidates.where(_isReusableSource).firstOrNull;
      textContent =
          transcript?.rawText ??
          await _ingestionService.ingestUrl(normalizedUrl ?? url);
    } else if ((type == 'document' || type == 'image' || type == 'ocr') &&
        rawContent != null &&
        (rawContent.startsWith('data:image') ||
            rawContent.startsWith('data:application') ||
            rawContent.length > 500 && !rawContent.contains(' '))) {
      // Base64 document or image data
      textContent = await _ingestionService.extractTextFromMedia(
        base64Data: rawContent,
        mimeType: rawContent.startsWith('data:')
            ? rawContent.split(';').first.replaceFirst('data:', '')
            : 'image/jpeg',
        provider: provider,
        geminiApiKey: geminiApiKey,
        nvidiaApiKey: nvidiaApiKey,
        nebiusApiKey: nebiusApiKey,
      );
    }

    if (textContent.trim().isEmpty) {
      throw ArgumentError(
        'Could not read any usable text from this source. '
        'Check the link, or paste the text directly.',
      );
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
      ),
    );

    late final Map<String, dynamic> lessonDsl;
    try {
      // Ground the lesson in authentic cultural/statutory facts.
      final tavilyApiKey = session.serverpod.getPassword('tavilyApiKey') ?? '';
      final tavilyService = TavilyService(apiKey: tavilyApiKey);
      final grounding = await tavilyService.groundTopic(
        topic: effectiveTitle,
        targetLanguage: targetLanguage,
        contextSnippet: textContent.length > 200
            ? textContent.substring(0, 200)
            : textContent,
      );

      final compiler = DualLessonCompilerService(
        provider: provider,
        geminiApiKey: geminiApiKey,
        nebiusApiKey: nebiusApiKey,
        nvidiaApiKey: nvidiaApiKey,
        groqApiKey: groqApiKey,
      );

      lessonDsl = await compiler.compileLesson(
        sourceTitle: effectiveTitle,
        rawText: textContent,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        estimatedLevel: cefrLevel,
        grounding: grounding,
      );
    } catch (_) {
      // Preserve the extracted source in the shared database, but don't leave
      // a failed or incomplete import in the learner's active content list.
      savedSource.isArchived = true;
      await Source.db.updateRow(session, savedSource);
      rethrow;
    }

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
    if (normalizedUrl != null) {
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
      if (_normalizeUrl(source.url ?? '') != url || source.id == null) continue;
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
      if (_normalizeUrl(source.url ?? '') != url || source.id == null) continue;
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
    required String url,
    required String supportLanguage,
  }) async {
    final now = DateTime.now();
    final source = await Source.db.insertRow(
      session,
      Source(
        userId: userId,
        type: 'url',
        url: url,
        rawText: cached.source.rawText,
        title: title.trim().isEmpty ? cached.source.title : title.trim(),
        targetLanguage: cached.source.targetLanguage,
        cefrLevel: cached.source.cefrLevel,
        createdAt: now,
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
          _normalizeUrl(source.url ?? '') != url ||
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

  String _normalizeUrl(String input) {
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

  bool _isReusableSource(Source source) {
    final text = source.rawText.toLowerCase();
    const syntheticMarkers = [
      'inspired by this video',
      'authentic conversational material',
      'real-world conversational content and spoken language discussion',
      'extracted web content from',
      'daily social media commentary and cultural discussion',
    ];
    return source.rawText.trim().length >= 40 &&
        !syntheticMarkers.any(text.contains);
  }

  bool _hasCompleteTakeaways(Lesson lesson, String sourceText) {
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
    final minimumGrammar = length >= 6000
        ? 3
        : (length >= 2500 ? 2 : (length >= 500 ? 1 : 0));
    final normalizedSource = _normalizeEvidence(sourceText);
    final vocabulary = decodeList(lesson.vocabulary)
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
    final grammar = decodeList(lesson.grammar)
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
