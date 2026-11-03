import 'package:serverpod/serverpod.dart';
import 'import_job_runner.dart';

/// Background lesson compilation. Scheduled by the ingestion endpoint so the
/// learner's request returns a job id immediately; the result is persisted in
/// the job row and pushed through the progress stream.
class ImportJobFutureCall extends FutureCall {
  Future<void> compile(Session session, int jobId) =>
      ImportJobRunner().run(session, jobId);
}
