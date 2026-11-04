import 'package:test/test.dart';
import 'package:talkloom_server/src/usage/ai_quota_service.dart';

void main() {
  group('AiQuotaService config', () {
    test('is enabled by default', () {
      // No AI_QUOTA_ENABLED in the test environment: default is on.
      expect(AiQuotaService.enabled, isTrue);
    });

    test('guest and registered defaults', () {
      final guest = AiQuotaService.limitsFor(guest: true);
      final registered = AiQuotaService.limitsFor(guest: false);
      expect(guest['import'], 3);
      expect(guest['turn'], 30);
      expect(registered['import'], 10);
      expect(registered['turn'], 100);
      expect(registered['illustration'], 20);
    });

    test('day bucket is UTC midnight', () {
      final bucket = AiQuotaService.dayBucket(
        DateTime(2026, 11, 4, 15, 30),
      );
      expect(bucket, DateTime.utc(2026, 11, 4));
    });
  });
}
