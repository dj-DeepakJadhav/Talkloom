import '../generated/protocol.dart';

/// Fails imports whose text contains no trace of the learner's target
/// language, before any AI credit is burned.
///
/// Heuristic on purpose: it runs before the (paid) compile step and must
/// never cost a model call. Short texts are always let through — the check
/// only fires on 300+ characters with zero language signals, which means
/// the learner pasted or linked content in another language. The client maps
/// `wrong_language` to a popup that suggests pasting matching text instead.
abstract final class TargetLanguageGuard {
  static const minCheckedLength = 300;
  static const minScore = 6;

  static const _signals = <String, ({String chars, List<String> words})>{
    'de': (
      chars: 'äöüß',
      words: [
        'der',
        'die',
        'das',
        'und',
        'ist',
        'ein',
        'eine',
        'nicht',
        'mit',
        'von',
        'den',
        'dem',
        'einen',
        'einem',
        'einer',
        'für',
        'auf',
        'aus',
        'wird',
        'werden',
        'sind',
        'haben',
        'auch',
        'sich',
        'dass',
      ],
    ),
    'fr': (
      chars: 'àâçéèêëîïôùû',
      words: [
        'les',
        'des',
        'une',
        'est',
        'dans',
        'pour',
        'avec',
        'pas',
        'vous',
        'nous',
        'ils',
        'elles',
        'sont',
        'font',
        'cette',
        'dans',
        'mais',
      ],
    ),
    'es': (
      chars: 'áéíóúñ¿¡',
      words: [
        'los',
        'las',
        'una',
        'está',
        'para',
        'con',
        'pero',
        'como',
        'más',
        'son',
        'tiene',
        'hasta',
        'desde',
        'porque',
        'entre',
        'sobre',
      ],
    ),
    'it': (
      chars: 'àèéìòù',
      words: [
        'che',
        'una',
        'sono',
        'come',
        'più',
        'della',
        'nella',
        'questo',
        'questa',
        'molto',
        'anche',
        'solo',
        'quando',
        'dove',
        'perché',
      ],
    ),
  };

  /// True for base64/data-URI media payloads, which carry no checkable text.
  static bool isOpaqueMedia(String raw) {
    final v = raw.trim();
    return v.startsWith('data:') ||
        (v.length > 500 && !v.contains(' ') && !v.contains('\n'));
  }

  /// True when [text] carries enough target-language signal to judge, or
  /// is too short/unknown to judge (same rules as [checkText], no throw).
  /// Used by extractors to decide whether page text is real content or
  /// just site chrome around spoken/on-screen material.
  static bool hasSignal({
    required String text,
    required String targetLanguage,
  }) {
    try {
      checkText(text: text, targetLanguage: targetLanguage);
      return true;
    } on ImportException {
      return false;
    }
  }

  /// Throws [ImportException] (`wrong_language`) when [text] is long enough
  /// to judge and shows no signal of [targetLanguage]. Unknown languages
  /// and short texts pass through unchecked.
  static void checkText({
    required String text,
    required String targetLanguage,
  }) {
    final lang = targetLanguage
        .trim()
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;
    final signals = _signals[lang];
    if (signals == null) return;
    final trimmed = text.trim();
    if (trimmed.length < minCheckedLength) return;

    final lower = trimmed.toLowerCase();
    var score = 0;
    for (var i = 0; i < lower.length; i++) {
      if (signals.chars.contains(lower[i])) score += 3;
    }
    for (final word in signals.words) {
      if (RegExp(
        '(^|[^\\p{L}])${RegExp.escape(word)}([\$]|[^\\p{L}])',
        unicode: true,
      ).hasMatch(lower)) {
        score += 1;
      }
      if (score >= minScore) return;
    }
    throw ImportException(
      code: 'wrong_language',
      message:
          'This source does not look like ${targetLanguage.toUpperCase()} content. '
          'Talkloom teaches from material in the language you are learning. '
          'Check the link, or paste ${targetLanguage.toUpperCase()} text instead.',
    );
  }
}
