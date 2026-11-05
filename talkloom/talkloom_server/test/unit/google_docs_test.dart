import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart'
    show ImportException;
import 'package:talkloom_server/src/services/agent_reach_worker_adapter.dart'
    show AgentReachResolvedContent, AgentReachWorkerAdapter;
import 'package:talkloom_server/src/services/agent_reach_youtube_resolver.dart'
    show AgentReachYouTubeResolver;
import 'package:talkloom_server/src/services/ingestion_service.dart';

class _NullWorker extends AgentReachWorkerAdapter {
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

const _germanDoc =
    'Guten Morgen, Herr Müller, wie geht es Ihnen heute? Ich lerne '
    'jeden Tag Deutsch, denn die Sprache ist wichtig für die Arbeit.';

void main() {
  Future<List<InternetAddress>> publicResolver(String _) async => [
    InternetAddress('93.184.216.34'),
  ];

  IngestionService service(String body, {int status = 200}) => IngestionService(
    hostResolver: publicResolver,
    client: MockClient((request) async {
      // Only the export endpoint may be called.
      expect(request.url.path, contains('/export'));
      return http.Response(body, status);
    }),
    agentReachWorker: _NullWorker(),
    agentReachYouTubeResolver: AgentReachYouTubeResolver(
      executableOverride: '__talkloom-test-no-ytdlp__',
    ),
  );

  group('Google Docs links', () {
    test('public doc exports as text', () async {
      final svc = service(_germanDoc);
      final text = await svc.ingestUrl(
        'https://docs.google.com/document/d/ABC123/edit?usp=sharing',
      );
      expect(text, contains('Guten Morgen'));
      svc.close();
    });

    test('private doc becomes guidance, not a lesson', () async {
      final svc = service(
        '<html>Sign in to continue to Google Docs</html>',
      );
      await expectLater(
        svc.ingestUrl('https://docs.google.com/document/d/ABC123/edit'),
        throwsA(
          isA<ImportException>().having((e) => e.code, 'code', 'unreadable'),
        ),
      );
      svc.close();
    });

    test('non-document Drive link is unsupported', () async {
      final svc = service(_germanDoc);
      await expectLater(
        svc.ingestUrl('https://drive.google.com/file/d/ABC123/view'),
        throwsA(
          isA<ImportException>().having(
            (e) => e.code,
            'code',
            'unsupported_link',
          ),
        ),
      );
      svc.close();
    });
  });
}
