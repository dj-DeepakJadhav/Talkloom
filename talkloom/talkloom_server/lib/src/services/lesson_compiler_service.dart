import 'dart:convert';
import 'package:http/http.dart' as http;
import 'tavily_service.dart';

class LessonCompilerService {
  final String nebiusApiKey;
  final String nebiusBaseUrl;
  final String modelName;
  final http.Client _client;

  LessonCompilerService({
    required this.nebiusApiKey,
    this.nebiusBaseUrl = 'https://api.tokenfactory.nebius.com/v1',
    this.modelName = 'nvidia/nemotron-3-8b-instruct',
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
    if (nebiusApiKey.isEmpty) {
      return _generateFallbackLessonDsl(
        sourceTitle: sourceTitle,
        rawText: rawText,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        estimatedLevel: estimatedLevel,
        grounding: grounding,
      );
    }

    try {
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
          'model': modelName,
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
      } else {
        return _generateFallbackLessonDsl(
          sourceTitle: sourceTitle,
          rawText: rawText,
          targetLanguage: targetLanguage,
          supportLanguage: supportLanguage,
          estimatedLevel: estimatedLevel,
          grounding: grounding,
        );
      }
    } catch (_) {
      return _generateFallbackLessonDsl(
        sourceTitle: sourceTitle,
        rawText: rawText,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        estimatedLevel: estimatedLevel,
        grounding: grounding,
      );
    }
  }

  Map<String, dynamic> _generateFallbackLessonDsl({
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    TavilyGroundingResult? grounding,
  }) {
    final isGerman = targetLanguage.toLowerCase().startsWith('de');
    final facts = grounding?.culturalFacts ?? [
      'Authentic communication relies on polite inquiry structures.',
      'Check local terms and conditions thoroughly before committing.'
    ];

    if (isGerman) {
      return {
        "objectives": [
          "Ask about additional costs (Nebenkosten)",
          "Use 'einziehen' naturally in speaking",
          "Form a polite indirect inquiry regarding deposit (Kaution)"
        ],
        "vocabulary": [
          {
            "id": "de:kaution",
            "lemma": "Kaution",
            "article": "die",
            "meaning": "security deposit",
            "sourceContext": "Die Kaution beträgt drei Monatskaltmieten.",
            "learnerState": "recognized_not_active"
          },
          {
            "id": "de:nebenkosten",
            "lemma": "Nebenkosten",
            "article": "die (pl.)",
            "meaning": "utility / extra operating costs",
            "sourceContext": "Sind die Heizkosten bereits in den Nebenkosten enthalten?",
            "learnerState": "recognized_not_active"
          },
          {
            "id": "de:einziehen",
            "lemma": "einziehen",
            "article": "",
            "meaning": "to move in",
            "sourceContext": "Wann können die neuen Mieter frühestens einziehen?",
            "learnerState": "recognized_not_active"
          }
        ],
        "grammar": [
          {
            "concept": "polite_indirect_question",
            "sourceSentence": "Könnten Sie mir bitte mitteilen, wie hoch die Kaution ist?",
            "explanation": "Use 'Könnten Sie...' + dependent subordinate clause with verb at the end for polite inquiries."
          }
        ],
        "activities": [
          {
            "type": "context_choice",
            "targets": ["de:kaution"],
            "question": "What is 'die Kaution' in the context of an apartment contract?",
            "options": [
              "Security deposit paid before moving in",
              "Monthly heating bill",
              "Keys handover certificate"
            ],
            "correctIndex": 0
          },
          {
            "type": "sentence_builder",
            "target": "Wie hoch sind die monatlichen Nebenkosten?",
            "scrambledTokens": ["monatlichen", "die", "Wie", "Nebenkosten?", "hoch", "sind"]
          },
          {
            "type": "speak_response",
            "objective": "Ask the landlord politely when you can move into the apartment."
          }
        ],
        "conversation": {
          "role": "landlord",
          "situation": "apartment viewing in Berlin",
          "hiddenTargets": ["de:kaution", "de:nebenkosten", "de:einziehen"],
          "culturalNotes": facts,
          "successCriteria": {
            "spontaneousTargetCount": 2
          }
        }
      };
    }

    return {
      "objectives": [
        "Inquire about standard terms and conditions",
        "Form a polite direct inquiry",
        "Retell essential elements from the source"
      ],
      "vocabulary": [
        {
          "id": "$targetLanguage:terms",
          "lemma": "terms",
          "article": "the",
          "meaning": "contractual conditions",
          "sourceContext": rawText.length > 30 ? rawText.substring(0, 30) : rawText,
          "learnerState": "recognized_not_active"
        }
      ],
      "grammar": [
        {
          "concept": "polite_inquiry",
          "sourceSentence": "Could you please clarify the details?",
          "explanation": "Use modal auxiliary verbs for polite conversational engagement."
        }
      ],
      "activities": [
        {
          "type": "context_choice",
          "targets": ["$targetLanguage:terms"],
          "question": "What is the primary condition discussed?",
          "options": ["Contractual terms", "Meeting schedule", "Cancellation fee"],
          "correctIndex": 0
        },
        {
          "type": "sentence_builder",
          "target": "Could you please clarify the terms?",
          "scrambledTokens": ["clarify", "please", "Could", "the", "you", "terms?"]
        },
        {
          "type": "speak_response",
          "objective": "Politely ask for confirmation of the terms."
        }
      ],
      "conversation": {
        "role": "discussion partner",
        "situation": "discussing the imported source material",
        "hiddenTargets": ["$targetLanguage:terms"],
        "culturalNotes": facts,
        "successCriteria": {
          "spontaneousTargetCount": 1
        }
      }
    };
  }
}
