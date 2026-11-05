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

/// AgentReach stub returning fixed page text (site chrome or real caption).
class _StubWorker extends AgentReachWorkerAdapter {
  _StubWorker(this.pageText);
  final String? pageText;

  @override
  Future<AgentReachResolvedContent?> resolveUrlContent(
    Uri uri, {
    String? userScopeId,
  }) async => pageText == null
      ? null
      : AgentReachResolvedContent(
          channel: 'Instagram',
          title: 'reel',
          author: 'tester',
          text: pageText!,
        );

  @override
  Future<AgentReachResolvedContent?> resolveYouTubeTranscript(
    Uri uri, {
    required String targetLanguage,
    String? userScopeId,
  }) async => null;
}

const _reelUrl = 'https://www.instagram.com/reel/De_lzAdIQfS/';

/// Long English page chrome with no German signal (the reel-2 failure):
/// the German is spoken in the video, not written on the page.
final _chromeText = List.filled(
  12,
  'Log In Sign Up Image profile picture Learn German Daily Lessons '
  'Everyday questions with English meanings for beginners at home. ',
).join();

const _germanCaption =
    'Guten Morgen! Wie geht es dir heute? Ich lerne Deutsch und ich '
    'trinke Kaffee mit meiner Freundin in Berlin. Das ist gut.';

const _germanTranscript =
    'Guten Morgen, wie geht es Ihnen? Ich lerne jeden Tag Deutsch, '
    'denn die Sprache ist wichtig für die Arbeit und das Studium.';

void main() {
  Future<List<InternetAddress>> publicResolver(String _) async => [
    InternetAddress('93.184.216.34'),
  ];

  IngestionService service({
    String? pageText,
    Future<Uint8List?> Function(String url)? audioDownloader,
    Future<String?> Function(Uint8List wav, String apiKey)? audioTranscriber,
  }) => IngestionService(
    hostResolver: publicResolver,
    client: MockClient((request) async => http.Response('not found', 404)),
    agentReachWorker: _StubWorker(pageText),
    agentReachYouTubeResolver: AgentReachYouTubeResolver(
      executableOverride: '__talkloom-test-no-ytdlp__',
    ),
    audioDownloader: audioDownloader,
    audioTranscriber: audioTranscriber,
  );

  group('social audio-transcription fallback', () {
    test('repairs chrome-only page text via spoken audio', () async {
      var transcribedWith = '';
      final svc = service(
        pageText: _chromeText,
        audioDownloader: (_) async =>
            Uint8List.fromList(utf8.encode('RIFFfake-wav-bytes')),
        audioTranscriber: (_, apiKey) async {
          transcribedWith = apiKey;
          return _germanTranscript;
        },
      );
      final text = await svc.ingestUrl(_reelUrl, metaApiKey: 'test-key');
      expect(transcribedWith, 'test-key');
      expect(text, contains('audio-transcription'));
      expect(text, contains('jeden Tag Deutsch'));
      svc.close();
    });

    test('keeps good page text without touching audio', () async {
      var audioCalled = false;
      final svc = service(
        pageText: _germanCaption,
        audioDownloader: (_) async {
          audioCalled = true;
          return null;
        },
        audioTranscriber: (_, _) async => null,
      );
      final text = await svc.ingestUrl(_reelUrl, metaApiKey: 'test-key');
      expect(text, contains('Instagram content'));
      expect(audioCalled, isFalse);
      svc.close();
    });

    test('without a key, chrome page text is returned for the guard', () async {
      final svc = service(
        pageText: _chromeText,
        audioDownloader: (_) async => null,
        audioTranscriber: (_, _) async => null,
      );
      final text = await svc.ingestUrl(_reelUrl);
      expect(text, contains('Instagram content'));
      svc.close();
    });
  });
}
