import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/agent_reach_worker_adapter.dart'
    show AgentReachResolvedContent, AgentReachWorkerAdapter;
import 'package:talkloom_server/src/services/ingestion_service.dart';
import 'package:talkloom_server/src/generated/protocol.dart'
    show ImportException;

/// Keeps these tests hermetic: the real adapter would run an installed
/// Agent Reach CLI and fetch the live page, bypassing the mocked client.
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

  group('IngestionService safe fetches', () {
    test('reports a bot-blocking site as a blocked import', () async {
      final service = IngestionService(
        agentReachWorker: _NullAgentReachWorker(),
        hostResolver: publicResolver,
        client: MockClient(
          (request) async => http.Response('Attention Required!', 403),
        ),
      );

      await expectLater(
        service.ingestUrl('https://example.org/lesson'),
        throwsA(
          isA<ImportException>()
              .having((e) => e.code, 'code', 'blocked')
              .having((e) => e.message, 'message', contains('example.org')),
        ),
      );
      service.close();
    });

    test('reports a page without text as no_text', () async {
      final service = IngestionService(
        agentReachWorker: _NullAgentReachWorker(),
        hostResolver: publicResolver,
        client: MockClient(
          (request) async =>
              http.Response('<html><script>x</script></html>', 200),
        ),
      );

      await expectLater(
        service.ingestUrl('https://example.org/app'),
        throwsA(
          isA<ImportException>().having((e) => e.code, 'code', 'no_text'),
        ),
      );
      service.close();
    });

    test('does not follow a redirect to a private destination', () async {
      final requestedHosts = <String>[];
      final service = IngestionService(
        agentReachWorker: _NullAgentReachWorker(),
        hostResolver: (host) async => host == 'example.org'
            ? [InternetAddress('93.184.216.34')]
            : [InternetAddress('127.0.0.1')],
        client: MockClient((request) async {
          requestedHosts.add(request.url.host);
          return http.Response(
            '',
            302,
            headers: {'location': 'https://internal.example.org/'},
          );
        }),
      );

      await expectLater(
        service.ingestUrl('https://example.org/redirect'),
        throwsA(isA<ImportException>()),
      );
      // The embedded-data fetch and the main fetch both stop at the redirect.
      // Nothing ever reaches the private destination.
      expect(requestedHosts, isNotEmpty);
      expect(requestedHosts.toSet(), {'example.org'});
      service.close();
    });

    test('bounds downloaded response bytes', () async {
      var requestCount = 0;
      final service = IngestionService(
        agentReachWorker: _NullAgentReachWorker(),
        hostResolver: publicResolver,
        client: MockClient((request) async {
          requestCount++;
          return http.Response(
            List.filled(2 * 1024 * 1024 + 1, 'x').join(),
            200,
          );
        }),
      );

      await expectLater(
        service.ingestUrl('https://example.org/large'),
        throwsA(isA<ImportException>()),
      );
      // Two direct fetches (embedded data, then the main read) plus the public
      // reader as an independent bounded fallback. Never an unbounded retry.
      expect(requestCount, lessThanOrEqualTo(3));
      service.close();
    });
  });
}
