import 'package:test/test.dart';
import 'package:talkloom_server/src/services/embedded_lesson_resolver.dart';

const _dwHtml = '''
<html><body>
<script>window.__APOLLO_STATE__={"Lesson:1":{"name":"Hallo!"},"Video:2":{"subtitles":[{"srcLanguage":"de","language":"GERMAN","subtitleUrl":"https://example.com/s.vtt"}]},"Knowledge:3":{"knowledgeType":"VOCABULARY","name":"auch","text":"<p>also</p>"}}};</script>
</body></html>
''';

const _vtt = '''WEBVTT

1
00:00:01.000 --> 00:00:04.000
– Guten Morgen, Herr Müller, wie geht es Ihnen heute?

2
00:00:04.200 --> 00:00:07.000
– Danke, sehr gut! Und Ihnen, Frau Schneider?

3
00:00:07.200 --> 00:00:10.000
– Auch gut, danke. Gehen wir einen Kaffee trinken?
''';
const _trackHtml = '''
<html><head><title>Leçon</title>
<script type="application/ld+json">{"@type":"VideoObject","name":"Bonjour","transcript":"Guten Tag, wie geht es Ihnen heute? Wir lernen zusammen Deutsch und üben die Aussprache jeden Morgen."}</script>
</head><body>shell</body></html>
''';

void main() {
  group('EmbeddedLessonResolver', () {
    test('DW page resolves through the DW adapter', () async {
      final text = await EmbeddedLessonResolver.resolveFromHtml(
        html: _dwHtml,
        fetchText: (_) async => _vtt,
      );
      expect(text, isNotNull);
      expect(text!, contains('Hallo!'));
      expect(text, contains('Guten Morgen, Herr Müller'));
      expect(text, contains('auch'));
    });

    test('JSON-LD transcript resolves without site code', () async {
      var fetched = false;
      final text = await EmbeddedLessonResolver.resolveFromHtml(
        html: _trackHtml,
        fetchText: (_) async {
          fetched = true;
          return null;
        },
      );
      expect(text, isNotNull);
      expect(text!, contains('Guten Tag'));
      expect(fetched, isFalse);
    });

    test('plain shell returns null for fallthrough', () async {
      final text = await EmbeddedLessonResolver.resolveFromHtml(
        html: '<html><body>Just a shell page</body></html>',
        fetchText: (_) async => null,
      );
      expect(text, isNull);
    });
  });
}
