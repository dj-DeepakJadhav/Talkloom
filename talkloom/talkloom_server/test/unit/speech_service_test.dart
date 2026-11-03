import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/meta_speech_service.dart';

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
  byteData.setUint32(24, 24000, Endian.little);
  byteData.setUint32(28, 48000, Endian.little);
  byteData.setUint16(32, 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  header.setRange(36, 40, ascii.encode('data'));
  byteData.setUint32(40, dataLength, Endian.little);
  return header;
}

void main() {
  group('MetaSpeechService transcription', () {
    test('validates audio input', () async {
      final service = MetaSpeechService(apiKey: 'test-key');

      await expectLater(
        service.transcribe('not-base64!!!', language: 'de'),
        throwsArgumentError,
      );
      await expectLater(
        service.transcribe(base64Encode(Uint8List(0)), language: 'de'),
        throwsArgumentError,
      );
      await expectLater(
        service.transcribe(
          base64Encode(createMockWav()),
          language: 'zh',
        ),
        throwsArgumentError,
      );
    });

    test('requires a Meta Model API key', () async {
      final service = MetaSpeechService(apiKey: '');

      await expectLater(
        service.transcribe(base64Encode(createMockWav()), language: 'de'),
        throwsStateError,
      );
    });

    test(
      'posts multipart audio to the Meta transcribe endpoint',
      () async {
        late Uri requestUrl;
        late Map<String, String> requestHeaders;
        late Map<String, String> requestFields;
        late String fileField;
        final capture = _CaptureClient(
          http.Response(
            jsonEncode({'transcript': 'Guten Tag, wie geht es dir?'}),
            200,
          ),
        );
        final service = MetaSpeechService(
          apiKey: 'meta-test-key',
          client: capture,
        );

        final text = await service.transcribe(
          base64Encode(createMockWav()),
          language: 'de',
          vocabulary: ['Kaution'],
        );

        expect(text, 'Guten Tag, wie geht es dir?');
        final sent = capture.last as http.MultipartRequest;
        requestUrl = sent.url;
        requestHeaders = sent.headers;
        requestFields = Map.of(sent.fields);
        fileField = sent.files.single.field;
        expect(requestUrl.host, 'api.meta.ai');
        expect(requestUrl.path, '/v1/asr/transcribe');
        expect(requestHeaders['authorization'], 'Bearer meta-test-key');
        final settings =
            jsonDecode(requestFields['request']!) as Map<String, dynamic>;
        expect(settings['model'], 'muse-voice-transcribe-1.0');
        expect(settings['audioEncoding'], 'WAV');
        expect(settings['languageBias'], ['German']);
        expect(settings['keywords'], ['Kaution']);
        expect(fileField, 'audio');
      },
    );

    test('surfaces Meta errors without inventing a transcript', () async {
      final service = MetaSpeechService(
        apiKey: 'meta-test-key',
        client: MockClient((_) async => http.Response('bad wav', 400)),
      );

      await expectLater(
        service.transcribe(base64Encode(createMockWav()), language: 'de'),
        throwsStateError,
      );
    });
  });
}

class _CaptureClient extends http.BaseClient {
  _CaptureClient(this.response);

  final http.Response response;
  http.BaseRequest? last;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    last = request;
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}
