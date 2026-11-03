import 'dart:convert';

/// Parsers for DW Learn German (`learngerman.dw.com`).
///
/// Those pages are client-rendered: the static HTML carries an English nav
/// shell, while the German lesson lives in the embedded
/// `window.__APOLLO_STATE__` JSON (Video entries link German subtitle files,
/// Knowledge entries carry vocabulary and grammar). Pure functions so they
/// can be unit-tested without network access.
abstract final class DwLearnGerman {
  /// Lesson data pulled from the embedded Apollo state, or null when the
  /// page has none (wrong page kind or changed markup).
  static DwLesson? parseApolloState(String html) {
    final start = html.indexOf('window.__APOLLO_STATE__=');
    if (start < 0) return null;
    final jsonStart = html.indexOf('{', start);
    if (jsonStart < 0) return null;
    final raw = _balancedJson(html, jsonStart);
    if (raw == null) return null;
    Map<String, dynamic> state;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      state = decoded;
    } catch (_) {
      return null;
    }

    String lessonName = 'DW Learn German';
    final subtitleUrls = <String>[];
    final vocabulary = <(String, String)>[];
    final grammar = <(String, String)>[];

    for (final entry in state.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      final key = entry.key;
      if (key.startsWith('Lesson:')) {
        final name = value['name']?.toString().trim();
        if (name != null && name.isNotEmpty) lessonName = name;
      } else if (key.startsWith('Video:')) {
        final subtitles = value['subtitles'];
        if (subtitles is List) {
          for (final sub in subtitles.whereType<Map>()) {
            final srcLang = sub['srcLanguage']?.toString().toLowerCase() ?? '';
            final lang = sub['language']?.toString().toUpperCase() ?? '';
            final url = sub['subtitleUrl']?.toString() ?? '';
            if (url.isNotEmpty &&
                (srcLang == 'de' || srcLang == 'ger' || lang == 'GERMAN')) {
              subtitleUrls.add(url);
            }
          }
        }
      } else if (key.startsWith('Knowledge:')) {
        final type = value['knowledgeType']?.toString().toUpperCase() ?? '';
        final title = (value['shortTitle'] ?? value['name'] ?? '')
            .toString()
            .trim();
        final text = stripHtml(value['text']?.toString() ?? '');
        if (title.isEmpty || text.isEmpty) continue;
        if (type == 'VOCABULARY') {
          vocabulary.add((title, text));
        } else if (type == 'GRAMMAR') {
          grammar.add((title, text));
        }
      }
    }
    if (subtitleUrls.isEmpty && vocabulary.isEmpty && grammar.isEmpty) {
      return null;
    }
    return DwLesson(
      lessonName: lessonName,
      germanSubtitleUrls: subtitleUrls,
      vocabulary: vocabulary,
      grammar: grammar,
    );
  }

  /// `window.__APOLLO_STATE__=` is followed by one JSON object; scan the
  /// balanced braces so later `<script>` blocks cannot corrupt the parse.
  /// Strings (with escapes) are skipped while counting.
  static String? _balancedJson(String html, int start) {
    var depth = 0;
    var inString = false;
    var escape = false;
    for (var i = start; i < html.length; i++) {
      final c = html[i];
      if (inString) {
        if (escape) {
          escape = false;
        } else if (c == '\\') {
          escape = true;
        } else if (c == '"') {
          inString = false;
        }
        continue;
      }
      if (c == '"') {
        inString = true;
      } else if (c == '{') {
        depth++;
      } else if (c == '}') {
        depth--;
        if (depth == 0) return html.substring(start, i + 1);
      }
    }
    return null;
  }

  /// WEBVTT (or SRT-ish) cue text as plain dialogue lines, in order.
  /// Cue numbers, timestamps, styling and voice tags are dropped;
  /// consecutive repeated drill lines collapse to one.
  static String parseVtt(String vtt) {
    final lines = <String>[];
    var skipBlock = false;
    for (final raw in const LineSplitter().convert(vtt)) {
      final line = raw.trim();
      if (line.isEmpty) {
        skipBlock = false;
        continue;
      }
      final upper = line.toUpperCase();
      if (upper == 'WEBVTT') continue;
      // STYLE/NOTE/REGION blocks run to the next blank line; only their
      // first line is recognizable, so swallow the whole block.
      if (upper.startsWith('STYLE') ||
          upper.startsWith('NOTE') ||
          upper.startsWith('REGION')) {
        skipBlock = true;
        continue;
      }
      if (skipBlock) continue;
      if (line.contains('-->')) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (line.startsWith('::')) continue;
      // Stray CSS braces from malformed blocks.
      if (line == '{' || line == '}') continue;
      final text = stripHtml(line);
      if (text.isEmpty) continue;
      // A dialogue line carries words; CSS leftovers do not.
      if (!RegExp(r'\p{L}', unicode: true).hasMatch(text)) continue;
      if (lines.isNotEmpty && lines.last == text) continue;
      lines.add(text);
    }
    return lines.join('\n');
  }

  /// HTML to plain text. Figures carry photos, not lesson content, so the
  /// whole block goes (including `null DW`-style empty photo credits).
  /// Numeric (`&#160;`) and common named entities are decoded; anything
  /// unknown is dropped rather than leaked as `&...;` into lesson text.
  static String stripHtml(String html) {
    return html
        .replaceAll(
          RegExp('<figure[\\s>][\\s\\S]*?</figure>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(
            '<figcaption[\\s>][\\s\\S]*?</figcaption>',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp('<(script|style)[\\s>][\\s\\S]*?</\\1>', caseSensitive: false),
          ' ',
        )
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) {
            final code = int.tryParse(m.group(1)!);
            if (code == null || code == 160) return ' ';
            try {
              return String.fromCharCode(code);
            } catch (_) {
              return ' ';
            }
          },
        )
        .replaceAll(RegExp(r'&#x([0-9a-fA-F]+);'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'\s+([.,;:!?])'), (m) => m.group(1)!)
        .trim();
  }
}

/// German lesson content of one DW page.
class DwLesson {
  DwLesson({
    required this.lessonName,
    required this.germanSubtitleUrls,
    required this.vocabulary,
    required this.grammar,
  });

  final String lessonName;
  final List<String> germanSubtitleUrls;

  /// (word, explanation) pairs.
  final List<(String, String)> vocabulary;

  /// (title, explanation) pairs.
  final List<(String, String)> grammar;
}
