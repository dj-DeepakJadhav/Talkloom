import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tavily_service.dart';

enum AiProvider { gemini, nebius, nvidia, groq }

class DualLessonCompilerService {
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

  DualLessonCompilerService({
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

  Future<Map<String, dynamic>> compileLesson({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) async {
    // 1. Primary Route: NVIDIA NIM
    if (provider == AiProvider.nvidia && nvidiaApiKey.isNotEmpty) {
      try {
        print('[DualLessonCompiler] Compiling with NVIDIA NIM...');
        return await _compileWithNvidia(
          sourceTitle: sourceTitle,
          rawText: rawText,
          targetLanguage: targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: estimatedLevel,
          grounding: grounding,
        );
      } catch (e) {
        print('[DualLessonCompiler] NVIDIA NIM compilation error: $e');
        if (geminiApiKey.isNotEmpty) {
          try {
            print('[DualLessonCompiler] Failover to Gemini...');
            return await _compileWithGemini(
              sourceTitle: sourceTitle,
              rawText: rawText,
              targetLanguage: targetLanguage,
              supportLanguage: supportLanguage,
              estimatedLevel: estimatedLevel,
              grounding: grounding,
            );
          } catch (e2) {
            print('[DualLessonCompiler] Gemini failover error: $e2');
          }
        }
      }
    } else if (provider == AiProvider.gemini && geminiApiKey.isNotEmpty) {
      try {
        return await _compileWithGemini(
          sourceTitle: sourceTitle,
          rawText: rawText,
          targetLanguage: targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: estimatedLevel,
          grounding: grounding,
        );
      } catch (e) {
        print('[DualLessonCompiler] Gemini compilation error: $e');
        // Failover to NVIDIA NIM if available
        if (nvidiaApiKey.isNotEmpty) {
          try {
            print('[DualLessonCompiler] Failover to NVIDIA NIM...');
            return await _compileWithNvidia(
              sourceTitle: sourceTitle,
              rawText: rawText,
              targetLanguage: targetLanguage,
              supportLanguage: supportLanguage,
              estimatedLevel: estimatedLevel,
              grounding: grounding,
            );
          } catch (e2) {
            print('[DualLessonCompiler] NVIDIA NIM failover error: $e2');
          }
        }
      }
    } else if (provider == AiProvider.nebius && nebiusApiKey.isNotEmpty) {
      try {
        return await _compileWithNebius(
          sourceTitle: sourceTitle,
          rawText: rawText,
          targetLanguage: targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: estimatedLevel,
          grounding: grounding,
        );
      } catch (e) {
        print('[DualLessonCompiler] Nebius compilation error: $e');
      }
    } else if (provider == AiProvider.nvidia && nvidiaApiKey.isNotEmpty) {
      try {
        return await _compileWithNvidia(
          sourceTitle: sourceTitle,
          rawText: rawText,
          targetLanguage: targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: estimatedLevel,
          grounding: grounding,
        );
      } catch (e) {
        print('[DualLessonCompiler] NVIDIA compilation error: $e');
      }
    } else if (provider == AiProvider.groq && groqApiKey.isNotEmpty) {
      try {
        return await _compileWithGroq(
          sourceTitle: sourceTitle,
          rawText: rawText,
          targetLanguage: targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: estimatedLevel,
          grounding: grounding,
        );
      } catch (e) {
        print('[DualLessonCompiler] Groq compilation error: $e');
      }
    }

    // Default dynamic contextual fallback (never static Kaution for unrelated topics)
    return _generateFallbackLessonDsl(
      sourceTitle: sourceTitle,
      rawText: rawText,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      estimatedLevel: estimatedLevel,
      grounding: grounding,
    );
  }

  Future<Map<String, dynamic>> _compileWithGemini({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) async {
    final groundingPrompt = grounding != null
        ? '\nAuthentic Ground Truth Facts:\n${grounding.culturalFacts.map((f) => "- $f").join("\n")}\nStatutory Rules:\n${grounding.statutoryRules.map((r) => "- $r").join("\n")}'
        : '';

    final prompt = '''
You are the Talkloom Pedagogical Lesson Compiler.
Compile the provided source text into a structured Lesson DSL JSON object.
Return ONLY valid JSON matching the schema below.

JSON Schema:
{
  "objectives": ["string", "string"],
  "vocabulary": [
    {
      "id": "lang:lemma",
      "lemma": "string",
      "article": "string (e.g. der/die/das or empty)",
      "meaning": "string in supportLanguage",
      "sourceContext": "string context sentence from source",
      "learnerState": "recognized_not_active"
    }
  ],
  "grammar": [
    {
      "concept": "string",
      "sourceSentence": "string",
      "explanation": "string in supportLanguage"
    }
  ],
  "activities": [
    {
      "type": "context_choice",
      "targets": ["lang:lemma"],
      "question": "string",
      "options": ["string", "string", "string"],
      "correctIndex": 0
    },
    {
      "type": "sentence_builder",
      "target": "complete target sentence",
      "scrambledTokens": ["token1", "token2", "token3"]
    },
    {
      "type": "speak_response",
      "objective": "string speaking mission objective"
    }
  ],
  "conversation": {
    "role": "string conversation partner role",
    "situation": "string situation description",
    "hiddenTargets": ["lang:lemma"],
    "culturalNotes": ["string"],
    "successCriteria": {
      "spontaneousTargetCount": 2
    }
  }
}

Source Details:
Target Language: $targetLanguage
Support Language: $supportLanguage
Learner CEFR Level: $estimatedLevel
Source Title: $sourceTitle
Source Content:
$rawText
$groundingPrompt
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
          'temperature': 0.2,
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text =
          data['candidates'][0]['content']['parts'][0]['text'] as String;
      return jsonDecode(text) as Map<String, dynamic>;
    }
    throw StateError('Gemini API returned status ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _compileWithNebius({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) async {
    final groundingPrompt = grounding != null
        ? '\nAuthentic Ground Truth Facts:\n${grounding.culturalFacts.map((f) => "- $f").join("\n")}\nStatutory Rules:\n${grounding.statutoryRules.map((r) => "- $r").join("\n")}'
        : '';

    final systemPrompt = '''
You are the Talkloom Pedagogical Lesson Compiler powered by NVIDIA Nemotron.
Compile the provided source text into a structured Lesson DSL JSON object.
Return ONLY valid JSON with no markdown backticks or commentary.

JSON Schema:
{
  "objectives": ["string", "string"],
  "vocabulary": [
    {
      "id": "lang:lemma",
      "lemma": "string",
      "article": "string (e.g. der/die/das or empty)",
      "meaning": "string in supportLanguage",
      "sourceContext": "string context sentence from source",
      "learnerState": "recognized_not_active"
    }
  ],
  "grammar": [
    {
      "concept": "string",
      "sourceSentence": "string",
      "explanation": "string in supportLanguage"
    }
  ],
  "activities": [
    {
      "type": "context_choice",
      "targets": ["lang:lemma"],
      "question": "string",
      "options": ["string", "string", "string"],
      "correctIndex": 0
    },
    {
      "type": "sentence_builder",
      "target": "complete target sentence",
      "scrambledTokens": ["token1", "token2", "token3"]
    },
    {
      "type": "speak_response",
      "objective": "string speaking mission objective"
    }
  ],
  "conversation": {
    "role": "string conversation partner role",
    "situation": "string situation description",
    "hiddenTargets": ["lang:lemma"],
    "culturalNotes": ["string"],
    "successCriteria": {
      "spontaneousTargetCount": 2
    }
  }
}
''';

    final userPrompt = '''
Target Language: $targetLanguage
Support Language: $supportLanguage
Learner CEFR Level: $estimatedLevel
Source Title: $sourceTitle
Source Content:
$rawText
$groundingPrompt

Compile the lesson now.
''';

    final response = await _client.post(
      Uri.parse('$nebiusBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $nebiusApiKey',
      },
      body: jsonEncode({
        'model': nebiusModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return jsonDecode(content) as Map<String, dynamic>;
    }
    throw StateError('Nebius API returned status ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _compileWithNvidia({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) async {
    final groundingPrompt = grounding != null
        ? '\nAuthentic Ground Truth Facts:\n${grounding.culturalFacts.map((f) => "- $f").join("\n")}\nStatutory Rules:\n${grounding.statutoryRules.map((r) => "- $r").join("\n")}'
        : '';

    final systemPrompt = '''
You are the Talkloom Pedagogical Lesson Compiler running directly on NVIDIA NIM (Nemotron).
Compile the provided source text into a structured Lesson DSL JSON object.
Return ONLY valid JSON with no markdown backticks or commentary.

JSON Schema:
{
  "objectives": ["string", "string"],
  "vocabulary": [
    {
      "id": "lang:lemma",
      "lemma": "string",
      "article": "string (e.g. der/die/das or empty)",
      "meaning": "string in supportLanguage",
      "sourceContext": "string context sentence from source",
      "learnerState": "recognized_not_active"
    }
  ],
  "grammar": [
    {
      "concept": "string",
      "sourceSentence": "string",
      "explanation": "string in supportLanguage"
    }
  ],
  "activities": [
    {
      "type": "context_choice",
      "targets": ["lang:lemma"],
      "question": "string",
      "options": ["string", "string", "string"],
      "correctIndex": 0
    },
    {
      "type": "sentence_builder",
      "target": "complete target sentence",
      "scrambledTokens": ["token1", "token2", "token3"]
    },
    {
      "type": "speak_response",
      "objective": "string speaking mission objective"
    }
  ],
  "conversation": {
    "role": "string conversation partner role",
    "situation": "string situation description",
    "hiddenTargets": ["lang:lemma"],
    "culturalNotes": ["string"],
    "successCriteria": {
      "spontaneousTargetCount": 2
    }
  }
}
''';

    final userPrompt = '''
Target Language: $targetLanguage
Support Language: $supportLanguage
Learner CEFR Level: $estimatedLevel
Source Title: $sourceTitle
Source Content:
$rawText
$groundingPrompt

Compile the lesson now.
''';

    final response = await _client.post(
      Uri.parse('$nvidiaBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $nvidiaApiKey',
      },
      body: jsonEncode({
        'model': nvidiaModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        'max_tokens': 2500,
        'response_format': {'type': 'json_object'},
        'chat_template_args': {'enable_thinking': false},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return jsonDecode(content) as Map<String, dynamic>;
    }
    throw StateError('NVIDIA NIM API returned status ${response.statusCode}');
  }

  Future<Map<String, dynamic>> _compileWithGroq({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) async {
    final groundingPrompt = grounding != null
        ? '\nAuthentic Ground Truth Facts:\n${grounding.culturalFacts.map((f) => "- $f").join("\n")}\nStatutory Rules:\n${grounding.statutoryRules.map((r) => "- $r").join("\n")}'
        : '';

    final systemPrompt = '''
You are the Talkloom Pedagogical Lesson Compiler powered by Groq LPU (Llama 3.3).
Compile the provided source text into a structured Lesson DSL JSON object.
Return ONLY valid JSON with no markdown backticks or commentary.

JSON Schema:
{
  "objectives": ["string", "string"],
  "vocabulary": [
    {
      "id": "lang:lemma",
      "lemma": "string",
      "article": "string (e.g. der/die/das or empty)",
      "meaning": "string in supportLanguage",
      "sourceContext": "string context sentence from source",
      "learnerState": "recognized_not_active"
    }
  ],
  "grammar": [
    {
      "concept": "string",
      "sourceSentence": "string",
      "explanation": "string in supportLanguage"
    }
  ],
  "activities": [
    {
      "type": "context_choice",
      "targets": ["lang:lemma"],
      "question": "string",
      "options": ["string", "string", "string"],
      "correctIndex": 0
    },
    {
      "type": "sentence_builder",
      "target": "complete target sentence",
      "scrambledTokens": ["token1", "token2", "token3"]
    },
    {
      "type": "speak_response",
      "objective": "string speaking mission objective"
    }
  ],
  "conversation": {
    "role": "string conversation partner role",
    "situation": "string situation description",
    "hiddenTargets": ["lang:lemma"],
    "culturalNotes": ["string"],
    "successCriteria": {
      "spontaneousTargetCount": 2
    }
  }
}
''';

    final userPrompt = '''
Target Language: $targetLanguage
Support Language: $supportLanguage
Learner CEFR Level: $estimatedLevel
Source Title: $sourceTitle
Source Content:
$rawText
$groundingPrompt

Compile the lesson now.
''';

    final response = await _client.post(
      Uri.parse('$groqBaseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['choices'][0]['message']['content'] as String;
      return jsonDecode(content) as Map<String, dynamic>;
    }
    throw StateError('Groq API returned status ${response.statusCode}');
  }

  Map<String, dynamic> _generateFallbackLessonDsl({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) {
    final facts = grounding?.culturalFacts ?? [
      'Authentic communication relies on natural spoken phrasing.',
      'Active listening and repetition reinforce vocabulary recall.'
    ];

    // Extract real sentences and keywords from rawText
    final sentences = rawText
        .split(RegExp(r'[.!?\n]+'))
        .map((s) => s.replaceAll(RegExp(r'\[.*?\]'), '').trim())
        .where((s) => s.length > 20 && s.length < 140 && !s.startsWith('http'))
        .toList();

    // Extract salient words
    final words = rawText
        .split(RegExp(r'[\s,.;:!?()"\[\]]+'))
        .map((w) => w.trim())
        .where((w) => w.length > 4 && !w.startsWith('http') && !w.contains('/'))
        .toSet()
        .toList();

    final vocabList = <Map<String, dynamic>>[];
    for (int i = 0; i < words.length && i < 3; i++) {
      final word = words[i];
      final contextSentence = sentences.firstWhere(
        (s) => s.toLowerCase().contains(word.toLowerCase()),
        orElse: () => sentences.isNotEmpty ? sentences.first : '$word is an important term in $sourceTitle.',
      );
      vocabList.add({
        'id': '$targetLanguage:${word.toLowerCase()}',
        'lemma': word,
        'article': '',
        'meaning': 'Contextual term from video: $word',
        'sourceContext': contextSentence,
        'learnerState': 'recognized_not_active',
      });
    }

    if (vocabList.isEmpty) {
      vocabList.add({
        'id': '$targetLanguage:practice',
        'lemma': 'Practice',
        'article': '',
        'meaning': 'To perform repeatedly so as to become proficient',
        'sourceContext': 'Practice speaking with authentic content.',
        'learnerState': 'recognized_not_active',
      });
    }

    final targetSentence = sentences.isNotEmpty
        ? sentences.first
        : 'Learning conversational expressions from $sourceTitle.';
    final sentenceTokens = targetSentence
        .split(RegExp(r'\s+'))
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(9)
        .toList();

    final activitiesList = <Map<String, dynamic>>[
      {
        'type': 'context_choice',
        'targets': [vocabList.first['id']],
        'question': 'What is the main topic explored in "$sourceTitle"?',
        'options': [
          'Understanding key points and expressions discussed in "$sourceTitle"',
          'An unrelated generic lesson about apartment deposits',
          'A grammar rule without any contextual practice',
        ],
        'correctIndex': 0,
      },
    ];

    if (sentenceTokens.length >= 3) {
      final scrambled = List<String>.from(sentenceTokens)..shuffle();
      activitiesList.add({
        'type': 'sentence_builder',
        'target': sentenceTokens.join(' '),
        'scrambledTokens': scrambled,
      });
    }

    activitiesList.add({
      'type': 'speak_response',
      'objective': 'Summarize what is being discussed in "$sourceTitle" in your own words.',
    });

    return {
      'objectives': [
        'Understand the core dialogue and context of: $sourceTitle',
        'Recognize and pronounce authentic vocabulary from the material',
        'Formulate natural spoken responses based on what happened in the video'
      ],
      'vocabulary': vocabList,
      'grammar': [
        {
          'concept': 'Spoken Discourse Structures',
          'sourceSentence': targetSentence,
          'explanation': 'Spoken language uses pragmatic discourse markers to connect thoughts smoothly.'
        }
      ],
      'activities': activitiesList,
      'conversation': {
        'role': 'Curious Conversation Partner',
        'situation': 'Discussing the ideas, dialogue, and events from "$sourceTitle".',
        'hiddenTargets': vocabList.map((v) => v['lemma'] as String).toList(),
        'culturalNotes': facts,
        'successCriteria': {'spontaneousTargetCount': 1}
      }
    };
  }
}
