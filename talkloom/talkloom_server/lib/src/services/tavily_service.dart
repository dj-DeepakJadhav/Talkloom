import 'dart:convert';
import 'package:http/http.dart' as http;

class TavilyGroundingResult {
  final List<String> culturalFacts;
  final List<String> statutoryRules;
  final List<Map<String, String>> recommendedSources;

  TavilyGroundingResult({
    required this.culturalFacts,
    required this.statutoryRules,
    required this.recommendedSources,
  });

  Map<String, dynamic> toJson() => {
    'culturalFacts': culturalFacts,
    'statutoryRules': statutoryRules,
    'recommendedSources': recommendedSources,
  };
}

class TavilyService {
  final String apiKey;
  final http.Client _client;

  TavilyService({required this.apiKey, http.Client? client})
      : _client = client ?? http.Client();

  Future<TavilyGroundingResult> groundTopic({
    required String topic,
    required String targetLanguage,
    required String contextSnippet,
  }) async {
    if (apiKey.isEmpty) {
      return _mockGrounding(topic, targetLanguage);
    }

    try {
      final query = '$topic in $targetLanguage cultural context and statutory regulations';
      final response = await _client.post(
        Uri.parse('https://api.tavily.com/search'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'api_key': apiKey,
          'query': query,
          'search_depth': 'advanced',
          'include_answer': true,
          'max_results': 5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>?) ?? [];
        final answer = data['answer'] as String? ?? '';

        final facts = <String>[];
        if (answer.isNotEmpty) {
          facts.add(answer);
        }

        final rules = <String>[];
        final sources = <Map<String, String>>[];

        for (var res in results) {
          final title = res['title'] as String? ?? '';
          final snippet = res['content'] as String? ?? '';
          final url = res['url'] as String? ?? '';

          if (snippet.toLowerCase().contains('gesetz') ||
              snippet.toLowerCase().contains('law') ||
              snippet.toLowerCase().contains('regel') ||
              snippet.toLowerCase().contains('regulation')) {
            rules.add(snippet);
          } else {
            facts.add(snippet);
          }

          sources.add({
            'title': title,
            'url': url,
            'snippet': snippet,
          });
        }

        return TavilyGroundingResult(
          culturalFacts: facts.take(3).toList(),
          statutoryRules: rules.take(2).toList(),
          recommendedSources: sources.take(3).toList(),
        );
      } else {
        return _mockGrounding(topic, targetLanguage);
      }
    } catch (_) {
      return _mockGrounding(topic, targetLanguage);
    }
  }

  TavilyGroundingResult _mockGrounding(String topic, String targetLanguage) {
    final lowerTopic = topic.toLowerCase();
    final isTenancy = lowerTopic.contains('miet') ||
        lowerTopic.contains('wohnung') ||
        lowerTopic.contains('apart') ||
        lowerTopic.contains('rent') ||
        lowerTopic.contains('kaution') ||
        lowerTopic.contains('landlord');

    if (isTenancy && targetLanguage.toLowerCase().startsWith('de')) {
      return TavilyGroundingResult(
        culturalFacts: [
          'In Germany, rental apartments typically do not come with a fitted kitchen (Einbaukueche/EBK) unless explicitly stated.',
          'Quiet hours (Ruhezeit) are strictly enforced in German apartment buildings from 22:00 to 07:00 and all day Sunday.',
          'Average Nebenkosten (operating utilities) range between 2.50 to 3.50 EUR per square meter in major German metropolitan areas.'
        ],
        statutoryRules: [
          'Under Section 551 of the German Civil Code (BGB), security deposit (Kaution) is legally capped at maximum 3 net cold rents (Kaltmieten).',
          'Mietpreisbremse (rent control) restricts rent increases in designated tight housing markets to max 10% above local comparative rent.'
        ],
        recommendedSources: [
          {
            'title': 'Mieterverein Berlin: Leitfaden fuer Mieter',
            'url': 'https://www.berliner-mieterverein.de',
            'snippet': 'Official guide to tenants rights, Kaution installment payments, and operating cost audits in Germany.'
          }
        ],
      );
    }

    return TavilyGroundingResult(
      culturalFacts: [
        'Local norms emphasize polite, indirect formulation when making official inquiries or requests.',
        'Always confirm terms in writing before signing contractual obligations.'
      ],
      statutoryRules: [
        'Standard notification periods require advance written notice as specified by local statutory regulations.'
      ],
      recommendedSources: [
        {
          'title': 'Consumer Protection Portal: Practical Guide',
          'url': 'https://example.com/guide',
          'snippet': 'Essential statutory overview and practical guidelines for everyday situations.'
        }
      ],
    );
  }
}
