import 'dart:convert';
import 'package:http/http.dart' as http;
import 'plain_language_policy.dart';

class DualPedagogicalAgentService {
  final String metaApiKey;
  final String metaModel;
  final String metaBaseUrl;
  final http.Client _client;

  DualPedagogicalAgentService({
    this.metaApiKey = '',
    this.metaModel = 'muse-spark-1.3',
    this.metaBaseUrl = 'https://api.meta.ai/v1',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<PedagogicalAgentTelemetry> stepConversation({
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String learnerUtterance,
    required double responseLatencySec,
    List<String>? culturalFacts,
  }) async {
    final history = ConversationHistoryEntry.parseAll(previousTurns);
    final recognizedTargets = <String>[];
    final assistedTargets = <String>[];
    for (final target in hiddenTargets) {
      final cleanTarget = target.contains(':')
          ? target.split(':').last
          : target;
      if (!_containsWholeTarget(learnerUtterance, cleanTarget)) continue;
      recognizedTargets.add(cleanTarget);
      if (_wasAssisted(history, cleanTarget)) assistedTargets.add(cleanTarget);
    }
    final detectedTarget = recognizedTargets.isEmpty
        ? null
        : recognizedTargets.first;
    final unassistedTarget =
        detectedTarget != null && !assistedTargets.contains(detectedTarget)
        ? detectedTarget
        : null;
    final spontaneous = unassistedTarget != null;

    final cognitiveLoad = responseLatencySec > 4.0
        ? 'High (Hesitant response)'
        : (responseLatencySec > 2.0
              ? 'Moderate (Normal processing)'
              : 'Low (Spontaneous recall)');

    final tactic = responseLatencySec > 3.5
        ? 'Simplify sentence structure and provide contextual encouragement'
        : (spontaneous
              ? 'Acknowledge target usage naturally and introduce follow-up complexity'
              : 'Formulate open natural question creating opening for remaining targets');

    // Meta Model API is the sole AI provider.
    if (metaApiKey.isNotEmpty) {
      try {
        final reply = await _generateMetaReply(
          targetLanguage: targetLanguage,
          role: role,
          situation: situation,
          hiddenTargets: hiddenTargets,
          previousTurns: history,
          learnerUtterance: learnerUtterance,
          tactic: tactic,
          cognitiveLoad: cognitiveLoad,
          culturalFacts: culturalFacts,
        );
        return PedagogicalAgentTelemetry(
          activeMission:
              'Elicit target expressions: ${hiddenTargets.join(", ")}',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: spontaneous && detectedTarget != null
              ? [detectedTarget]
              : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: reply,
          targetProducedSpontaneously: spontaneous,
          detectedTarget: unassistedTarget,
          recognizedTargets: recognizedTargets,
          assistedTargets: assistedTargets,
          responseMode: 'meta',
        );
      } catch (error) {
        print('[DualPedagogicalAgentService] meta error: $error');
      }
    }

    // 3. Fallback
    print(
      '[DualPedagogicalAgentService] Falling back to contextual template reply.',
    );
    return _generateFallbackReply(
      targetLanguage: targetLanguage,
      hiddenTargets: hiddenTargets,
      tactic: tactic,
      latency: responseLatencySec,
      cognitiveLoad: cognitiveLoad,
      recognizedTargets: recognizedTargets,
      assistedTargets: assistedTargets,
    );
  }

  List<Map<String, String>> _openAiHistory(
    List<ConversationHistoryEntry> history,
  ) => [
    for (final turn in history)
      {
        'role': turn.role == ConversationTurnRole.tutor ? 'assistant' : 'user',
        'content': turn.content,
      },
  ];

  bool _containsWholeTarget(String utterance, String target) {
    final cleanTarget = target.trim().toLowerCase();
    if (cleanTarget.isEmpty) return false;
    const delimiter = r'[^\p{L}\p{N}]';
    return RegExp(
      '(^|$delimiter)${RegExp.escape(cleanTarget)}(\$|$delimiter)',
      unicode: true,
    ).hasMatch(utterance.toLowerCase());
  }

  bool _wasAssisted(List<ConversationHistoryEntry> history, String target) =>
      history.any((turn) {
        if (turn.role != ConversationTurnRole.tutor) return false;
        if (turn.assistance != ConversationAssistance.none) return true;
        return _containsWholeTarget(turn.content, target);
      });

  Future<String> _generateMetaReply({
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<ConversationHistoryEntry> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt =
        '''
You are Talkloom's conversational language tutor.
Role: $role
Situation: $situation
Target language: $targetLanguage
Hidden teaching targets to elicit naturally (never list them to the learner): ${hiddenTargets.join(', ')}
Teaching tactic: $tactic
Learner cognitive load: $cognitiveLoad
Relevant cultural facts: ${(culturalFacts ?? []).join('; ')}
Reply in $targetLanguage in one or two natural spoken sentences. Stay in character, respond to what the learner said, and gently invite them to use language without supplying the target words.
''';
    final response = await _client.post(
      Uri.parse('$metaBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $metaApiKey',
      },
      body: jsonEncode({
        'model': metaModel,
        'reasoning_effort': 'low',
        'messages': [
          {
            'role': 'system',
            'content': '$systemPrompt\n$plainLanguageWritingRules',
          },
          ..._openAiHistory(previousTurns),
          {'role': 'user', 'content': learnerUtterance},
        ],
        'temperature': 0.6,
        'max_tokens': 1024,
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['choices'][0]['message']['content'] as String).trim();
    }
    throw StateError('Meta Model API returned status ${response.statusCode}');
  }

  PedagogicalAgentTelemetry _generateFallbackReply({
    required String targetLanguage,
    required List<String> hiddenTargets,
    required String tactic,
    required double latency,
    required String cognitiveLoad,
    required List<String> recognizedTargets,
    required List<String> assistedTargets,
  }) {
    final isGerman = targetLanguage.toLowerCase().startsWith('de');

    final reply = isGerman
        ? 'Ich verstehe. Was möchtest du dazu noch wissen?'
        : 'I understand. What would you like to know next?';

    return PedagogicalAgentTelemetry(
      activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
      activeTactic: tactic,
      hiddenTargets: hiddenTargets,
      elicitedTargets: const [],
      estimatedLatencySec: latency,
      cognitiveLoad: cognitiveLoad,
      reply: reply,
      targetProducedSpontaneously: false,
      recognizedTargets: recognizedTargets,
      assistedTargets: assistedTargets,
      responseMode: 'template_fallback',
    );
  }
}

class PedagogicalAgentTelemetry {
  final String activeMission;
  final String activeTactic;
  final List<String> hiddenTargets;
  final List<String> elicitedTargets;
  final double estimatedLatencySec;
  final String cognitiveLoad;
  final String reply;
  final bool targetProducedSpontaneously;
  final String? detectedTarget;
  final List<String> recognizedTargets;
  final List<String> assistedTargets;
  final String responseMode;
  final bool evidenceEligible;

  PedagogicalAgentTelemetry({
    required this.activeMission,
    required this.activeTactic,
    required this.hiddenTargets,
    required this.elicitedTargets,
    required this.estimatedLatencySec,
    required this.cognitiveLoad,
    required this.reply,
    required this.targetProducedSpontaneously,
    this.detectedTarget,
    this.recognizedTargets = const [],
    this.assistedTargets = const [],
    this.responseMode = 'provider',
    this.evidenceEligible = false,
  });

  Map<String, dynamic> toJson() => {
    'activeMission': activeMission,
    'activeTactic': activeTactic,
    'hiddenTargets': hiddenTargets,
    'elicitedTargets': elicitedTargets,
    'estimatedLatencySec': estimatedLatencySec,
    'cognitiveLoad': cognitiveLoad,
    'reply': reply,
    'targetProducedSpontaneously': targetProducedSpontaneously,
    'detectedTarget': detectedTarget,
    'recognizedTargets': recognizedTargets,
    'assistedTargets': assistedTargets,
    'responseMode': responseMode,
    'evidenceEligible': evidenceEligible,
  };
}

enum ConversationTurnRole { learner, tutor }

enum ConversationAssistance { none, prompted, modelled }

class ConversationHistoryEntry {
  final ConversationTurnRole role;
  final String content;
  final ConversationAssistance assistance;

  const ConversationHistoryEntry({
    required this.role,
    required this.content,
    required this.assistance,
  });

  static List<ConversationHistoryEntry> parseAll(List<String> values) {
    final result = <ConversationHistoryEntry>[];
    var totalCharacters = 0;
    for (final value in values.reversed) {
      if (result.length >= 30 || totalCharacters >= 12000) break;
      if (value.trim().isEmpty) continue;
      final parsed = _parseOne(value);
      final content = parsed.content.length > 3000
          ? parsed.content.substring(0, 3000)
          : parsed.content;
      if (totalCharacters + content.length > 12000) continue;
      totalCharacters += content.length;
      result.add(
        ConversationHistoryEntry(
          role: parsed.role,
          content: content,
          assistance: parsed.assistance,
        ),
      );
    }
    return result.reversed.toList();
  }

  static ConversationHistoryEntry _parseOne(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) {
        final role = switch (decoded['role']) {
          'learner' => ConversationTurnRole.learner,
          'tutor' => ConversationTurnRole.tutor,
          _ => null,
        };
        final content = decoded['content'];
        final assistance = switch (decoded['assistance']) {
          'none' => ConversationAssistance.none,
          'prompted' => ConversationAssistance.prompted,
          'modelled' => ConversationAssistance.modelled,
          _ => null,
        };
        if (role != null &&
            content is String &&
            content.trim().isNotEmpty &&
            assistance != null) {
          return ConversationHistoryEntry(
            role: role,
            content: content,
            assistance: assistance,
          );
        }
      }
    } on FormatException {
      // Legacy plain strings are treated as tutor help for safe evidence.
    }
    return ConversationHistoryEntry(
      role: ConversationTurnRole.tutor,
      content: value,
      assistance: ConversationAssistance.modelled,
    );
  }
}
