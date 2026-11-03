import 'package:test/test.dart';
import 'package:talkloom_server/src/services/ingestion_service.dart';

void main() {
  test('manual target captions have a plain header', () {
    expect(
      youTubeCaptionHeader(
        title: 'T',
        author: 'A',
        language: 'de',
        isGenerated: false,
      ),
      '[YouTube Video: T by A | captions: de, manual]',
    );
  });

  test('auto-generated German has no warning', () {
    expect(
      youTubeCaptionHeader(
        title: 'T',
        author: 'A',
        language: 'de',
        isGenerated: true,
      ),
      '[YouTube Video: T by A | captions: de, auto-generated]',
    );
  });

  test('auto-generated English warns about misheard German', () {
    final header = youTubeCaptionHeader(
      title: 'T',
      author: 'A',
      language: 'en',
      isGenerated: true,
    );
    expect(header, contains('captions: en, auto-generated'));
    expect(header, contains('machine-generated in another language'));
    expect(header, contains('misheard'));
  });

  test('missing language keeps the legacy header', () {
    expect(
      youTubeCaptionHeader(title: 'T', author: 'A'),
      '[YouTube Video: T by A]',
    );
  });
}
