import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'package:talkloom_server/src/sources/import_maintenance_service.dart';
import 'package:talkloom_server/src/sources/lesson_import_service.dart';

void main() {
  group('ImportMaintenanceService.isStale', () {
    ImportJob job(String stage, DateTime updatedAt) => ImportJob(
      userId: 'u',
      type: 'text',
      title: 't',
      targetLanguage: 'de',
      supportLanguage: 'en',
      cefrLevel: 'A1',
      stage: stage,
      createdAt: updatedAt.subtract(const Duration(hours: 1)),
      updatedAt: updatedAt,
    );

    test('flags old non-terminal jobs', () {
      final now = DateTime.now();
      expect(
        ImportMaintenanceService.isStale(
          job(ImportStage.compiling, now.subtract(const Duration(hours: 2))),
          now,
        ),
        isTrue,
      );
    });

    test('ignores fresh jobs and terminal stages', () {
      final now = DateTime.now();
      expect(
        ImportMaintenanceService.isStale(
          job(ImportStage.compiling, now.subtract(const Duration(minutes: 5))),
          now,
        ),
        isFalse,
      );
      expect(
        ImportMaintenanceService.isStale(
          job(ImportStage.saved, now.subtract(const Duration(hours: 5))),
          now,
        ),
        isFalse,
      );
      expect(
        ImportMaintenanceService.isStale(
          job(ImportStage.failed, now.subtract(const Duration(hours: 5))),
          now,
        ),
        isFalse,
      );
    });
  });
}
