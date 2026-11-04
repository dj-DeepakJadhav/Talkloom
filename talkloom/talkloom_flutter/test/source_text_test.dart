import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/features/content/source_text.dart';
import 'package:talkloom_flutter/features/content/content_widgets.dart';
import 'package:talkloom_client/talkloom_client.dart';

void main() {
  test('source display hides leaked subtitle styling but keeps dialogue', () {
    const source =
        '## Dialogue\n\ncolor: white;\nbackground-color: black;\nfont-size: 156%;\nline-height: normal;\nfont-family: Arial;\n}\n– Guten Morgen, Herr Müller.';
    final display = readableSourceText(source);
    expect(display, isNot(contains('font-family')));
    expect(display, contains('– Guten Morgen, Herr Müller.'));
    expect(source, contains('font-family'));
  });
  test('an untitled source gets a readable identity from its content', () {
    final source = Source(
      userId: 'test',
      type: 'text',
      title: ' ',
      rawText: '## Guten Morgen\nWie geht es Ihnen?',
      targetLanguage: 'de',
      cefrLevel: 'A2',
      createdAt: DateTime.utc(2026),
    );
    expect(sourceDisplayTitle(source), 'Guten Morgen');
  });
  test(
    'source display decodes escapes once without changing original evidence',
    () {
      const original =
          '## Vocabulary\n- sch&ouml;n: nice;&#160;pretty &#x1F44B;';
      expect(
        readableSourceText(original),
        '## Vocabulary\n- schön: nice; pretty 👋',
      );
      expect(original, contains('&#160;'));
      expect(readableSourceText('&amp;lt;'), '&lt;');
      expect(
        readableSourceText('&#99999999; &unknown; &#xD800;'),
        '&#99999999; &unknown; &#xD800;',
      );
    },
  );
}
