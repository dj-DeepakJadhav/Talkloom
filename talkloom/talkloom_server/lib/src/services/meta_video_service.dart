import 'dart:convert';
import 'package:http/http.dart' as http;
import 'meta_models.dart';

/// Video understanding via the Meta Model API (Responses API + input_video).
///
/// Given a *direct* public mp4 URL, Muse Spark watches the footage and its
/// embedded audio together, returning a summary plus timestamped chapters.
/// YouTube watch pages are not direct video files — resolving those to
/// playable URLs is a separate step (Goal 3, tick 2).
class MetaVideoService {
  MetaVideoService({
    http.Client? client,
    required this.apiKey,
    this.model = kMetaMultimodalModel,
    this.baseUrl = kMetaBaseUrl,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;
  final String model;
  final String baseUrl;

  /// Describes the video at [videoUrl]. Returns predictive chapter data:
  /// `{summary: String, chapters: [{start, end, title}]}`. Times are
  /// `MM:SS` strings as produced by the model.
  Future<Map<String, dynamic>> describeVideo(
    String videoUrl, {
    required String language,
  }) async {
    final uri = Uri.tryParse(videoUrl.trim());
    if (uri == null ||
        !(uri.scheme == 'http' || uri.scheme == 'https') ||
        !uri.path.toLowerCase().endsWith('.mp4')) {
      throw ArgumentError('A public http(s) .mp4 URL is required.');
    }
    if (apiKey.isEmpty) {
      throw StateError('Meta Model API key is not configured.');
    }
    final languageName = switch (language.toLowerCase().split(RegExp('[-_]')).first) {
      'de' => 'German',
      'en' => 'English',
      'es' => 'Spanish',
      'fr' => 'French',
      'it' => 'Italian',
      _ => throw ArgumentError('This language is not supported: $language'),
    };

    final response = await _client
        .post(
          Uri.parse('$baseUrl/responses'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'reasoning': {'effort': 'low'},
            'input': [
              {
                'type': 'message',
                'role': 'user',
                'content': [
                  {
                    'type': 'input_text',
                    'text':
                        'Watch this video (frames and speech together). Reply in $languageName as JSON only, no prose: {"summary": "2-3 sentences on what happens", "chapters": [{"start": "MM:SS", "end": "MM:SS", "title": "short chapter title"}]}. Cover the whole video with 3-8 chapters in order. Base every title on something actually seen or heard.',
                  },
                  {
                    'type': 'input_video',
                    'video_url': uri.toString(),
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(minutes: 10));

    if (response.statusCode != 200) {
      throw StateError(
        'Meta video understanding failed (HTTP ${response.statusCode}).',
      );
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw StateError('Meta video understanding returned no data.');
    }
    final output = data['output'];
    if (output is! List) {
      throw StateError('Meta video understanding returned no output.');
    }
    final texts = [
      for (final item in output)
        if (item is Map)
          for (final part in (item['content'] as List? ?? const []))
            if (part is Map && part['type'] == 'output_text')
              part['text'].toString(),
    ].join('\n');
    final cleaned = texts
        .trim()
        .replaceAll(RegExp(r'^```(?:json)?', multiLine: true), '')
        .replaceAll(RegExp(r'```\s*$'), '')
        .trim();
    try {
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) {
        return {
          'summary': parsed['summary']?.toString() ?? cleaned,
          'chapters': parsed['chapters'] is List ? parsed['chapters'] : const [],
        };
      }
    } on FormatException {
      // Fall through to the plain-text response.
    }
    return {'summary': cleaned, 'chapters': const []};
  }
}
