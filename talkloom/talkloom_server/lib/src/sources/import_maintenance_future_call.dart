import 'package:serverpod/serverpod.dart';
import 'import_maintenance_service.dart';

/// Recurring agentic loop: reaps stuck import jobs every 15 minutes.
/// Registered automatically by code generation as
/// `ImportMaintenanceSweepFutureCall`; scheduled in `server.dart`.
class ImportMaintenanceFutureCall extends FutureCall {
  Future<void> sweep(Session session) =>
      ImportMaintenanceService().sweep(session);
}
