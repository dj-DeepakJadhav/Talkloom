import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/ingestion_service.dart';

void main() {
  Future<List<InternetAddress>> publicResolver(String _) async => [
    InternetAddress('93.184.216.34'),
  ];

  group('IngestionService safe fetches', () {
    test('does not follow a redirect to a private destination', () async {
      var requestCount = 0;
      final service = IngestionService(
        hostResolver: (host) async => host == 'example.org'
            ? [InternetAddress('93.184.216.34')]
            : [InternetAddress('127.0.0.1')],
        client: MockClient((request) async {
          requestCount++;
          return http.Response(
            '',
            302,
            headers: {'location': 'https://internal.example.org/'},
          );
        }),
      );

      await expectLater(
        service.ingestUrl('https://example.org/redirect'),
        throwsA(isA<StateError>()),
      );
      expect(requestCount, 1);
      service.close();
    });

    test('bounds downloaded response bytes', () async {
      var requestCount = 0;
      final service = IngestionService(
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
        throwsA(isA<StateError>()),
      );
      expect(requestCount, 1);
      service.close();
    });
  });
}
