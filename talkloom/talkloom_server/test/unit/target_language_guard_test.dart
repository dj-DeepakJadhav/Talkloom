import 'package:test/test.dart';
import 'package:talkloom_server/src/sources/target_language_guard.dart';

void main() {
  group('TargetLanguageGuard', () {
    test('long German text passes for de', () {
      final text = List.filled(
        20,
        'Der Unterricht beginnt heute. Die Schüler lernen Deutsch, '
        'denn die Sprache ist wichtig für das Studium und die Arbeit. ',
      ).join();
      expect(
        () => TargetLanguageGuard.checkText(text: text, targetLanguage: 'de'),
        returnsNormally,
      );
    });

    test('long English text fails for de with wrong_language', () {
      final text = List.filled(
        20,
        'The lesson starts today. Students learn languages because studying '
        'is important for university and future work in many countries. ',
      ).join();
      expect(
        () => TargetLanguageGuard.checkText(text: text, targetLanguage: 'de'),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('wrong_language') ||
                (e as dynamic).code == 'wrong_language',
          ),
        ),
      );
    });

    test('short texts always pass (no false positives)', () {
      expect(
        () => TargetLanguageGuard.checkText(
          text: 'Hello world',
          targetLanguage: 'de',
        ),
        returnsNormally,
      );
    });

    test('opaque media payloads are detected', () {
      expect(
        TargetLanguageGuard.isOpaqueMedia('data:image/png;base64,AAA'),
        isTrue,
      );
      expect(TargetLanguageGuard.isOpaqueMedia('normal pasted text'), isFalse);
    });
  });
}
