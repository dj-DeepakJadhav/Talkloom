import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../services/agent_reach_worker_adapter.dart';
import '../sources/safe_url_policy.dart';

/// Exposes Agent Reach's read-only channel actions to a learner identity.
/// The CLI runs under a HOME isolated to that learner's Serverpod identity.
class AgentReachEndpoint extends Endpoint {
  static const _maxParametersBytes = 64 * 1024;
  final AgentReachWorkerAdapter _worker = AgentReachWorkerAdapter();

  @override
  bool get requireLogin => true;

  String _userScopeId(Session session) {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) {
      throw StateError('Sign in to use connected content sources.');
    }
    return userId.toString();
  }

  /// Lists Agent Reach channels, actions, parameters and available backends.
  Future<String> channels(Session session) => _worker.channels(
    userScopeId: _userScopeId(session),
  );

  /// Returns channel setup/health information scoped to this learner.
  Future<String> doctor(Session session) => _worker.doctor(
    userScopeId: _userScopeId(session),
  );

  /// Runs one read-only channel action, for example `youtube subtitle` or
  /// `reddit read`. Parameters are JSON so newly added Agent Reach actions are
  /// available without another Serverpod schema change.
  Future<String> runAction(
    Session session,
    String channel,
    String action,
    String parametersJson, {
    String? backend,
    int timeoutSeconds = 30,
  }) async {
    if (parametersJson.length > _maxParametersBytes) {
      throw ArgumentError('These action details are too large.');
    }
    final decoded = jsonDecode(parametersJson);
    if (decoded is! Map<String, dynamic>) {
      throw ArgumentError('Action details must be a JSON object.');
    }

    final parameters = <String, dynamic>{};
    for (final entry in decoded.entries) {
      parameters[entry.key] = await _validateParameterValue(entry.value);
    }

    return _worker.runAction(
      userScopeId: _userScopeId(session),
      channel: channel,
      action: action,
      parameters: parameters,
      backend: backend,
      timeoutSeconds: timeoutSeconds,
    );
  }

  Future<String> _validatePublicUrl(String value) async {
    final uri = SafeUrlPolicy.parsePublicWebUrl(value);
    await SafeUrlPolicy.resolvePublicAddresses(
      uri,
      resolver: InternetAddress.lookup,
    );
    return uri.toString();
  }

  Future<Object?> _validateParameterValue(Object? value) async {
    if (value is String && value.contains('://')) {
      return _validatePublicUrl(value);
    }
    if (value is List) {
      final validated = <Object?>[];
      for (final entry in value) {
        validated.add(await _validateParameterValue(entry));
      }
      return validated;
    }
    if (value is Map<String, dynamic>) {
      final validated = <String, dynamic>{};
      for (final entry in value.entries) {
        validated[entry.key] = await _validateParameterValue(entry.value);
      }
      return validated;
    }
    return value;
  }
}
