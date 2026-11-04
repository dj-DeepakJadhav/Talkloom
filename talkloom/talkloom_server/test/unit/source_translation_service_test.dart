import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/source_translation_service.dart';

void main() {
  test('cleans the screenshot subtitle CSS while preserving dialogue', () {
    const raw = '''## Dialogue

color: white;
background-color: black;
font-size: 156%;
line-height: normal;
font-family: Arial;
}
– Guten Morgen, Herr Müller,
wie geht es Ihnen?
– Danke, gut!''';
    final clean = sourceReadingText(raw);
    expect(clean, isNot(contains('font-size')));
    expect(clean, isNot(contains('color:')));
    expect(clean, contains('– Guten Morgen, Herr Müller,\nwie geht es Ihnen?'));
    expect(raw, contains('font-size'));
  });

  test(
    'segments lines and paragraphs without dropping long source content',
    () {
      const source = 'Guten Morgen.\nWie geht es Ihnen?\n\nDanke, gut!';
      expect(sourceReadingSegments(source, 'line'), hasLength(3));
      expect(sourceReadingSegments(source, 'paragraph'), hasLength(2));
      expect(sourceReadingSegments(source, 'complete'), hasLength(2));
      final long = List.filled(12000, 'Wort').join(' ');
      expect(sourceReadingSegments(long, 'complete').join(' '), long);
      expect(
        () => sourceReadingSegments(source, 'unknown'),
        throwsArgumentError,
      );
    },
  );

  test('decodes source escapes exactly once', () {
    expect(
      sourceReadingText('sch&ouml;n;&#160;pretty &#x1F44B; &amp;lt;'),
      'schön; pretty 👋 &lt;',
    );
  });

  test(
    'translation stays aligned even if provider reorders segments',
    () async {
      late Map<String, dynamic> sent;
      final service = SourceTranslationService(
        apiKey: 'test',
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.url.host, 'api.meta.ai');
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'segments': [
                        {'id': 1, 'translation': 'Thank you!'},
                        {'id': 0, 'translation': 'Good morning.'},
                      ],
                    }),
                  },
                },
              ],
            }),
            200,
          );
        }),
      );
      expect(await service.translate(['Guten Morgen.', 'Danke!'], 'en-GB'), [
        'Good morning.',
        'Thank you!',
      ]);
      expect(sent['model'], 'muse-spark-1.3');
      final messages = sent['messages'] as List;
      expect(messages.first['content'], contains('untrusted quoted data'));
      expect(
        jsonDecode(messages.last['content'])['segments'][0]['original'],
        'Guten Morgen.',
      );
    },
  );

  for (final broken in [
    [
      {'id': 0, 'translation': 'Hello'},
    ],
    [
      {'id': 0, 'translation': 'Hello'},
      {'id': 0, 'translation': 'Hi'},
    ],
    [
      {'id': 0, 'translation': ''},
      {'id': 1, 'translation': 'Thanks'},
    ],
    [
      {'id': 0, 'translation': 'Hello'},
      {'id': 5, 'translation': 'Thanks'},
    ],
  ]) {
    test(
      'rejects missing, duplicate, empty or foreign segment ids: $broken',
      () async {
        final service = SourceTranslationService(
          apiKey: 'test',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {
                      'content': jsonEncode({'segments': broken}),
                    },
                  },
                ],
              }),
              200,
            ),
          ),
        );
        await expectLater(
          service.translate(['Hallo', 'Danke'], 'en'),
          throwsStateError,
        );
      },
    );
  }

  test('missing configuration never manufactures translations', () async {
    final service = SourceTranslationService(apiKey: '');
    addTearDown(service.close);
    await expectLater(service.translate(['Hallo'], 'en'), throwsStateError);
  });
}
