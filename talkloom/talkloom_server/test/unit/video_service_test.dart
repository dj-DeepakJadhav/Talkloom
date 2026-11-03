import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/meta_video_service.dart';

Map<String, dynamic> responsesEnvelope(String text) => {
  'output': [
    {'type': 'reasoning', 'id': 'rs_1'},
    {
      'type': 'message',
      'id': 'msg_1',
      'role': 'assistant',
      'content': [
        {'type': 'output_text', 'text': text},
      ],
    },
  ],
};

void main() {
  group('MetaVideoService', () {
    test('posts a video_url Responses request with low reasoning', () async {
      late Uri requestUrl;
      late Map<String, dynamic> requestBody;
      final service = MetaVideoService(
        apiKey: 'meta-test-key',
        client: MockClient((request) async {
          requestUrl = request.url;
          requestBody = jsonDecode(request.body);
          return http.Response(
            jsonEncode(
              responsesEnvelope(
                '{"summary": "A flower opens.", "chapters": [{"start": "00:00", "end": "00:10", "title": "Opening"}]}',
              ),
            ),
            200,
          );
        }),
      );

      final result = await service.describeVideo(
        'https://example.com/clip.mp4',
        language: 'de',
      );

      expect(requestUrl.host, 'api.meta.ai');
      expect(requestUrl.path, '/v1/responses');
      final input = (requestBody['input'] as List).single as Map;
      final content = input['content'] as List;
      final video = content
          .whereType<Map>()
          .firstWhere((c) => c['type'] == 'input_video');
      expect(video['video_url'], 'https://example.com/clip.mp4');
      expect(result['summary'], 'A flower opens.');
      expect((result['chapters'] as List), hasLength(1));
    });

    test('rejects non-mp4 URLs and missing keys', () async {
      final service = MetaVideoService(apiKey: 'meta-test-key');
      await expectLater(
        service.describeVideo('https://example.com/watch?v=abc', language: 'de'),
        throwsArgumentError,
      );

      final noKey = MetaVideoService(apiKey: '');
      await expectLater(
        noKey.describeVideo('https://example.com/clip.mp4', language: 'de'),
        throwsStateError,
      );
    });

    test('falls back to plain summary when JSON is absent', () async {
      final service = MetaVideoService(
        apiKey: 'meta-test-key',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(responsesEnvelope('Just some prose.')),
            200,
          ),
        ),
      );

      final result = await service.describeVideo(
        'https://example.com/clip.mp4',
        language: 'de',
      );

      expect(result['summary'], contains('Just some prose.'));
      expect(result['chapters'], isEmpty);
    });
  });
}
