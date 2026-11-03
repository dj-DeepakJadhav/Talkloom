import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/content/content_widgets.dart';

Source _src({String? url, String type = 'url', String raw = ''}) => Source(
  id: 1,
  userId: 'u',
  type: type,
  url: url,
  title: 'A very long title that should wrap nicely across several lines ok',
  rawText: raw,
  targetLanguage: 'de',
  cefrLevel: 'A2',
  createdAt: DateTime.utc(2026, 10, 5),
);

void main() {
  group('sourceKind', () {
    final cases = <String?, SourceKind>{
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ': SourceKind.youtubeVideo,
      'https://m.youtube.com/watch?v=dQw4w9WgXcQ': SourceKind.youtubeVideo,
      'https://youtu.be/dQw4w9WgXcQ': SourceKind.youtubeVideo,
      'https://www.youtube.com/shorts/dQw4w9WgXcQ': SourceKind.youtubeShort,
      'https://www.tiktok.com/@a/video/1': SourceKind.tiktok,
      'https://vm.tiktok.com/ZM123/': SourceKind.tiktok,
      'https://vt.tiktok.com/ZS123/': SourceKind.tiktok,
      'https://www.instagram.com/reel/abc/': SourceKind.instagram,
      'https://instagram.com/p/abc/': SourceKind.instagram,
      'https://www.instagram.com/tv/abc/': SourceKind.instagram,
      'https://instagr.am/p/abc': SourceKind.instagram,
      'https://www.spiegel.de/a/b': SourceKind.article,
      'https://notyoutube.com/shorts/x': SourceKind.article,
      'https://example.com/youtube.com': SourceKind.article,
    };
    cases.forEach((url, kind) {
      test('$url -> $kind', () => expect(sourceKind(_src(url: url)), kind));
    });
    test('null url: text / file', () {
      expect(sourceKind(_src(type: 'text')), SourceKind.text);
      expect(sourceKind(_src(type: 'file')), SourceKind.file);
    });
    test('malformed urls fall back to type', () {
      expect(
        sourceKind(_src(url: 'http://[bad', type: 'text')),
        SourceKind.text,
      );
      expect(sourceKind(_src(url: 'not a url', type: 'file')), SourceKind.file);
      expect(sourceKind(_src(url: '', type: 'text')), SourceKind.text);
    });
    test('platform labels', () {
      expect(sourcePlatform(_src(url: 'https://vm.tiktok.com/x')), 'TikTok');
      expect(sourcePlatform(_src(url: 'https://instagr.am/p/x')), 'Instagram');
      expect(sourcePlatform(_src(url: 'https://youtu.be/x')), 'YouTube');
      expect(
        sourcePlatform(_src(url: 'https://www.spiegel.de/a')),
        'spiegel.de',
      );
      expect(sourcePlatform(_src(type: 'text')), 'Your text');
      expect(sourcePlatform(_src(type: 'file')), 'Your upload');
    });
    test('excerpt', () {
      expect(sourceExcerpt(_src(raw: '')), contains('very long title'));
      expect(
        sourceExcerpt(_src(raw: 'a ' * 200)).length,
        lessThanOrEqualTo(91),
      );
    });
  });

  final fixtures = <String, Source>{
    'video': _src(url: 'https://youtu.be/dQw4w9WgXcQ'),
    'short': _src(url: 'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
    'tiktok': _src(url: 'https://vm.tiktok.com/ZM123/', raw: 'Hallo ' * 60),
    'instagram': _src(url: 'https://instagr.am/p/abc'),
    'article': _src(url: 'https://www.a-very-long-news-site-name.example.de/x'),
    'text': _src(type: 'text', raw: 'Ich hätte gern einen Kaffee. ' * 20),
    'file': _src(type: 'file'),
  };

  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5]) {
      for (final compact in [false, true]) {
        for (final e in fixtures.entries) {
          testWidgets('${e.key} w=$width x$scale compact=$compact', (t) async {
            t.view.physicalSize = Size(width, 900);
            t.view.devicePixelRatio = 1;
            addTearDown(t.view.reset);
            await t.pumpWidget(
              MaterialApp(
                theme: buildTalkloomTheme(Brightness.light),
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(c).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: Scaffold(
                  body: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: SourceArtwork(
                        source: e.value,
                        height: compact ? 110 : 170,
                        compact: compact,
                      ),
                    ),
                  ),
                ),
              ),
            );
            await t.pump();
            expect(t.takeException(), isNull);
            expect(find.byType(SourceArtwork), findsOneWidget);
          });
        }
      }
    }
  }
}
