import 'dart:convert';

import 'dw_learn_german.dart';

/// Generic lesson extraction from embedded page data.
///
/// JS-rendered lesson sites all hide their content the same way: a thin
/// static shell plus structured data in the HTML (Apollo/Next/Nuxt state,
/// JSON-LD, `<track>` subtitles). Each site differs only in *where* the
/// data sits, so that part lives in small adapters ([EmbeddedSiteAdapter]).
/// Everything else — subtitle download, VTT parsing, text composition — is
/// shared. Adding a site means adding an adapter, not a new pipeline.
abstract final class EmbeddedLessonResolver {
  static final List<EmbeddedSiteAdapter> _adapters = [
    DwLearnGermanAdapter(),
    JsonLdLessonAdapter(),
  ];

  /// Best-effort lesson text from raw [html], or null when no adapter finds
  /// real lesson content (the caller falls through to its generic reader).
  /// [fetchText] downloads a subtitle/track URL; failures mean that source
  /// is skipped, never fatal.
  static Future<String?> resolveFromHtml({
    required String html,
    required Future<String?> Function(String url) fetchText,
  }) async {
    EmbeddedLesson? lesson;
    for (final adapter in _adapters) {
      try {
        lesson = adapter.extract(html);
      } catch (_) {
        continue;
      }
      if (lesson != null && lesson.hasContent) break;
      lesson = null;
    }
    if (lesson == null) return null;

    final resolved = lesson;
    final parts = <String>[EmbeddedLesson.header(resolved.title)];
    if (resolved.dialogue != null && resolved.dialogue!.trim().length > 60) {
      parts.add('## Dialogue\n${resolved.dialogue!.trim()}');
    } else {
      for (final url in resolved.subtitleUrls) {
        try {
          final vtt = await fetchText(url);
          if (vtt == null) continue;
          final dialogue = DwLearnGerman.parseVtt(vtt);
          if (dialogue.trim().length > 60) {
            parts.add('## Dialogue\n$dialogue');
            break;
          }
        } catch (_) {
          continue;
        }
      }
    }
    if (resolved.vocabulary.isNotEmpty) {
      parts.add(
        '## Vocabulary\n${resolved.vocabulary.map((v) => '- ${v.$1}: ${v.$2}').join('\n')}',
      );
    }
    if (resolved.grammar.isNotEmpty) {
      parts.add(
        '## Grammar\n${resolved.grammar.map((g) => '- ${g.$1}: ${g.$2}').join('\n')}',
      );
    }
    final text = parts.join('\n\n');
    // No extra quality gate here: adapters only produce content from
    // explicit lesson signals (lesson JSON, subtitle tracks, transcripts),
    // never from shell text. The pipeline's target-language guard and the
    // compiler's evidence validation remain the backstops downstream.
    return text.length > 8000 ? '${text.substring(0, 8000)}\n…' : text;
  }
}

/// One site's way of hiding lesson data in static HTML.
abstract class EmbeddedSiteAdapter {
  /// Lesson data, or null when this page has none for this adapter.
  EmbeddedLesson? extract(String html);
}

/// Host-agnostic lesson content, whatever the adapter found.
class EmbeddedLesson {
  EmbeddedLesson({
    required this.title,
    this.subtitleUrls = const [],
    this.vocabulary = const [],
    this.grammar = const [],
    this.dialogue,
  });

  final String title;
  final List<String> subtitleUrls;

  /// (word, explanation) pairs.
  final List<(String, String)> vocabulary;

  /// (title, explanation) pairs.
  final List<(String, String)> grammar;

  /// Ready-made dialogue text (no subtitle download needed).
  final String? dialogue;

  bool get hasContent =>
      subtitleUrls.isNotEmpty ||
      vocabulary.isNotEmpty ||
      grammar.isNotEmpty ||
      (dialogue != null && dialogue!.trim().length > 60);

  static String header(String title) => '[Lesson: $title]';
}

/// DW Learn German: lesson data in `window.__APOLLO_STATE__`.
class DwLearnGermanAdapter implements EmbeddedSiteAdapter {
  @override
  EmbeddedLesson? extract(String html) {
    final lesson = DwLearnGerman.parseApolloState(html);
    if (lesson == null) return null;
    return EmbeddedLesson(
      title: 'DW Learn German: ${lesson.lessonName}',
      subtitleUrls: lesson.germanSubtitleUrls,
      vocabulary: lesson.vocabulary,
      grammar: lesson.grammar,
    );
  }
}

/// Any site with schema.org markup: `VideoObject`/`LearningResource`
/// transcripts and `<track kind="subtitles">` elements. Covers video
/// lesson pages, course platforms and publishers without site code.
class JsonLdLessonAdapter implements EmbeddedSiteAdapter {
  @override
  EmbeddedLesson? extract(String html) {
    String? title;
    final subtitleUrls = <String>[];

    // Subtitle tracks work with no JSON at all.
    for (final match in RegExp(
      '<track[^>]+>',
      caseSensitive: false,
    ).allMatches(html)) {
      final tag = match.group(0)!;
      if (!RegExp(
        'kind\\s*=\\s*["\']?subtitles',
        caseSensitive: false,
      ).hasMatch(tag)) {
        continue;
      }
      final src = RegExp(
        'src\\s*=\\s*["\']([^"\']+)',
        caseSensitive: false,
      ).firstMatch(tag)?.group(1);
      if (src != null && src.isNotEmpty) subtitleUrls.add(_absolute(src));
    }

    for (final match in RegExp(
      '<script[^>]*type\\s*=\\s*["\']application/ld\\+json["\'][^>]*>([\\s\\S]*?)</script>',
      caseSensitive: false,
    ).allMatches(html)) {
      dynamic decoded;
      try {
        decoded = jsonDecode(match.group(1)!);
      } catch (_) {
        continue;
      }
      final graphs = decoded is List
          ? decoded
          : (decoded is Map && decoded['@graph'] is List
                ? decoded['@graph'] as List
                : [decoded]);
      for (final node in graphs) {
        if (node is! Map) continue;
        final type = node['@type']?.toString() ?? '';
        if (!type.contains('VideoObject') &&
            !type.contains('LearningResource') &&
            !type.contains('Article') &&
            !type.contains('Course')) {
          continue;
        }
        title ??= node['name']?.toString() ?? node['headline']?.toString();
        final transcript = node['transcript']?.toString();
        if (transcript != null && transcript.trim().length > 60) {
          return EmbeddedLesson(
            title: (title ?? 'Web lesson').trim(),
            dialogue: DwLearnGerman.stripHtml(transcript),
          );
        }
      }
    }
    if (subtitleUrls.isEmpty) return null;
    return EmbeddedLesson(
      title: (title ?? 'Web lesson').trim(),
      subtitleUrls: subtitleUrls,
    );
  }

  String _absolute(String src) => src;
}
