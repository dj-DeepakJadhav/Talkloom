import 'package:flutter/foundation.dart';

/// A language Talkloom can teach or explain in.
///
/// The backend is language-agnostic — `targetLanguage` is a parameter on every
/// endpoint and `LearnerState` is keyed on (user, language). This catalogue is
/// what lets the client stop assuming German.
@immutable
class Language {
  const Language({
    required this.code,
    required this.englishName,
    required this.endonym,
    required this.flag,
    this.isRightToLeft = false,
  });

  /// ISO 639-1 code, used as `targetLanguage` / `supportLanguage` on the wire.
  final String code;

  /// Name in English, for support-language pickers.
  final String englishName;

  /// The language's name in itself — shown as the primary label because that
  /// is how learners recognise their own language.
  final String endonym;

  final String flag;
  final bool isRightToLeft;

  @override
  bool operator ==(Object other) => other is Language && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

abstract final class LanguageCatalog {
  static const all = <Language>[
    Language(
      code: 'de',
      englishName: 'German',
      endonym: 'Deutsch',
      flag: '🇩🇪',
    ),
    Language(
      code: 'es',
      englishName: 'Spanish',
      endonym: 'Español',
      flag: '🇪🇸',
    ),
    Language(
      code: 'fr',
      englishName: 'French',
      endonym: 'Français',
      flag: '🇫🇷',
    ),
    Language(
      code: 'it',
      englishName: 'Italian',
      endonym: 'Italiano',
      flag: '🇮🇹',
    ),
    Language(
      code: 'pt',
      englishName: 'Portuguese',
      endonym: 'Português',
      flag: '🇵🇹',
    ),
    Language(
      code: 'nl',
      englishName: 'Dutch',
      endonym: 'Nederlands',
      flag: '🇳🇱',
    ),
    Language(
      code: 'pl',
      englishName: 'Polish',
      endonym: 'Polski',
      flag: '🇵🇱',
    ),
    Language(
      code: 'sv',
      englishName: 'Swedish',
      endonym: 'Svenska',
      flag: '🇸🇪',
    ),
    Language(
      code: 'tr',
      englishName: 'Turkish',
      endonym: 'Türkçe',
      flag: '🇹🇷',
    ),
    Language(code: 'ja', englishName: 'Japanese', endonym: '日本語', flag: '🇯🇵'),
    Language(code: 'ko', englishName: 'Korean', endonym: '한국어', flag: '🇰🇷'),
    Language(code: 'zh', englishName: 'Chinese', endonym: '中文', flag: '🇨🇳'),
    Language(code: 'hi', englishName: 'Hindi', endonym: 'हिन्दी', flag: '🇮🇳'),
    Language(
      code: 'en',
      englishName: 'English',
      endonym: 'English',
      flag: '🇬🇧',
    ),
    Language(
      code: 'ar',
      englishName: 'Arabic',
      endonym: 'العربية',
      flag: '🇸🇦',
      isRightToLeft: true,
    ),
    Language(
      code: 'he',
      englishName: 'Hebrew',
      endonym: 'עברית',
      flag: '🇮🇱',
      isRightToLeft: true,
    ),
  ];

  static Language byCode(String code) {
    return all.firstWhere(
      (language) => language.code == code,
      orElse: () => all.first,
    );
  }
}

/// CEFR proficiency, used to scale generated lessons.
enum CefrLevel {
  a1('A1', 'Just starting'),
  a2('A2', 'Basic phrases'),
  b1('B1', 'Everyday conversation'),
  b2('B2', 'Comfortable and fluent'),
  c1('C1', 'Advanced');

  const CefrLevel(this.code, this.description);

  final String code;
  final String description;

  static CefrLevel fromCode(String code) {
    return CefrLevel.values.firstWhere(
      (level) => level.code.toLowerCase() == code.toLowerCase(),
      orElse: () => CefrLevel.b1,
    );
  }
}
