import 'dart:convert';
import 'package:http/http.dart' as http;

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
  };
}

class PedagogicalAgentService {
  final String nebiusApiKey;
  final String nebiusBaseUrl;
  final String modelName;
  final http.Client _client;

  PedagogicalAgentService({
    required this.nebiusApiKey,
    this.nebiusBaseUrl = 'https://api.tokenfactory.nebius.com/v1',
    this.modelName = 'nvidia/nemotron-3-8b-instruct',
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
    final cognitiveLoad = responseLatencySec > 4.0
        ? 'High (Hesitation Detected)'
        : (responseLatencySec > 2.0 ? 'Elevated' : 'Normal / Fluent');

    String? detectedTarget;
    bool spontaneous = false;
    final normalizedInput = learnerUtterance.toLowerCase();

    for (var target in hiddenTargets) {
      final cleanTarget = target.contains(':') ? target.split(':')[1] : target;
      if (normalizedInput.contains(cleanTarget.toLowerCase())) {
        detectedTarget = cleanTarget;
        spontaneous = true;
        break;
      }
    }

    final tactic = responseLatencySec > 3.5
        ? 'Simplify sentence structure and provide contextual encouragement'
        : (spontaneous
            ? 'Acknowledge target usage naturally and introduce follow-up complexity'
            : 'Formulate open natural question creating opening for remaining targets');

    if (nebiusApiKey.isEmpty) {
      return _generateFallbackReply(
        role: role,
        targetLanguage: targetLanguage,
        learnerUtterance: learnerUtterance,
        hiddenTargets: hiddenTargets,
        detectedTarget: detectedTarget,
        spontaneous: spontaneous,
        tactic: tactic,
        latency: responseLatencySec,
        cognitiveLoad: cognitiveLoad,
      );
    }

    try {
      final systemPrompt = '''
You are the Talkloom Pedagogical Conversation Tutor.
Role: $role
Situation: $situation
Target Language: $targetLanguage
Hidden Teaching Targets to elicit (NEVER state these explicitly): ${hiddenTargets.join(", ")}
Pedagogical Tactic: $tactic
Learner Cognitive Load: $cognitiveLoad

Cultural facts to weave in if natural:
${(culturalFacts ?? []).map((f) => "- $f").join("\n")}

Rules:
1. Respond in $targetLanguage staying completely in character.
2. Keep turns between 1-2 natural spoken sentences.
3. Gently steer toward eliciting unreached targets without giving away the vocabulary.
4. If learner made a severe comprehension error, clarify gently without interrupting fluency.
''';

      final messages = <Map<String, String>>[
        {'role': 'system', 'content': systemPrompt},
      ];

      for (var turn in previousTurns) {
        messages.add({'role': 'assistant', 'content': turn});
      }
      messages.add({'role': 'user', 'content': learnerUtterance});

      final response = await _client.post(
        Uri.parse('$nebiusBaseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $nebiusApiKey',
        },
        body: jsonEncode({
          'model': modelName,
          'messages': messages,
          'temperature': 0.6,
          'max_tokens': 120,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final replyText = data['choices'][0]['message']['content'] as String;

        return PedagogicalAgentTelemetry(
          activeMission: 'Elicit ${hiddenTargets.join(", ")} naturally',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: replyText.trim(),
          targetProducedSpontaneously: spontaneous,
          detectedTarget: detectedTarget,
        );
      }
    } catch (_) {}

    return _generateFallbackReply(
      role: role,
      targetLanguage: targetLanguage,
      learnerUtterance: learnerUtterance,
      hiddenTargets: hiddenTargets,
      detectedTarget: detectedTarget,
      spontaneous: spontaneous,
      tactic: tactic,
      latency: responseLatencySec,
      cognitiveLoad: cognitiveLoad,
    );
  }

  PedagogicalAgentTelemetry _generateFallbackReply({
    required String role,
    required String targetLanguage,
    required String learnerUtterance,
    required List<String> hiddenTargets,
    required String? detectedTarget,
    required bool spontaneous,
    required String tactic,
    required double latency,
    required String cognitiveLoad,
  }) {
    final isGerman = targetLanguage.toLowerCase().startsWith('de');
    String reply;

    if (isGerman) {
      if (detectedTarget != null) {
        reply = 'Sehr gut! Genau, das ist ein wichtiger Punkt. Haben Sie dazu noch weitere Fragen zu den Bedingungen oder zum Einzugstermin?';
      } else {
        reply = 'Guten Tag! Willkommen zur Besichtigung. Wann hatten Sie denn vor einzuziehen, und haben Sie Fragen zu den Kosten?';
      }
    } else {
      if (detectedTarget != null) {
        reply = 'Excellent point! That is crucial here. Do you have any further questions regarding the contract or timeline?';
      } else {
        reply = 'Hello! Welcome. Could you share what questions you have regarding the terms or schedule?';
      }
    }

    return PedagogicalAgentTelemetry(
      activeMission: 'Elicit ${hiddenTargets.join(", ")} naturally',
      activeTactic: tactic,
      hiddenTargets: hiddenTargets,
      elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
      estimatedLatencySec: latency,
      cognitiveLoad: cognitiveLoad,
      reply: reply,
      targetProducedSpontaneously: spontaneous,
      detectedTarget: detectedTarget,
    );
  }
}
