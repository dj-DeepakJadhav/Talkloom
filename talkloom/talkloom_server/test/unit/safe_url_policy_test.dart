import 'dart:io';

import 'package:test/test.dart';
import 'package:talkloom_server/src/sources/safe_url_policy.dart';

void main() {
  group('SafeUrlPolicy', () {
    test('accepts HTTPS public hostnames and rejects unsafe URL forms', () {
      expect(
        SafeUrlPolicy.parsePublicWebUrl('https://example.org/path').host,
        'example.org',
      );
      for (final url in [
        'http://example.org',
        'file:///etc/passwd',
        'https://user:pass@example.org/',
        'https://example.org:8443/',
        'https://127.0.0.1/',
        'https://[::1]/',
        'https://localhost./',
        'https://printer.local/',
      ]) {
        expect(
          () => SafeUrlPolicy.parsePublicWebUrl(url),
          throwsArgumentError,
          reason: url,
        );
      }
    });

    test(
      'rejects every private, loopback, link-local, and reserved DNS answer',
      () async {
        for (final address in [
          InternetAddress('127.0.0.1'),
          InternetAddress('10.0.0.1'),
          InternetAddress('172.16.0.1'),
          InternetAddress('192.168.1.10'),
          InternetAddress('169.254.169.254'),
          InternetAddress('100.64.0.1'),
          InternetAddress('224.0.0.1'),
          InternetAddress('::1', type: InternetAddressType.IPv6),
          InternetAddress('fe80::1', type: InternetAddressType.IPv6),
          InternetAddress('fd00::1', type: InternetAddressType.IPv6),
        ]) {
          await expectLater(
            SafeUrlPolicy.resolvePublicAddresses(
              Uri.parse('https://example.org'),
              resolver: (_) async => [address],
            ),
            throwsArgumentError,
            reason: address.address,
          );
        }
      },
    );

    test('rejects mixed public/private DNS answers', () async {
      await expectLater(
        SafeUrlPolicy.resolvePublicAddresses(
          Uri.parse('https://example.org'),
          resolver: (_) async => [
            InternetAddress('93.184.216.34'),
            InternetAddress('192.168.1.1'),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
