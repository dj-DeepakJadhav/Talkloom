import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:talkloom_server/src/services/ingestion_service.dart';
import 'package:talkloom_server/src/sources/target_language_guard.dart';
import 'package:talkloom_server/src/sources/content_hygiene_service.dart';
import 'package:talkloom_server/src/generated/protocol.dart'
    show ImportException;

/// Input acceptance matrix, run by hand before any handover:
/// `dart test test/integration/ingest_matrix_test.dart`
///
/// No-AI tier: URL extraction + language guard + hygiene scan only, so it
/// runs in seconds and costs nothing. Full compiles (slow, paid) are covered
/// by `import_job_test.dart` and the pre-recording rehearsal, not here.
///
/// Cases live in `test/data/ingest_matrix.json` — add the learner's real
/// links there (name/type/url-or-text/targetLanguage/expect) and rerun.
/// `expect` is one of: ok | wrong_language | unreadable.
void main() {
  test('ingest matrix is green', () async {
    final cases = jsonDecode(
      await File('test/data/ingest_matrix.json').readAsString(),
    ) as List;
    final service = IngestionService();
    final rows = <List<String>>[];
    try {
      for (final entry in cases.whereType<Map>()) {
        final name = entry['name'].toString();
        final type = entry['type'].toString();
        final target = (entry['targetLanguage'] ?? 'de').toString();
        final expected = entry['expect'].toString();
        String outcome;
        String detail;
        try {
          final String text;
          if (type == 'url') {
            // META_API_KEY enables the audio-transcription repair path
            // (spoken reels). Without it those cases report their
            // page-text outcome, which is the honest production behavior
            // on a keyless server.
            final metaApiKey = Platform.environment['META_API_KEY'] ?? '';
            text = await service
                .ingestUrl(
                  entry['url'].toString(),
                  metaApiKey: metaApiKey,
                )
                .timeout(const Duration(minutes: 2));
          } else if (type == 'document' || type == 'image') {
            // Upload / Scan: fixture file -> base64 media extraction.
            final fixture = File(entry['file'].toString());
            if (!await fixture.exists()) {
              rows.add([
                name,
                expected,
                'missing_fixture',
                entry['file'].toString(),
              ]);
              continue;
            }
            final bytes = await fixture.readAsBytes();
            final mime = entry['mime'].toString();
            final dataUri =
                'data:$mime;base64,${base64Encode(bytes)}';
            final metaApiKey = Platform.environment['META_API_KEY'] ?? '';
            text = await service
                .extractTextFromMedia(
                  base64Data: dataUri,
                  mimeType: mime,
                  metaApiKey: metaApiKey,
                )
                .timeout(const Duration(minutes: 2));
          } else {
            text = entry['text'].toString();
            if (text.trim().isEmpty) throw ArgumentError('empty case text');
          }
          final hygiene = ContentHygieneService.scanText(text);
          TargetLanguageGuard.checkText(text: text, targetLanguage: target);
          outcome = 'ok';
          detail =
              '${text.length} chars${hygiene.isEmpty ? '' : ' hygiene=${hygiene.join(",")}'}';
        } on ImportException catch (e) {
          outcome = e.code;
          detail = e.message.length > 80
              ? '${e.message.substring(0, 80)}…'
              : e.message;
        } on TimeoutException {
          outcome = 'timeout';
          detail = 'upstream too slow';
        } catch (e) {
          outcome = 'error';
          detail = e.runtimeType.toString();
        }
        rows.add([name, expected, outcome, detail]);
      }
    } finally {
      service.close();
    }
    for (final row in rows) {
      // ignore: avoid_print
      print('MATRIX ${row[0]} expect=${row[1]} got=${row[2]} :: ${row[3]}');
    }
    final failures = rows.where((r) => r[1] != r[2]).toList();
    expect(
      failures,
      isEmpty,
      reason:
          'matrix failures: ${failures.map((r) => '${r[0]} expected ${r[1]} got ${r[2]}').join('; ')}',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
