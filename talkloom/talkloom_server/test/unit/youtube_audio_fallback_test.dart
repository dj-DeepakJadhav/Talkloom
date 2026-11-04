import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/agent_reach_worker_adapter.dart'
    show AgentReachResolvedContent, AgentReachWorkerAdapter;
import 'package:talkloom_server/src/services/agent_reach_youtube_resolver.dart'
    show AgentReachYouTubeResolver;
import 'package:talkloom_server/src/services/ingestion_service.dart';

class _NullAgentReachWorker extends AgentReachWorkerAdapter {
  @override
  Future<AgentReachResolvedContent?> resolveUrlContent(
    Uri uri, {
    String? userScopeId,
  }) async => null;

  @override
  Future<AgentReachResolvedContent?> resolveYouTubeTranscript(
    Uri uri, {
    required String targetLanguage,
    String? userScopeId,
  }) async => null;
}

void main() {
  Future<List<InternetAddress>> publicResolver(String _) async => [
    InternetAddress('93.184.216.34'),
  ];

  IngestionService service({
    Future<Uint8List?> Function(String url)? audioDownloader,
    Future<String?> Function(Uint8List wav, String apiKey)? audioTranscriber,
  }) => IngestionService(
    hostResolver: publicResolver,
    client: MockClient((request) async => http.Response('{}', 404)),
    agentReachWorker: _NullAgentReachWorker(),
    agentReachYouTubeResolver: AgentReachYouTubeResolver(
      executableOverride: '__talkloom-test-no-ytdlp__',
    ),
    audioDownloader: audioDownloader,
    audioTranscriber: audioTranscriber,
  );

  /// A syntactically valid but nonexistent video id, so the real caption
  /// upstreams (including the Python extractor) fail hermetically and the
  /// audio fallback path is exercised without live captions.
  const missingVideoUrl = 'https://www.youtube.com/watch?v=AAAAAAAAAAA';

  group('YouTube audio-transcription fallback', () {
    test('returns transcribed audio when captions are missing', () async {
      final wav = Uint8List.fromList(utf8.encode('RIFFfake-wav-bytes'));
      final svc = service(
        audioDownloader: (_) async => wav,
        audioTranscriber: (_, apiKey) async {
          expect(apiKey, isNotEmpty);
          return 'Dies ist eine transkribierte deutsche Audiobeschreibung mit '
              'mehr als sechzig Zeichen für den Fallback-Test der App.';
        },
      );

      final text = await svc.ingestUrl(
        missingVideoUrl,
        metaApiKey: 'test-key',
      );
      expect(text, contains('audio-transcription'));
      expect(text, contains('transkribierte deutsche Audiobeschreibung'));
      svc.close();
    });

    test('fails with guidance when no key and no captions', () async {
      final svc = service(
        audioDownloader: (_) async => null,
        audioTranscriber: (_, _) async => null,
      );

      await expectLater(
        svc.ingestUrl(missingVideoUrl),
        throwsA(isA<StateError>()),
      );
      svc.close();
    });

    test('fails with guidance when audio download is unavailable', () async {
      var transcribed = false;
      final svc = service(
        audioDownloader: (_) async => null,
        audioTranscriber: (_, _) async {
          transcribed = true;
          return 'unused';
        },
      );

      await expectLater(
        svc.ingestUrl(missingVideoUrl, metaApiKey: 'test-key'),
        throwsA(isA<StateError>()),
      );
      expect(transcribed, isFalse);
      svc.close();
    });
  });
}
