import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/meta_image_service.dart';

Uint8List createMockPng() {
  final bytes = Uint8List(16);
  bytes[0] = 0x89;
  bytes[1] = 0x50;
  bytes[2] = 0x4E;
  bytes[3] = 0x47;
  bytes[4] = 0x0D;
  bytes[5] = 0x0A;
  bytes[6] = 0x1A;
  bytes[7] = 0x0A;
  return bytes;
}

void main() {
  group('MetaImageService house style', () {
    test('style prompt locks palette, outlines, and no-text rule', () {
      final prompt = MetaImageService.stylePrompt('an apple');
      expect(prompt, contains('#30251D'));
      expect(prompt, contains('#FFFCF5'));
      expect(prompt, contains('no text'));
      expect(prompt, contains('an apple'));
      expect(prompt, isNot(contains('photorealistic')));
    });

    test('validates subject input and API key', () async {
      final noKey = MetaImageService(apiKey: '');
      await expectLater(noKey.illustrate('Apfel'), throwsStateError);

      final service = MetaImageService(apiKey: 'test-key');
      await expectLater(service.illustrate(''), throwsArgumentError);
      await expectLater(
        service.illustrate('a' * 201),
        throwsArgumentError,
      );
    });

    test(
      'posts the style-locked prompt to the Meta images endpoint',
      () async {
        final png = createMockPng();
        late Uri requestUrl;
        late Map<String, dynamic> requestBody;
        final tempDir = await Directory.systemTemp.createTemp(
          'image_prompt_test_',
        );
        try {
          final service = MetaImageService(
            apiKey: 'meta-test-key',
            cacheDirectory: tempDir,
            client: MockClient((request) async {
              requestUrl = request.url;
              requestBody = jsonDecode(request.body) as Map<String, dynamic>;
              return http.Response(
                jsonEncode({
                  'data': [
                    {'b64_json': base64Encode(png)},
                  ],
                }),
                200,
              );
            }),
          );

          final bytes = await service.illustrate('Apfel');

          expect(bytes, equals(png));
          expect(requestUrl.host, 'api.meta.ai');
          expect(requestUrl.path, '/v1/images/generations');
          expect(requestBody['model'], 'muse-image-1.0');
          expect(requestBody['size'], '1024x1024');
          expect(
            requestBody['prompt'] as String,
            contains('no text'),
          );
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('serves repeated subjects from disk cache', () async {
      final png = createMockPng();
      var calls = 0;
      final tempDir = await Directory.systemTemp.createTemp(
        'image_cache_test_',
      );
      try {
        final service = MetaImageService(
          apiKey: 'meta-test-key',
          cacheDirectory: tempDir,
          client: MockClient((_) async {
            calls++;
            return http.Response(
              jsonEncode({
                'data': [
                  {'b64_json': base64Encode(png)},
                ],
              }),
              200,
            );
          }),
        );

        final first = await service.illustrate('Apfel');
        final second = await service.illustrate('Apfel');

        expect(first, equals(png));
        expect(second, equals(png));
        expect(calls, 1);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
