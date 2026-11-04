import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import '../generated/protocol.dart';

/// Server-side AI cost guard.
///
/// Every Meta Model API call burns the operator's credits, and the client is
/// public, so each paid operation passes through [consume] first. Guests get
/// a small daily allowance; registered learners get a larger one. Counters
/// reset at UTC midnight. Over-quota requests fail with a learner-safe
/// [ImportException] (`quota_exceeded`) that the Flutter app maps to an
/// upgrade/wait message — never a bare 500.
///
/// Tuned without code changes through environment variables (Render
/// dashboard → Environment → save → restart; locally, export before
/// `serverpod start`):
///
/// * `AI_QUOTA_ENABLED=false` — master switch off (no limits at all).
///   Default `true`.
/// * `AI_QUOTA_GUEST_IMPORTS`, `AI_QUOTA_GUEST_TURNS`,
///   `AI_QUOTA_GUEST_TRANSLATIONS`, `AI_QUOTA_GUEST_TRANSCRIPTIONS`,
///   `AI_QUOTA_GUEST_ILLUSTRATIONS` — guest daily caps.
/// * `AI_QUOTA_REGISTERED_*` — same keys for registered learners.
/// * `0` disables that kind entirely. Unset keys keep the built-in
///   defaults below.
class AiQuotaService {
  static const _guestDefaults = <String, int>{
    'import': 3,
    'turn': 30,
    'translation': 30,
    'transcription': 10,
    'illustration': 5,
  };

  static const _registeredDefaults = <String, int>{
    'import': 10,
    'turn': 100,
    'translation': 100,
    'transcription': 30,
    'illustration': 20,
  };

  /// Master switch. Read live on every call; Render picks up changed env
  /// values on restart.
  static bool get enabled {
    final value = (Platform.environment['AI_QUOTA_ENABLED'] ?? 'true')
        .trim()
        .toLowerCase();
    return value != 'false' && value != '0' && value != 'no' && value != 'off';
  }

  /// Effective caps for a tier, with env overrides applied.
  static Map<String, int> limitsFor({required bool guest}) {
    final tier = guest ? 'GUEST' : 'REGISTERED';
    final defaults = guest ? _guestDefaults : _registeredDefaults;
    return {
      for (final entry in defaults.entries)
        entry.key: _envCap(tier, entry.key, entry.value),
    };
  }

  static int _envCap(String tier, String kind, int fallback) {
    final raw = Platform.environment['AI_QUOTA_${tier}_${kind.toUpperCase()}'];
    if (raw == null) return fallback;
    return int.tryParse(raw.trim()) ?? fallback;
  }

  /// True for anonymous-only identities; false once an email account exists.
  static Future<bool> isGuest(Session session) async {
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) return true;
    final id = UuidValue.withValidation(userIdentifier);
    final anonymous = await AnonymousAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(id),
    );
    if (anonymous == null) return false;
    return !await AuthServices.instance.emailIdp.hasAccount(session);
  }

  /// UTC-midnight bucket for [now].
  static DateTime dayBucket(DateTime now) =>
      DateTime.utc(now.year, now.month, now.day);

  /// Fails with `quota_exceeded` when the daily allowance for [kind] is
  /// spent, otherwise bumps the counter. Kinds: import, turn, translation,
  /// transcription, illustration, video. No-op when the master switch is
  /// off. Call this where AI credit actually burns, not where requests
  /// queue — failed fetches must never eat the allowance.
  static Future<void> consume(Session session, String kind) async {
    if (!enabled) return;
    final userIdentifier = session.authenticated?.userIdentifier;
    if (userIdentifier == null) {
      throw StateError('Sign in to use AI features.');
    }
    final userId = userIdentifier.toString();
    final guest = await isGuest(session);
    final limits = limitsFor(guest: guest);
    final cap = limits[kind];
    if (cap == null) throw ArgumentError('Unknown AI usage kind: $kind');

    final day = dayBucket(DateTime.now());
    var row = await AiUsage.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.day.equals(day),
    );
    row ??= await AiUsage.db.insertRow(
      session,
      AiUsage(userId: userId, day: day),
    );

    final used = _count(row, kind);
    if (used >= cap) {
      throw ImportException(
        code: 'quota_exceeded',
        message: guest
            ? 'You used today\u2019s free AI allowance ($cap ${_label(kind)}/day for guests). Register for more, or come back tomorrow.'
            : 'You used today\u2019s free AI allowance ($cap ${_label(kind)}/day). Come back tomorrow.',
      );
    }
    _bump(row, kind);
    await AiUsage.db.updateRow(session, row);
  }

  static int _count(AiUsage row, String kind) => switch (kind) {
    'import' => row.imports,
    'turn' || 'translation' => row.conversationTurns,
    'transcription' => row.transcriptions,
    'illustration' => row.illustrations,
    'video' => row.imports, // video chapters ride on the import allowance
    _ => 0,
  };

  static void _bump(AiUsage row, String kind) {
    switch (kind) {
      case 'import':
      case 'video':
        row.imports += 1;
      case 'turn':
      case 'translation':
        row.conversationTurns += 1;
      case 'transcription':
        row.transcriptions += 1;
      case 'illustration':
        row.illustrations += 1;
    }
  }

  static String _label(String kind) => switch (kind) {
    'import' => 'lesson imports',
    'turn' => 'tutor turns',
    'translation' => 'translation batches and tutor turns',
    'transcription' => 'transcriptions',
    'illustration' => 'illustrations',
    'video' => 'video chapters',
    _ => kind,
  };
}
