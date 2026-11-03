import 'package:flutter/foundation.dart';
import 'language.dart';

/// Everything the app needs to know to generate and run a lesson.
///
/// This replaces the literal `'de'` / `'en'` / `'B1'` / `'landlord'` arguments
/// that were previously scattered through the UI. Any screen that needs to
/// talk to the backend reads these values from here.
@immutable
class LearningSession {
  const LearningSession({
    required this.target,
    required this.support,
    required this.level,
  });

  /// The language being learned.
  final Language target;

  /// The language explanations are given in.
  final Language support;

  final CefrLevel level;

  bool get isConfigured => target.code != support.code;

  LearningSession copyWith({
    Language? target,
    Language? support,
    CefrLevel? level,
  }) {
    return LearningSession(
      target: target ?? this.target,
      support: support ?? this.support,
      level: level ?? this.level,
    );
  }

  Map<String, String> toJson() => {
    'target': target.code,
    'support': support.code,
    'level': level.code,
  };

  static LearningSession fromJson(Map<String, dynamic> json) {
    return LearningSession(
      target: LanguageCatalog.byCode(json['target'] as String? ?? 'de'),
      support: LanguageCatalog.byCode(json['support'] as String? ?? 'en'),
      level: CefrLevel.fromCode(json['level'] as String? ?? 'B1'),
    );
  }

  static LearningSession guestDefault() {
    return LearningSession(
      target: LanguageCatalog.byCode('de'),
      support: LanguageCatalog.byCode('en'),
      level: CefrLevel.a2,
    );
  }
}

/// A situation the learner can practise, expressed independently of language.
///
/// The backend generates the actual content, so one definition serves every
/// language in the catalogue — replacing the three hardcoded German presets.
@immutable
class StarterScenario {
  const StarterScenario({
    required this.id,
    required this.title,
    required this.blurb,
    required this.role,
    required this.situation,
  });

  final String id;

  /// Shown to the learner, in their support language.
  final String title;
  final String blurb;

  /// The character the AI plays during the speaking mission.
  final String role;

  /// The setting handed to the conversation agent.
  final String situation;

  /// The prompt sent to the lesson compiler when no source was imported.
  String seedFor(LearningSession session) {
    return 'Everyday $situation in ${session.target.englishName}. '
        'The learner is at ${session.level.code} level and is speaking with a $role. '
        'Produce realistic, useful language for this situation.';
  }
}

abstract final class StarterScenarios {
  static const all = <StarterScenario>[
    StarterScenario(
      id: 'renting',
      title: 'Renting a flat',
      blurb: 'Deposits, contracts and viewings',
      role: 'landlord',
      situation: 'apartment viewing',
    ),
    StarterScenario(
      id: 'cafe',
      title: 'Ordering at a café',
      blurb: 'Drinks, food and small talk',
      role: 'barista',
      situation: 'ordering in a café',
    ),
    StarterScenario(
      id: 'travel',
      title: 'Getting around',
      blurb: 'Tickets, directions and delays',
      role: 'ticket clerk',
      situation: 'buying a train ticket',
    ),
    StarterScenario(
      id: 'doctor',
      title: 'At the doctor',
      blurb: 'Symptoms, appointments and advice',
      role: 'doctor',
      situation: 'a medical appointment',
    ),
    StarterScenario(
      id: 'work',
      title: 'First day at work',
      blurb: 'Introductions and workplace basics',
      role: 'new colleague',
      situation: 'meeting colleagues at a new job',
    ),
  ];
}
