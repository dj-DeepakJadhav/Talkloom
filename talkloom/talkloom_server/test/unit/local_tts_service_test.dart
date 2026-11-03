import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/local_tts_service.dart';

Uint8List createMockWav({int dataLength = 44100}) {
  final header = Uint8List(44 + dataLength);
  final byteData = ByteData.sublistView(header);
  header.setRange(0, 4, ascii.encode('RIFF'));
  byteData.setUint32(4, 36 + dataLength, Endian.little);
  header.setRange(8, 12, ascii.encode('WAVE'));
  header.setRange(12, 16, ascii.encode('fmt '));
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little);
  byteData.setUint16(22, 1, Endian.little);
  byteData.setUint32(24, 22050, Endian.little);
  byteData.setUint32(28, 44100, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  header.setRange(36, 40, ascii.encode('data'));
  byteData.setUint32(40, dataLength, Endian.little);
  return header;
}

void main() {
  group('LocalTtsService (open-voice worker)', () {
    test('posts text, language and voice to the worker', () async {
      final mockAudio = createMockWav();
      late Uri requestUrl;
      late Map<String, dynamic> requestBody;
      final service = LocalTtsService(
        worker: Uri.parse('http://voice:8131/synthesize'),
        client: MockClient((request) async {
          requestUrl = request.url;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response.bytes(mockAudio, 200);
        }),
      );

      final result = await service.synthesize(
        'Guten Tag',
        'de',
        voice: 'de-ramona-f',
      );

      expect(result.audio, equals(mockAudio));
      expect(result.voice, 'de-ramona-f');
      expect(requestUrl.host, 'voice');
      expect(requestBody['text'], 'Guten Tag');
      expect(requestBody['language'], 'de');
      expect(requestBody['voice'], 'de-ramona-f');
    });

    test('falls back to the default voice when none is given', () async {
      final service = LocalTtsService(
        defaultVoice: 'de-thorsten-m',
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['voice'], 'de-thorsten-m');
          return http.Response.bytes(createMockWav(), 200);
        }),
      );

      final result = await service.synthesize('Hallo', 'de');

      expect(result.voice, 'de-thorsten-m');
    });

    test('rejects empty text and invalid audio', () async {
      final service = LocalTtsService(
        client: MockClient(
          (_) async => http.Response.bytes(Uint8List(0), 200),
        ),
      );

      await expectLater(service.synthesize('', 'de'), throwsArgumentError);
      await expectLater(
        service.synthesize('Hallo', 'de'),
        throwsStateError,
      );
    });

    test('surfaces worker outages as errors for client fallback', () async {
      final service = LocalTtsService(
        client: MockClient((_) async => http.Response('down', 503)),
      );

      await expectLater(
        service.synthesize('Hallo', 'de'),
        throwsStateError,
      );
    });
  });
}
