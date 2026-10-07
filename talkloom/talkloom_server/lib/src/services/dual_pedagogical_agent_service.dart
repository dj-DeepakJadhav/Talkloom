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

    // Try the configured provider first, then one configured failover.
    for (final candidate in _availableProviders()) {
      try {
        final reply = await _generateReplyFor(
          candidate,
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
          responseMode: candidate.name,
        );
      } catch (error) {
        print('[DualPedagogicalAgentService] ${candidate.name} error: $error');
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

  List<AiProvider> _availableProviders() {
    final configured = <AiProvider, bool>{
      AiProvider.gemini: geminiApiKey.isNotEmpty,
      AiProvider.nebius: nebiusApiKey.isNotEmpty,
      AiProvider.nvidia: nvidiaApiKey.isNotEmpty,
      AiProvider.groq: groqApiKey.isNotEmpty,
    };
    final order = <AiProvider>[
      provider,
      AiProvider.nvidia,
      AiProvider.gemini,
      AiProvider.nebius,
      AiProvider.groq,
    ];
    return order
        .toSet()
        .where((candidate) => configured[candidate]!)
        .take(2)
        .toList();
  }

  Future<String> _generateReplyFor(
    AiProvider candidate, {
    required String targetLanguage,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<ConversationHistoryEntry> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) => switch (candidate) {
    AiProvider.gemini => _generateGeminiReply(
      targetLanguage: targetLanguage,
      role: role,
      situation: situation,
      hiddenTargets: hiddenTargets,
      previousTurns: previousTurns,
      learnerUtterance: learnerUtterance,
      tactic: tactic,
      cognitiveLoad: cognitiveLoad,
      culturalFacts: culturalFacts,
    ),
    AiProvider.nebius => _generateNebiusReply(
      targetLanguage: targetLanguage,
      role: role,
      situation: situation,
      hiddenTargets: hiddenTargets,
      previousTurns: previousTurns,
      learnerUtterance: learnerUtterance,
      tactic: tactic,
      cognitiveLoad: cognitiveLoad,
      culturalFacts: culturalFacts,
    ),
    AiProvider.nvidia => _generateNvidiaReply(
      targetLanguage: targetLanguage,
      role: role,
      situation: situation,
      hiddenTargets: hiddenTargets,
      previousTurns: previousTurns,
      learnerUtterance: learnerUtterance,
      tactic: tactic,
      cognitiveLoad: cognitiveLoad,
      culturalFacts: culturalFacts,
    ),
    AiProvider.groq => _generateGroqReply(
      targetLanguage: targetLanguage,
      role: role,
      situation: situation,
      hiddenTargets: hiddenTargets,
      previousTurns: previousTurns,
      learnerUtterance: learnerUtterance,
      tactic: tactic,
      cognitiveLoad: cognitiveLoad,
      culturalFacts: culturalFacts,
    ),
  };

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

  Future<String> _generateGeminiReply({
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

    final prompt =
        '''
$systemPrompt

Previous conversation turns:
${previousTurns.map((turn) => "${turn.role.name}: ${turn.content}").join("\n")}

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
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.6,
          'maxOutputTokens': 150,
        },
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
    required List<ConversationHistoryEntry> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt =
        '''
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
      ..._openAiHistory(previousTurns),
      {'role': 'user', 'content': learnerUtterance},
    ];

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
    required List<ConversationHistoryEntry> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt =
        '''
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
      ..._openAiHistory(previousTurns),
      {'role': 'user', 'content': learnerUtterance},
    ];

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
    required List<ConversationHistoryEntry> previousTurns,
    required String learnerUtterance,
    required String tactic,
    required String cognitiveLoad,
    List<String>? culturalFacts,
  }) async {
    final systemPrompt =
        '''
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
      ..._openAiHistory(previousTurns),
      {'role': 'user', 'content': learnerUtterance},
    ];

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
