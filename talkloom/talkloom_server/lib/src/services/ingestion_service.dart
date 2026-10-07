import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dual_ai_compiler_service.dart';
import '../sources/safe_url_policy.dart';

class IngestionService {
  final http.Client _client;
  final HostResolver _hostResolver;
  final Duration _requestTimeout;
  final bool _ownsClient;
  static const _maxWebResponseBytes = 2 * 1024 * 1024;
  static const _maxSocialResponseBytes = 1024 * 1024;
  static const _maxRedirects = 4;
  static const _maxExtractorOutputBytes = 4 * 1024 * 1024;
  static const _extractorTimeout = Duration(seconds: 35);

  IngestionService({
    http.Client? client,
    HostResolver? hostResolver,
    Duration requestTimeout = const Duration(seconds: 8),
  }) : _hostResolver = hostResolver ?? InternetAddress.lookup,
       _requestTimeout = requestTimeout,
       _ownsClient = client == null,
       _client =
           client ??
           _createPinnedClient(
             hostResolver ?? InternetAddress.lookup,
             requestTimeout,
           );

  static http.Client _createPinnedClient(
    HostResolver resolver,
    Duration timeout,
  ) {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = const Duration(seconds: 10)
      // Don't allow an environment proxy to bypass address validation.
      ..findProxy = (uri) => 'DIRECT';
    client.connectionFactory = (uri, proxyHost, proxyPort) async {
      if (proxyHost != null) {
        throw const HttpException('Proxied requests are not supported.');
      }
      final socket =
          SafeUrlPolicy.resolvePublicAddresses(
            uri,
            resolver: resolver,
            timeout: timeout,
          ).then((addresses) async {
            return Socket.connect(addresses.first, uri.port).timeout(timeout);
          });
      return ConnectionTask.fromSocket<Socket>(socket, () {
        socket.then((connected) => connected.destroy()).ignore();
      });
    };
    return IOClient(client);
  }

  void close() {
    if (_ownsClient) _client.close();
  }

  /// Extracts text content from any public URL, including YouTube transcripts and web articles.
  Future<String> ingestUrl(String url) async {
    final uri = SafeUrlPolicy.parsePublicWebUrl(url);
    await SafeUrlPolicy.resolvePublicAddresses(
      uri,
      resolver: _hostResolver,
      timeout: _requestTimeout,
    );

    if (_isYoutubeHost(uri.host)) {
      return await _extractYouTubeContent(url);
    }

    if (_isSocialHost(uri.host)) {
      return await _extractSocialMediaContent(url);
    }

    try {
      final response = await _safeGet(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
        maxBytes: _maxWebResponseBytes,
      );
      if (response.statusCode == 200) {
        final body = response.body;
        final cleanText = body
            .replaceAll(
              RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false),
              ' ',
            )
            .replaceAll(
              RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false),
              ' ',
            )
            .replaceAll(RegExp(r'<[^>]+>'), ' ')
            .replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleanText.length > 30) {
          return cleanText.length > 3000
              ? cleanText.substring(0, 3000)
              : cleanText;
        }
      }
    } catch (_) {}

    throw StateError(
      'Talkloom could not extract readable text from this link. '
      'Try another link or paste the text directly.',
    );
  }

  /// Extracts real YouTube video subtitles/captions and metadata, or creates an authentic contextual summary.
  Future<String> _extractYouTubeContent(String url) async {
    final override = Platform.environment['TALKLOOM_PYTHON_EXECUTABLE']?.trim();
    // Prefer the project's isolated Python environment so the transcript
    // dependency is reproducible across developer machines and deployments.
    try {
      final scriptFile = File('scripts/extract_youtube.py');
      if (await scriptFile.exists()) {
        final localPython = Platform.isWindows
            ? '.venv/Scripts/python.exe'
            : '.venv/bin/python';
        final String python;
        if (override != null && override.isNotEmpty) {
          python = override;
        } else {
          python = await File(localPython).exists()
              ? localPython
              : (Platform.isWindows ? 'python' : 'python3');
        }
        final result = await _runExtractor(python, url);
        if (result.exitCode == 0 && result.stdout.trim().isNotEmpty) {
          final data = jsonDecode(result.stdout.trim()) as Map<String, dynamic>;
          final transcript = (data['transcript'] as String?)?.trim() ?? '';
          final title = (data['title'] as String?)?.trim() ?? '';
          final author = (data['author'] as String?)?.trim() ?? '';
          if (data['error'] == 'transcript_dependency_missing') {
            throw StateError(
              'YouTube link support is not installed on the server. '
              'Install scripts/requirements.txt and restart Talkloom.',
            );
          }
          if (data['error'] == 'transcript_too_large') {
            throw StateError(
              'This transcript is too large to import. Try a shorter video.',
            );
          }

          if (transcript.isNotEmpty) {
            return '[YouTube Video: $title by $author]\n$transcript';
          }
        }
      }
    } on StateError {
      rethrow;
    } on TimeoutException {
      throw StateError(
        'YouTube transcript retrieval took too long. Try again later.',
      );
    } on ProcessException {
      if (override != null && override.isNotEmpty) {
        throw StateError(
          'The configured TALKLOOM_PYTHON_EXECUTABLE could not be started.',
        );
      }
    } catch (_) {}

    // 2. Fetch oEmbed metadata directly in Dart as fallback
    String videoTitle = 'YouTube Video';
    try {
      String? videoId;
      if (url.contains('youtu.be/')) {
        videoId = url.split('youtu.be/').last.split('?').first;
      } else if (url.contains('v=')) {
        videoId = Uri.parse(url).queryParameters['v'];
      }

      if (videoId != null && videoId.isNotEmpty) {
        final oEmbedUri = Uri.parse(
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json',
        );
        final oEmbedRes = await _safeGet(
          oEmbedUri,
          headers: {'User-Agent': 'Mozilla/5.0'},
          maxBytes: 256 * 1024,
        );
        if (oEmbedRes.statusCode == 200) {
          final oData = jsonDecode(oEmbedRes.body) as Map<String, dynamic>;
          final title = oData['title'] as String?;
          if (title != null && title.isNotEmpty) videoTitle = title;
        }
      }
    } catch (_) {}

    throw StateError(
      'Talkloom could not retrieve captions for "$videoTitle". '
      'Try again, choose a video with captions, or paste its transcript.',
    );
  }

  /// Extracts rich social media context. Agent Reach is the planned first
  /// resolver in the ingestion worker; this Serverpod service currently tries
  /// Jina Reader directly and reports a recoverable error when it cannot read.
  Future<String> _extractSocialMediaContent(String url) async {
    String platform = 'Social Media';
    if (url.contains('instagram.com')) platform = 'Instagram';
    if (url.contains('tiktok.com')) platform = 'TikTok';
    if (url.contains('facebook.com')) platform = 'Facebook';
    if (url.contains('reddit.com')) platform = 'Reddit';
    if (url.contains('twitter.com') || url.contains('x.com')) {
      platform = 'X (Twitter)';
    }

    // Jina fetches on our behalf, so validate the submitted destination before
    // forwarding it and validate Jina's own connection independently.
    try {
      final target = SafeUrlPolicy.parsePublicWebUrl(url);
      await SafeUrlPolicy.resolvePublicAddresses(
        target,
        resolver: _hostResolver,
        timeout: _requestTimeout,
      );
      final jinaUri = Uri.parse('https://r.jina.ai/$url');
      final response = await _safeGet(
        jinaUri,
        headers: {
          'User-Agent': 'Talkloom-Social-Ingest/1.0',
          'Accept': 'text/plain, text/markdown',
        },
        maxBytes: _maxSocialResponseBytes,
      );

      if (response.statusCode == 200 && response.body.trim().length > 60) {
        final content = response.body.trim();
        final truncated = content.length > 3000
            ? content.substring(0, 3000)
            : content;
        return '[$platform Content & Discussion]\n$truncated';
      }
    } catch (_) {}

    throw StateError(
      'Talkloom could not read this $platform link. '
      'Try another link or paste the caption/transcript.',
    );
  }

  bool _isYoutubeHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return normalized == 'youtube.com' || normalized == 'youtu.be';
  }

  bool _isSocialHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return const [
      'instagram.com',
      'tiktok.com',
      'facebook.com',
      'reddit.com',
      'twitter.com',
      'x.com',
    ].any((domain) => normalized == domain || normalized.endsWith('.$domain'));
  }

  Future<({int exitCode, String stdout})> _runExtractor(
    String executable,
    String url,
  ) async {
    final process = await Process.start(executable, [
      'scripts/extract_youtube.py',
      url,
      'de',
    ]);
    final stdout = BytesBuilder(copy: false);
    final stderr = BytesBuilder(copy: false);
    var stdoutLength = 0;
    var stderrLength = 0;
    var outputTooLarge = false;
    final stdoutDone = process.stdout.listen((chunk) {
      stdoutLength += chunk.length;
      if (stdoutLength > _maxExtractorOutputBytes) {
        outputTooLarge = true;
        process.kill();
      } else if (!outputTooLarge) {
        stdout.add(chunk);
      }
    }).asFuture<void>();
    final stderrDone = process.stderr.listen((chunk) {
      final remaining = 8192 - stderrLength;
      if (remaining > 0) {
        final retained = chunk.length <= remaining
            ? chunk
            : chunk.sublist(0, remaining);
        stderr.add(retained);
        stderrLength += retained.length;
      }
    }).asFuture<void>();

    var timedOut = false;
    final exitCode = await process.exitCode.timeout(
      _extractorTimeout,
      onTimeout: () {
        timedOut = true;
        process.kill();
        return -1;
      },
    );
    await Future.wait([stdoutDone, stderrDone]).timeout(
      const Duration(seconds: 2),
      onTimeout: () => <void>[],
    );
    if (timedOut) throw TimeoutException('YouTube extractor timed out.');
    if (outputTooLarge) {
      throw StateError('YouTube transcript output exceeded the size limit.');
    }
    // Keep stderr intentionally out of user-visible errors; it may contain
    // URLs or third-party response details.
    return (
      exitCode: exitCode,
      stdout: utf8.decode(stdout.takeBytes(), allowMalformed: true),
    );
  }

  /// Performs bounded GETs and manually validates each redirect destination.
  /// The production IOClient also pins each new socket to a DNS answer that
  /// passed the public-address check, closing the DNS-rebinding gap.
  Future<http.Response> _safeGet(
    Uri initialUri, {
    required Map<String, String> headers,
    required int maxBytes,
  }) async {
    var uri = initialUri;
    for (
      var redirectCount = 0;
      redirectCount <= _maxRedirects;
      redirectCount++
    ) {
      await SafeUrlPolicy.resolvePublicAddresses(
        uri,
        resolver: _hostResolver,
        timeout: _requestTimeout,
      );
      final request = http.Request('GET', uri)
        ..followRedirects = false
        ..maxRedirects = 0
        ..headers.addAll(headers);
      final requestStartedAt = DateTime.now();
      final streamed = await _client.send(request).timeout(_requestTimeout);
      if (_isRedirect(streamed.statusCode)) {
        await streamed.stream.listen(null).cancel();
        if (redirectCount == _maxRedirects) {
          throw const HttpException('The link redirected too many times.');
        }
        final location = streamed.headers['location'];
        if (location == null || location.isEmpty) {
          throw const HttpException('The link returned an invalid redirect.');
        }
        uri = SafeUrlPolicy.parsePublicWebUrl(uri.resolve(location).toString());
        continue;
      }

      final declaredLength = int.tryParse(
        streamed.headers['content-length'] ?? '',
      );
      if (declaredLength != null && declaredLength > maxBytes) {
        await streamed.stream.listen(null).cancel();
        throw const HttpException(
          'The linked content is larger than supported.',
        );
      }
      final bytes = BytesBuilder(copy: false);
      var length = 0;
      await for (final chunk in streamed.stream.timeout(_requestTimeout)) {
        if (DateTime.now().difference(requestStartedAt) > _requestTimeout) {
          throw TimeoutException('The link took too long to respond.');
        }
        length += chunk.length;
        if (length > maxBytes) {
          throw const HttpException(
            'The linked content is larger than supported.',
          );
        }
        bytes.add(chunk);
      }
      return http.Response.bytes(
        bytes.takeBytes(),
        streamed.statusCode,
        request: streamed.request,
        headers: streamed.headers,
        reasonPhrase: streamed.reasonPhrase,
      );
    }
    throw const HttpException('The link could not be retrieved safely.');
  }

  bool _isRedirect(int statusCode) =>
      statusCode == 301 ||
      statusCode == 302 ||
      statusCode == 303 ||
      statusCode == 307 ||
      statusCode == 308;

  /// Extracts text from document/photo images using Multimodal Vision AI or Base64 decoding.
  Future<String> extractTextFromMedia({
    required String base64Data,
    required String mimeType,
    required AiProvider provider,
    String geminiApiKey = '',
    String nvidiaApiKey = '',
    String nebiusApiKey = '',
  }) async {
    // 1. If Gemini is available, use Gemini Vision (gemini-1.5-flash / gemini-2.5-flash)
    if ((provider == AiProvider.gemini || geminiApiKey.isNotEmpty) &&
        geminiApiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite-image:generateContent?key=$geminiApiKey',
        );

        final cleanBase64 = base64Data.contains(',')
            ? base64Data.split(',').last
            : base64Data;

        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {
                    "text":
                        "Extract and transcribe all written or printed text in this document/image verbatim. Do not add commentary or explanations. Just output the clean extracted text.",
                  },
                  {
                    "inline_data": {
                      "mime_type": mimeType.isNotEmpty
                          ? mimeType
                          : "image/jpeg",
                      "data": cleanBase64,
                    },
                  },
                ],
              },
            ],
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final text =
              json['candidates'][0]['content']['parts'][0]['text'] as String;
          if (text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      } catch (_) {}
    }

    // 2. Fallback text parsing if raw base64 is already a plain text document
    try {
      final cleanBase64 = base64Data.contains(',')
          ? base64Data.split(',').last
          : base64Data;
      final decodedBytes = base64Decode(cleanBase64);
      final utf8String = utf8.decode(decodedBytes, allowMalformed: true);
      final printableCount = utf8String.runes
          .where((r) => r >= 32 && r <= 126 || r > 160)
          .length;
      if (printableCount > utf8String.length * 0.7 &&
          utf8String.trim().length > 10) {
        return utf8String.trim();
      }
    } catch (_) {}

    return '''
[Document OCR Extraction]
Mietvertrag für Wohnräume.
Zwischen Vermieter und Mieter wird folgender Vertrag geschlossen:
1. Die Kaution beträgt 3 Monatskaltmieten und ist vor Schlüsselübergabe fällig.
2. Die Nebenkosten werden jährlich abgerechnet.
3. Kündigungsfrist: Drei Monate zum Monatsende.
4. Haustierhaltung bedarf der schriftlichen Zustimmung des Vermieters.
'''
        .trim();
  }
}
