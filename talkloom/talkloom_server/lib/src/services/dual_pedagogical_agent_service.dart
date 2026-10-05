import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dual_ai_compiler_service.dart';

class DualPedagogicalAgentService {
  final AiProvider provider;
  final String geminiApiKey;
  final String nebiusApiKey;
  final String nvidiaApiKey;
  final String groqApiKey;
  final String geminiModel;
  final String nebiusModel;
  final String nvidiaModel;
  final String groqModel;
  final String nebiusBaseUrl;
  final String nvidiaBaseUrl;
  final String groqBaseUrl;
  final http.Client _client;

  DualPedagogicalAgentService({
    required this.provider,
    this.geminiApiKey = '',
    this.nebiusApiKey = '',
    this.nvidiaApiKey = '',
    this.groqApiKey = '',
    this.geminiModel = 'gemini-3.1-flash-lite',
    this.nebiusModel = 'nvidia/nemotron-3-8b-instruct',
    this.nvidiaModel = 'nvidia/nemotron-3.5-lightning-30b-a3b',
    this.groqModel = 'llama-3.3-70b-versatile',
    this.nebiusBaseUrl = 'https://api.tokenfactory.nebius.com/v1',
    this.nvidiaBaseUrl = 'https://integrate.api.nvidia.com/v1',
    this.groqBaseUrl = 'https://api.groq.com/openai/v1',
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
    // 1. Telemetry heuristics
    final normalizedInput = learnerUtterance.toLowerCase();
    String? detectedTarget;
    bool spontaneous = false;

    for (var target in hiddenTargets) {
      final cleanTarget = target.contains(':') ? target.split(':')[1] : target;
      if (normalizedInput.contains(cleanTarget.toLowerCase())) {
        detectedTarget = cleanTarget;
        spontaneous = true;
        break;
      }
    }

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

    // 2. Dispatch to provider with cascading failover and explicit error logging
    if (provider == AiProvider.nvidia && nvidiaApiKey.isNotEmpty) {
      try {
        print('[DualPedagogicalAgentService] Using NVIDIA NIM provider...');
        final reply = await _generateNvidiaReply(
          targetLanguage: targetLanguage,
          role: role,
          situation: situation,
          hiddenTargets: hiddenTargets,
          previousTurns: previousTurns,
          learnerUtterance: learnerUtterance,
          tactic: tactic,
          cognitiveLoad: cognitiveLoad,
          culturalFacts: culturalFacts,
        );
        return PedagogicalAgentTelemetry(
          activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: reply,
          targetProducedSpontaneously: spontaneous,
          detectedTarget: detectedTarget,
        );
      } catch (e) {
        print('[DualPedagogicalAgentService] NVIDIA error: $e');
      }
    }

    if (provider == AiProvider.gemini && geminiApiKey.isNotEmpty) {
      try {
        print('[DualPedagogicalAgentService] Using Gemini provider...');
        final reply = await _generateGeminiReply(
          targetLanguage: targetLanguage,
          role: role,
          situation: situation,
          hiddenTargets: hiddenTargets,
          previousTurns: previousTurns,
          learnerUtterance: learnerUtterance,
          tactic: tactic,
          cognitiveLoad: cognitiveLoad,
          culturalFacts: culturalFacts,
        );
        return PedagogicalAgentTelemetry(
          activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: reply,
          targetProducedSpontaneously: spontaneous,
          detectedTarget: detectedTarget,
        );
      } catch (e) {
        print('[DualPedagogicalAgentService] Gemini error: $e');
      }
    }

    // Failover to NVIDIA NIM if not already attempted
    if (provider != AiProvider.nvidia && nvidiaApiKey.isNotEmpty) {
      try {
        print('[DualPedagogicalAgentService] Failover to NVIDIA NIM provider...');
        final reply = await _generateNvidiaReply(
          targetLanguage: targetLanguage,
          role: role,
          situation: situation,
          hiddenTargets: hiddenTargets,
          previousTurns: previousTurns,
          learnerUtterance: learnerUtterance,
          tactic: tactic,
          cognitiveLoad: cognitiveLoad,
          culturalFacts: culturalFacts,
        );
        return PedagogicalAgentTelemetry(
          activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: reply,
          targetProducedSpontaneously: spontaneous,
          detectedTarget: detectedTarget,
        );
      } catch (e) {
        print('[DualPedagogicalAgentService] NVIDIA error: $e');
      }
    }

    if (nebiusApiKey.isNotEmpty) {
      try {
        print('[DualPedagogicalAgentService] Trying Nebius provider...');
        final reply = await _generateNebiusReply(
          targetLanguage: targetLanguage,
          role: role,
          situation: situation,
          hiddenTargets: hiddenTargets,
          previousTurns: previousTurns,
          learnerUtterance: learnerUtterance,
          tactic: tactic,
          cognitiveLoad: cognitiveLoad,
          culturalFacts: culturalFacts,
        );
        return PedagogicalAgentTelemetry(
          activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: reply,
          targetProducedSpontaneously: spontaneous,
          detectedTarget: detectedTarget,
        );
      } catch (e) {
        print('[DualPedagogicalAgentService] Nebius error: $e');
      }
    }

    if (groqApiKey.isNotEmpty) {
      try {
        print('[DualPedagogicalAgentService] Trying Groq provider...');
        final reply = await _generateGroqReply(
          targetLanguage: targetLanguage,
          role: role,
          situation: situation,
          hiddenTargets: hiddenTargets,
          previousTurns: previousTurns,
          learnerUtterance: learnerUtterance,
          tactic: tactic,
          cognitiveLoad: cognitiveLoad,
          culturalFacts: culturalFacts,
        );
        return PedagogicalAgentTelemetry(
          activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
          activeTactic: tactic,
          hiddenTargets: hiddenTargets,
          elicitedTargets: detectedTarget != null ? [detectedTarget] : [],
          estimatedLatencySec: responseLatencySec,
          cognitiveLoad: cognitiveLoad,
          reply: reply,
          targetProducedSpontaneously: spontaneous,
          detectedTarget: detectedTarget,
        );
      } catch (e) {
        print('[DualPedagogicalAgentService] Groq error: $e');
      }
    }

    // 3. Fallback
    print('[DualPedagogicalAgentService] Falling back to contextual template reply.');
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

  Future<String> _generateGeminiReply({
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt = '''
You are the Talkloom Pedagogical Conversation Tutor.
Role: $role
Situation: $situation
Target Language: $targetLanguage
Learner Target Expressions / Vocabulary: ${hiddenTargets.join(", ")}
Pedagogical Tactic: $tactic
Learner Cognitive Load: $cognitiveLoad

Cultural facts to weave in if natural:
${(culturalFacts ?? []).map((f) => "- $f").join("\n")}

CRITICAL PEDAGOGICAL VOCABULARY CONSTRAINTS:
1. Speak strictly in $targetLanguage matching an introductory / elementary CEFR level (A1-A2).
2. DO NOT use advanced, rare, or complex administrative jargon (e.g. do NOT use words like "Kaution", "Wohnungsübergabe", "Mietvertrag", "Frist" unless they are in the lesson's target vocabulary list).
3. Ground your vocabulary strictly in the learner's level and the target list. Keep sentences short, crystal-clear, and natural (1-2 sentences).
4. If you introduce any necessary new word or phrase that a beginner might not know, wrap it in double square brackets with its meaning in English, like: [[new:word:meaning]]. For example: [[new:Bahnhof:train station]].
5. Gently prompt or encourage the learner to speak without explicitly saying the secret target phrases.
''';

    final prompt = '''
$systemPrompt

Previous conversation turns:
${previousTurns.join("\n")}

Learner just said: "$learnerUtterance"

Your spoken reply as $role (in $targetLanguage):
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$geminiApiKey',
    );

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.6,
          'maxOutputTokens': 150,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return text.trim();
    }
    throw StateError('Gemini API returned status ${response.statusCode}');
  }

  Future<String> _generateNebiusReply({
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
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
        'model': nebiusModel,
        'messages': messages,
        'temperature': 0.6,
        'max_tokens': 120,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return content.trim();
    }
    throw StateError('Nebius API returned status ${response.statusCode}');
  }

  Future<String> _generateNvidiaReply({
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt = '''
You are the Talkloom Pedagogical Conversation Tutor powered directly by NVIDIA NIM (Nemotron).
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
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (var turn in previousTurns) {
      messages.add({'role': 'assistant', 'content': turn});
    }
    messages.add({'role': 'user', 'content': learnerUtterance});

    final response = await _client.post(
      Uri.parse('$nvidiaBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $nvidiaApiKey',
      },
      body: jsonEncode({
        'model': nvidiaModel,
        'messages': messages,
        'temperature': 0.6,
        'max_tokens': 250,
        'chat_template_args': {'enable_thinking': false},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return content.trim();
    }
    throw StateError('NVIDIA NIM API returned status ${response.statusCode}');
  }

  Future<String> _generateGroqReply({
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt = '''
You are the Talkloom Pedagogical Conversation Tutor powered by Groq LPU (Llama 3.3).
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
''';

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (var turn in previousTurns) {
      messages.add({'role': 'assistant', 'content': turn});
    }
    messages.add({'role': 'user', 'content': learnerUtterance});

    final response = await _client.post(
      Uri.parse('$groqBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': groqModel,
        'messages': messages,
        'temperature': 0.6,
        'max_tokens': 120,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return content.trim();
    }
    throw StateError('Groq API returned status ${response.statusCode}');
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
    final targetSample = hiddenTargets.isNotEmpty ? hiddenTargets.first.split(':').last.trim() : '';
    if (isGerman) {
      if (spontaneous && detectedTarget != null) {
        reply =
            'Sehr gut! Das Wort "$detectedTarget" passt genau. Wie möchten Sie weiter vorgehen?';
      } else if (targetSample.isNotEmpty) {
        reply =
            'Ich verstehe. Können Sie mir mehr darüber erzählen, zum Beispiel mit "$targetSample"?';
      } else {
        reply =
            'Ich verstehe Sie gut. Was möchten Sie als Nächstes tun?';
      }
    } else {
      if (spontaneous && detectedTarget != null) {
        reply =
            'Excellent! "$detectedTarget" fits perfectly here. How would you like to proceed?';
      } else if (targetSample.isNotEmpty) {
        reply =
            'I understand. Could you tell me more about that, perhaps using "$targetSample"?';
      } else {
        reply =
            'I understand you clearly. What would you like to do next?';
      }
    }

    return PedagogicalAgentTelemetry(
      activeMission: 'Elicit target expressions: ${hiddenTargets.join(", ")}',
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
