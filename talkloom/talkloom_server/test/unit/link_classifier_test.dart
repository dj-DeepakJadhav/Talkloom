import 'package:talkloom_server/src/sources/link_classifier.dart';
import 'package:test/test.dart';

void main() {
  group('LinkClassifier', () {
    test('reads the channel from the YouTube caption header', () {
      final c = LinkClassifier.classify(
        'https://www.youtube.com/watch?v=abc',
        transcript:
            '[YouTube Video: Ein Tag in Berlin by DW Deutsch | captions: de, manual]\nHallo',
      );
      expect(c.platform, LinkPlatform.youtube);
      expect(c.creator, 'DW Deutsch');
      expect(c.creatorKey, 'dw deutsch');
      expect(c.timeToLive, isNull);
    });

    test('takes the creator from the link on social platforms', () {
      expect(
        LinkClassifier.classify(
          'https://www.tiktok.com/@deutschmitanna/video/1',
        ).creator,
        'deutschmitanna',
      );
      expect(
        LinkClassifier.classify(
          'https://www.reddit.com/r/German/comments/x/y/',
        ).creator,
        'r/German',
      );
      expect(
        LinkClassifier.classify(
          'https://www.instagram.com/learngermanwith/reel/z/',
        ).creator,
        'learngermanwith',
      );
      expect(
        LinkClassifier.classify('https://www.instagram.com/reel/z/').creator,
        isNull,
      );
    });

    test('files anything else under web with the site as creator', () {
      final c = LinkClassifier.classify('https://www.dw.com/de/thema/a-1');
      expect(c.platform, LinkPlatform.web);
      expect(c.creator, 'dw.com');
      expect(c.timeToLive, const Duration(days: 30));
    });

    test('does not mistake look-alike hosts for a platform', () {
      expect(
        LinkClassifier.classify('https://notyoutube.com/watch?v=1').platform,
        LinkPlatform.web,
      );
    });

    test('spots profile pages that hold no single lesson', () {
      expect(
        LinkClassifier.profileAccount('https://www.instagram.com/nicosweg/'),
        'nicosweg',
      );
      expect(
        LinkClassifier.profileAccount('https://www.tiktok.com/@nicosweg'),
        'nicosweg',
      );
      expect(
        LinkClassifier.profileAccount('https://x.com/nicosweg'),
        'nicosweg',
      );
    });

    test('does not flag reels and posts as profiles', () {
      expect(
        LinkClassifier.profileAccount(
          'https://www.instagram.com/reel/ABC123/?igsh=xyz',
        ),
        isNull,
      );
      expect(
        LinkClassifier.profileAccount('https://www.instagram.com/p/ABC123/'),
        isNull,
      );
      expect(
        LinkClassifier.profileAccount(
          'https://www.tiktok.com/@nicosweg/video/123',
        ),
        isNull,
      );
    });
  });
}
