import 'package:test/test.dart';
import 'package:talkloom_server/src/services/dw_learn_german.dart';

const _apolloHtml = '''
<html><head><title>Hallo! | Nicos Weg</title></head><body>
<div>shell</div>
<script>window.__APOLLO_STATE__={"Lesson:37250531":{"__typename":"Lesson","id":37250531,"name":"Hallo!"},"Video:38052231":{"__typename":"Video","subtitles":[{"__typename":"SimpleResourceLink","srcLanguage":"de","language":"GERMAN","subtitleUrl":"https://www.dw.com/media/subtitles/69977685"}]},"Knowledge:1":{"__typename":"Knowledge","knowledgeType":"VOCABULARY","name":"auch","shortTitle":"auch","text":"<p>also</p>"},"Knowledge:2":{"__typename":"Knowledge","knowledgeType":"GRAMMAR","shortTitle":"Formal address","text":"<p>Use <strong>Sie</strong>.</p>"}};</script>
<script>var other = {};</script>
</body></html>
''';

const _vtt = '''WEBVTT

STYLE
::cue(.S1) { color: white; }

1
00:00:10.480 --> 00:00:13.040 align:center
<c.S1>– Guten Morgen, Herr Müller,
wie geht es Ihnen?</c>

2
00:00:13.120 --> 00:00:17.760 align:center
– Guten Morgen, Frau Schneider.

3
00:00:17.840 --> 00:00:20.480 align:center
– Guten Morgen, Frau Schneider.
''';

void main() {
  group('DwLearnGerman.parseApolloState', () {
    test('extracts lesson, subtitles, vocab and grammar', () {
      final lesson = DwLearnGerman.parseApolloState(_apolloHtml);
      expect(lesson, isNotNull);
      expect(lesson!.lessonName, 'Hallo!');
      expect(lesson.germanSubtitleUrls, [
        'https://www.dw.com/media/subtitles/69977685',
      ]);
      expect(lesson.vocabulary, [('auch', 'also')]);
      expect(lesson.grammar, [('Formal address', 'Use Sie.')]);
    });

    test('returns null without apollo state', () {
      expect(DwLearnGerman.parseApolloState('<html></html>'), isNull);
    });

    test('returns null when no German content found', () {
      final html =
          '<script>window.__APOLLO_STATE__='
          '{"Lesson:1":{"name":"X"}};</script>';
      expect(DwLearnGerman.parseApolloState(html), isNull);
    });
  });

  group('DwLearnGerman.parseVtt', () {
    test('keeps dialogue, drops cues and tags', () {
      final dialogue = DwLearnGerman.parseVtt(_vtt);
      expect(dialogue, contains('Guten Morgen, Herr Müller,'));
      expect(dialogue, contains('Guten Morgen, Frau Schneider.'));
      expect(dialogue.contains('-->'), isFalse);
      expect(dialogue.contains('<c.S1>'), isFalse);
      // Consecutive drill repetition collapses.
      expect('Guten Morgen, Frau Schneider.'.allMatches(dialogue).length, 1);
    });
  });
}
