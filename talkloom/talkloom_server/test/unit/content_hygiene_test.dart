import 'package:test/test.dart';
import 'package:talkloom_server/src/services/dw_learn_german.dart';
import 'package:talkloom_server/src/sources/content_hygiene_service.dart';

const _styledVtt = '''WEBVTT

STYLE
::cue(.S1) {
color: white;
background-color: black;
font-size: 156%;
line-height: normal;
font-family: Arial;
}

1
00:00:10.480 --> 00:00:13.040 align:center
<c.S1>Guten Morgen, Herr Müller</c>

2
00:00:13.120 --> 00:00:17.760 align:center
Danke, gut!
''';

void main() {
  group('VTT style blocks', () {
    test('drops the whole STYLE block, keeps dialogue', () {
      final dialogue = DwLearnGerman.parseVtt(_styledVtt);
      expect(dialogue, contains('Guten Morgen, Herr Müller'));
      expect(dialogue, contains('Danke, gut!'));
      expect(dialogue.contains('background-color'), isFalse);
      expect(dialogue.contains('font-size'), isFalse);
      expect(dialogue.contains('}'), isFalse);
    });
  });

  group('stripHtml', () {
    test('decodes numeric entities', () {
      expect(
        DwLearnGerman.stripHtml('<p>well;&#160;good</p>'),
        'well; good',
      );
      expect(
        DwLearnGerman.stripHtml('dir?&#160;(informal)'),
        'dir? (informal)',
      );
    });

    test('removes figures including null credits', () {
      expect(
        DwLearnGerman.stripHtml(
          '<p>Hi!</p><figure><img alt="x"><figcaption><small>null DW</small></figcaption></figure><p>Bye.</p>',
        ),
        contains('Hi!'),
      );
      final clean = DwLearnGerman.stripHtml(
        '<figure><figcaption><small>null DW</small></figcaption></figure>',
      );
      expect(clean.contains('null DW'), isFalse);
    });
  });

  group('ContentHygieneService', () {
    test('flags the production defects', () {
      expect(
        ContentHygieneService.scanText(
          'color: white; background-color: black;',
        ),
        contains('subtitle_css'),
      );
      expect(
        ContentHygieneService.scanText('well;&#160;good'),
        contains('html_entities'),
      );
      expect(
        ContentHygieneService.scanText('Informal forms null DW Hey'),
        contains('template_junk'),
      );
      expect(
        ContentHygieneService.scanText(
          'Title: X URL Source: y Markdown Content: z',
        ),
        contains('reader_shell'),
      );
      expect(
        ContentHygieneService.scanText(
          'You need to enable JavaScript to run this app',
        ),
        contains('js_shell'),
      );
    });

    test('clean German passes', () {
      expect(
        ContentHygieneService.scanText(
          'Guten Morgen, Herr Müller, wie geht es Ihnen?',
        ),
        isEmpty,
      );
      expect(
        ContentHygieneService.isPoisoned('Guten Morgen!'),
        isFalse,
      );
    });

    test('shells are poisoned', () {
      expect(
        ContentHygieneService.isPoisoned(
          'Title: Hallo! URL Source: x Markdown Content: Learn German',
        ),
        isTrue,
      );
    });
  });
}
