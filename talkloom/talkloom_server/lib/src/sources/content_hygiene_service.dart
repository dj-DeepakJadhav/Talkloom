/// Stored-content hygiene signatures.
///
/// Catches the junk that reader shells and half-stripped markup leave in
/// saved rows: subtitle CSS, raw HTML entities, photo-credit `null`s,
/// JavaScript-shell markers, and reader-proxy shells. Pure functions so the
/// maintenance loop, the import path and unit tests all share one
/// definition of "dirty".
abstract final class ContentHygieneService {
  /// Defect codes found in [text], or empty when it looks like real lesson
  /// content. Case-insensitive substring matching on purpose: these are
  /// machine-generated markers, not prose.
  static List<String> scanText(String text) {
    if (text.trim().isEmpty) return const ['empty'];
    final lower = text.toLowerCase();
    final defects = <String>[];

    // Subtitle CSS leaked into dialogue (VTT STYLE blocks).
    if (lower.contains('background-color:') ||
        (lower.contains('font-size:') && lower.contains('font-family:'))) {
      defects.add('subtitle_css');
    }
    // Undecoded entities.
    if (RegExp(r'&#\d+;').hasMatch(text) ||
        RegExp(r'&[a-zA-Z]+;').hasMatch(text)) {
      defects.add('html_entities');
    }
    // Photo credits with null authors, template leftovers.
    if (lower.contains('null dw') ||
        lower.contains('null/null') ||
        lower.contains('\${formatid}') ||
        lower.contains('placeholder-image')) {
      defects.add('template_junk');
    }
    // JavaScript shell instead of content.
    if (lower.contains('enable javascript to run this app') ||
        lower.contains('you need to enable javascript')) {
      defects.add('js_shell');
    }
    // Reader-proxy shell saved as if it were the lesson.
    if (lower.contains('url source:') && lower.contains('markdown content:')) {
      defects.add('reader_shell');
    }
    return defects;
  }

  /// True when [text] must never be compiled as-is.
  static bool isPoisoned(String text) {
    final defects = scanText(text);
    return defects.any(
      (d) => d == 'js_shell' || d == 'reader_shell' || d == 'empty',
    );
  }
}
