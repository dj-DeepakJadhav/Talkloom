import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';
import '../services/ingestion_service.dart';
import '../services/tavily_service.dart';
import '../services/dual_ai_compiler_service.dart';

class IngestionEndpoint extends Endpoint {
  final IngestionService _ingestionService = IngestionService();

  /// Sources and lessons belong to a learner, so every method here is scoped
  /// to the authenticated session.
  @override
  bool get requireLogin => false;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      return 'guest_learner';
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
      textContent = await _ingestionService.ingestUrl(url);
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
      final headerMatch = RegExp(r'^\[(?:YouTube Video|Social Media|Instagram|TikTok|Facebook):\s*([^\]]+)\]', multiLine: true).firstMatch(textContent);
      if (headerMatch != null) {
        effectiveTitle = headerMatch.group(1)?.trim() ?? effectiveTitle;
      }
    }

    final savedSource = await Source.db.insertRow(
      session,
      Source(
        userId: userId,
        type: type,
        url: url,
        rawText: textContent,
        title: effectiveTitle,
        targetLanguage: targetLanguage,
        cefrLevel: cefrLevel,
        createdAt: DateTime.now(),
      ),
    );

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

    final lessonDsl = await compiler.compileLesson(
      sourceTitle: effectiveTitle,
      rawText: textContent,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      estimatedLevel: cefrLevel,
      grounding: grounding,
    );

    return await Lesson.db.insertRow(
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
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: limit.clamp(1, 100),
      offset: offset < 0 ? 0 : offset,
    );
  }

  Future<Lesson?> getLessonBySourceId(Session session, int sourceId) async {
    final userId = _requireUserId(session);
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
    return await Lesson.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: limit.clamp(1, 100),
      offset: offset < 0 ? 0 : offset,
    );
  }
}
