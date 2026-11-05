import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:serverpod/serverpod.dart';
import 'agent_reach_worker_adapter.dart';
import 'agent_reach_youtube_resolver.dart';
import 'dw_learn_german.dart';
import 'embedded_lesson_resolver.dart';
import 'meta_speech_service.dart';
import '../generated/protocol.dart' show ImportException;
import '../sources/safe_url_policy.dart';
import '../sources/target_language_guard.dart';
import 'meta_models.dart';

class IngestionService {
  final http.Client _client;
  final HostResolver _hostResolver;
  final Duration _requestTimeout;
  final bool _ownsClient;
  final AgentReachWorkerAdapter _agentReachWorker;
  final AgentReachYouTubeResolver _agentReachYouTubeResolver;

  /// Returns mono 16 kHz WAV audio for a video, or null when unavailable.
  final Future<Uint8List?> Function(String url) _audioDownloader;

  /// Returns a transcript for WAV audio, or null when it cannot be produced.
  final Future<String?> Function(Uint8List wav, String apiKey)
  _audioTranscriber;
  static const _audioFallbackSeconds = 420;
  static const _minAudioTranscriptChars = 60;
  static const _maxWebResponseBytes = 2 * 1024 * 1024;
  static const _maxSocialResponseBytes = 1024 * 1024;
  static const _maxRedirects = 4;
  static const _maxExtractorOutputBytes = 4 * 1024 * 1024;
  static const _extractorTimeout = Duration(seconds: 35);

  IngestionService({
    http.Client? client,
    HostResolver? hostResolver,
    AgentReachWorkerAdapter? agentReachWorker,
    AgentReachYouTubeResolver? agentReachYouTubeResolver,
    Duration requestTimeout = const Duration(seconds: 8),
    Future<Uint8List?> Function(String url)? audioDownloader,
    Future<String?> Function(Uint8List wav, String apiKey)? audioTranscriber,
  }) : _hostResolver = hostResolver ?? InternetAddress.lookup,
       _audioDownloader = audioDownloader ?? _downloadYouTubeAudio,
       _audioTranscriber = audioTranscriber ?? _transcribeWithMeta,
       _agentReachWorker = agentReachWorker ?? AgentReachWorkerAdapter(),
       _agentReachYouTubeResolver =
           agentReachYouTubeResolver ?? AgentReachYouTubeResolver(),
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
            Object? lastError;
            for (final address in addresses) {
              Socket? raw;
              try {
                raw = await Socket.connect(address, uri.port).timeout(timeout);
                if (uri.scheme != 'https') return raw;
                // The factory replaces HttpClient's own connect, so TLS must
                // be done here, against the host name rather than the pinned
                // address.
                return await SecureSocket.secure(
                  raw,
                  host: uri.host,
                ).timeout(timeout);
              } catch (e) {
                raw?.destroy();
                lastError = e;
              }
            }
            throw lastError ??
                SocketException('Failed to connect to ${uri.host}');
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
  Future<String> ingestUrl(
    String url, {
    String? userScopeId,
    Session? session,
    String metaApiKey = '',
  }) async {
    final uri = SafeUrlPolicy.parsePublicWebUrl(url);
    await SafeUrlPolicy.resolvePublicAddresses(
      uri,
      resolver: _hostResolver,
      timeout: _requestTimeout,
    );

    if (_isYoutubeHost(uri.host)) {
      return await _extractYouTubeContent(
        url,
        userScopeId: userScopeId,
        metaApiKey: metaApiKey,
      );
    }

    // Embedded lesson data first: JS-rendered lesson sites show readers
    // only an English shell while the German lesson hides in page JSON
    // (Apollo/Next/Nuxt state, JSON-LD, subtitle tracks). One generic
    // resolver with per-site adapters; misses fall through to the readers.
    try {
      final embedded = await _safeGet(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
        maxBytes: _maxWebResponseBytes,
      );
      session?.log(
        'Embedded fetch ${uri.host}: status=${embedded.statusCode} '
        'bytes=${embedded.body.length}',
      );
      if (embedded.statusCode == 200) {
        final lesson = await EmbeddedLessonResolver.resolveFromHtml(
          html: embedded.body,
          fetchText: (subtitleUrl) async {
            try {
              final sub = await _safeGet(
                Uri.parse(subtitleUrl),
                headers: const {'Accept': 'text/vtt,text/plain,*/*'},
                maxBytes: 512 * 1024,
              );
              session?.log(
                'Embedded subtitle $subtitleUrl: status=${sub.statusCode} '
                'bytes=${sub.body.length}',
              );
              return sub.statusCode == 200 ? sub.body : null;
            } catch (_) {
              return null;
            }
          },
        );
        session?.log(
          'Embedded resolver ${uri.host}: '
          '${lesson == null ? 'miss' : 'hit len=${lesson.length}'}',
        );
        if (lesson != null && lesson.trim().length > 60) return lesson;
      }
    } catch (_) {
      // Fall through to the readers below.
    }

    // Google Docs / Sheets links: public files export as plain text/CSV.
    // Private files return a login page, which becomes guidance, never a
    // lesson.
    if (uri.host == 'docs.google.com' || uri.host == 'drive.google.com') {
      return await _extractGoogleDoc(uri);
    }

    if (_isSocialHost(uri.host)) {
      return await _extractSocialMediaContent(
        url,
        userScopeId: userScopeId,
        metaApiKey: metaApiKey,
      );
    }

    try {
      final resolved = await _agentReachWorker.resolveUrlContent(
        uri,
        userScopeId: userScopeId,
      );
      if (resolved != null && resolved.text.trim().length > 60) {
        final heading = [
          if (resolved.title?.isNotEmpty == true) resolved.title!,
          if (resolved.author?.isNotEmpty == true) 'by ${resolved.author}',
        ].join(' ');
        return '[${resolved.channel} content${heading.isEmpty ? '' : ': $heading'}]\n'
            '${resolved.text.trim()}';
      }
    } catch (_) {
      // Agent Reach is optional; continue through Talkloom's public reader.
    }

    ImportException? primaryFailure;
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
      if (response.statusCode != 200) {
        primaryFailure = _importFailureForStatus(response.statusCode, uri.host);
      } else {
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
        if (cleanText.length > 60 &&
            !cleanText.toLowerCase().contains(
              'enable javascript to run this app',
            )) {
          return cleanText.length > 5000
              ? cleanText.substring(0, 5000)
              : cleanText;
        }
        primaryFailure = ImportException(
          code: 'no_text',
          message:
              'This page has no text Talkloom can read. It may load its content '
              'with JavaScript. Paste the text instead.',
        );
      }
    } on ImportException catch (e) {
      primaryFailure = e;
    } on TimeoutException {
      primaryFailure = ImportException(
        code: 'timeout',
        message:
            '${uri.host} took too long to respond. Try again in a moment, or '
            'paste the text instead.',
      );
    } catch (_) {
      primaryFailure = ImportException(
        code: 'unreachable',
        message:
            'Talkloom could not reach ${uri.host}. Check the link, or paste '
            'the text instead.',
      );
    }

    // Try reader proxy as a secondary resolver before giving up.
    try {
      final jinaUri = Uri.parse('https://r.jina.ai/$url');
      final jinaResponse = await _safeGet(
        jinaUri,
        headers: {
          'User-Agent': 'Talkloom-Web-Ingest/1.0',
          'Accept': 'text/plain, text/markdown',
        },
        maxBytes: _maxWebResponseBytes,
      );
      if (jinaResponse.statusCode == 200) {
        final jinaText = jinaResponse.body.trim();
        if (jinaText.length > 60) {
          return jinaText.length > 5000
              ? jinaText.substring(0, 5000)
              : jinaText;
        }
      }
    } catch (_) {}

    throw primaryFailure;
  }

  ImportException _importFailureForStatus(int status, String host) {
    if (status == 401 || status == 403 || status == 429 || status == 503) {
      return ImportException(
        code: 'blocked',
        message:
            '$host blocks automated readers, so Talkloom cannot open this '
            'link. Open it in your browser and paste the text instead.',
      );
    }
    if (status == 404 || status == 410) {
      return ImportException(
        code: 'not_found',
        message: 'This page no longer exists ($status). Check the link.',
      );
    }
    return ImportException(
      code: 'unavailable',
      message:
          '$host answered with an error ($status). Try again later, or paste '
          'the text instead.',
    );
  }

  /// Resolves real YouTube captions from ordered upstreams.
  Future<String> _extractYouTubeContent(
    String url, {
    String? userScopeId,
    String metaApiKey = '',
  }) async {
    try {
      final resolved = await _agentReachWorker.resolveYouTubeTranscript(
        Uri.parse(url),
        targetLanguage: youTubeTargetLanguage,
        userScopeId: userScopeId,
      );
      if (resolved != null && resolved.text.trim().isNotEmpty) {
        final title = resolved.title?.isNotEmpty == true
            ? resolved.title!
            : 'YouTube Video';
        final author = resolved.author ?? '';
        return '${youTubeCaptionHeader(title: title, author: author)}\n'
            '${resolved.text}';
      }
    } catch (_) {
      // Agent Reach is optional; continue to Talkloom's local upstreams.
    }

    // Agent Reach's pattern is health-checked upstream selection with a
    // platform-specific fallback. The CLI adapter is preferred; a direct
    // yt-dlp upstream then precedes Talkloom's existing transcript API.
    try {
      final captions = await _agentReachYouTubeResolver.resolve(
        url,
        targetLanguage: youTubeTargetLanguage,
      );
      if (captions != null && captions.transcript.trim().isNotEmpty) {
        final title = captions.title.isEmpty ? 'YouTube Video' : captions.title;
        return '${youTubeCaptionHeader(title: title, author: '')}\n'
            '${captions.transcript}';
      }
    } catch (_) {
      // An upstream failure should not prevent the regular resolver from
      // trying its independent transcript API.
    }

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
              'YouTube captions are unavailable right now. '
              'Try again later, or paste the transcript.',
            );
          }
          if (data['error'] == 'transcript_too_large') {
            throw StateError(
              'This transcript is too large to import. Try a shorter video.',
            );
          }

          if (transcript.isNotEmpty) {
            final description = (data['description'] as String?)?.trim() ?? '';
            final body = description.isNotEmpty
                ? '$transcript\n\n[Video Description & Notes]\n$description'
                : transcript;
            return '${youTubeCaptionHeader(title: title, author: author, language: data['language'] as String?, isGenerated: data['isGenerated'] == true, translated: data['translated'] == true)}\n$body';
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

    // Last resort: no usable captions. Transcribe the spoken audio with Muse
    // Voice. Needs a Meta key plus yt-dlp and ffmpeg on the server; without
    // them this stays null and the learner gets the guidance below.
    if (metaApiKey.isNotEmpty) {
      try {
        final wav = await _audioDownloader(url);
        if (wav != null && wav.isNotEmpty) {
          final transcript = (await _audioTranscriber(wav, metaApiKey))?.trim();
          if (transcript != null &&
              transcript.length >= _minAudioTranscriptChars) {
            return '[YouTube Video: $videoTitle | audio-transcription: '
                'spoken German transcribed by Muse Voice from the first '
                '${_audioFallbackSeconds ~/ 60} minutes; words may be '
                'misheard]\n$transcript';
          }
        }
      } catch (_) {
        // Fall through to the actionable error below.
      }
    }

    throw StateError(
      'Talkloom could not retrieve captions for "$videoTitle". '
      'Try again, choose a video with captions, or paste its transcript.',
    );
  }

  /// Downloads the first minutes of a video's audio as mono 16 kHz WAV, the
  /// format Muse Voice accepts. Returns null when yt-dlp/ffmpeg are missing or
  /// the download fails or times out.
  static Future<Uint8List?> _downloadYouTubeAudio(String url) async {
    final directory = await Directory.systemTemp.createTemp('talkloom-audio-');
    Process? process;
    try {
      const args = [
        '--no-warnings',
        '--no-progress',
        '--no-playlist',
        '-f',
        'bestaudio',
        '-x',
        '--audio-format',
        'wav',
        '--postprocessor-args',
        'ffmpeg:-ac 1 -ar 16000 -t $_audioFallbackSeconds',
      ];
      // yt-dlp may live on PATH (local dev) or in the production Python
      // venv (/opt/talkloom-python, see Dockerfile). Try both.
      final outputTemplate =
          '${directory.path}${Platform.pathSeparator}audio.%(ext)s';
      try {
        process = await Process.start('yt-dlp', [
          ...args,
          '-o',
          outputTemplate,
          url,
        ]);
      } catch (_) {
        final venvYtDlp =
            '${Platform.pathSeparator}opt${Platform.pathSeparator}talkloom-python${Platform.pathSeparator}bin${Platform.pathSeparator}yt-dlp';
        if (!await File(venvYtDlp).exists()) rethrow;
        process = await Process.start(venvYtDlp, [
          ...args,
          '-o',
          outputTemplate,
          url,
        ]);
      }
      // Drain output so a full pipe cannot stall the process.
      process.stdout.drain<void>().ignore();
      process.stderr.drain<void>().ignore();
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 150),
      );
      if (exitCode != 0) return null;
      final file = File('${directory.path}${Platform.pathSeparator}audio.wav');
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      // Muse Voice accepts 1 KB to 15 MB.
      return bytes.length < 1000 || bytes.length > 15 * 1024 * 1024
          ? null
          : bytes;
    } catch (_) {
      process?.kill();
      return null;
    } finally {
      await directory.delete(recursive: true).catchError((_) => directory);
    }
  }

  static Future<String?> _transcribeWithMeta(
    Uint8List wav,
    String apiKey,
  ) async {
    final service = MetaSpeechService(apiKey: apiKey);
    try {
      return await service.transcribe(base64Encode(wav), language: 'de');
    } catch (_) {
      return null;
    }
  }

  /// Public Google Docs/Sheets via their export endpoints. Only files
  /// shared as "anyone with the link" export; everything else 401s or
  /// returns the sign-in page and becomes learner guidance.
  Future<String> _extractGoogleDoc(Uri uri) async {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // /document/d/{id}/... or /spreadsheets/d/{id}/...
    String? kind;
    String? id;
    for (var i = 0; i + 2 < segments.length; i++) {
      if (segments[i + 1] == 'd' &&
          (segments[i] == 'document' || segments[i] == 'spreadsheets')) {
        kind = segments[i];
        id = segments[i + 2];
        break;
      }
    }
    if (kind == null || id == null) {
      throw ImportException(
        code: 'unsupported_link',
        message:
            'This Google Drive link is not a document Talkloom can open. '
            'Share the file itself, or paste its text.',
      );
    }
    final format = kind == 'spreadsheets' ? 'csv' : 'txt';
    final exportUri = Uri.https(
      'docs.google.com',
      '/$kind/d/$id/export',
      {'format': format},
    );
    final response = await _safeGet(
      exportUri,
      headers: const {'Accept': 'text/plain, text/csv, */*'},
      maxBytes: _maxWebResponseBytes,
    );
    final body = response.body.trim();
    final looksLikeLogin =
        body.toLowerCase().contains('sign in') &&
        body.toLowerCase().contains('google');
    if (response.statusCode != 200 || body.length <= 60 || looksLikeLogin) {
      throw ImportException(
        code: 'unreadable',
        message:
            'Talkloom could not open this Google file. Set sharing to '
            '"Anyone with the link", or download it and upload the file.',
      );
    }
    return body.length > 8000 ? '${body.substring(0, 8000)}\n…' : body;
  }

  /// Extracts rich social media context through the existing reader fallback.
  ///
  /// Agentic order: (1) page readers (AgentReach, then Jina); (2) verify the
  /// text actually carries target-language signal — social pages are mostly
  /// site chrome around spoken/on-screen content; (3) repair by downloading
  /// the media audio (yt-dlp) and transcribing it with Muse Voice;
  /// (4) only then give up with guidance. Page text that fails verification
  /// but exists is still returned when no repair is possible, so the
  /// pipeline's language guard can judge it (never silently discarded).
  Future<String> _extractSocialMediaContent(
    String url, {
    String? userScopeId,
    String metaApiKey = '',
    String targetLanguage = 'de',
  }) async {
    String platform = 'Social Media';
    if (url.contains('instagram.com')) platform = 'Instagram';
    if (url.contains('tiktok.com')) platform = 'TikTok';
    if (url.contains('facebook.com')) platform = 'Facebook';
    if (url.contains('reddit.com')) platform = 'Reddit';
    if (url.contains('bilibili.com') || url.contains('b23.tv')) {
      platform = 'Bilibili';
    }
    if (url.contains('xiaohongshu.com') || url.contains('xhslink.com')) {
      platform = 'Xiaohongshu';
    }
    if (url.contains('xueqiu.com')) platform = 'Xueqiu';
    if (url.contains('xiaoyuzhoufm.com')) platform = 'Xiaoyuzhou';
    if (url.contains('linkedin.com')) platform = 'LinkedIn';
    if (url.contains('github.com')) platform = 'GitHub';
    if (url.contains('v2ex.com')) platform = 'V2EX';
    if (url.contains('zhipin.com') || url.contains('bosszhipin.com')) {
      platform = 'Boss';
    }
    if (url.contains('twitter.com') || url.contains('x.com')) {
      platform = 'X (Twitter)';
    }

    String? pageText;
    try {
      final resolved = await _agentReachWorker.resolveUrlContent(
        Uri.parse(url),
        userScopeId: userScopeId,
      );
      if (resolved != null && resolved.text.trim().length > 60) {
        final title = resolved.title;
        final author = resolved.author;
        final heading = [
          if (title != null && title.isNotEmpty) title,
          if (author != null && author.isNotEmpty) 'by $author',
        ].join(' ');
        pageText =
            '[${resolved.channel} content${heading.isEmpty ? '' : ': $heading'}]\n'
            '${resolved.text}';
      }
    } catch (_) {
      // Keep the existing public-reader fallback available.
    }

    if (pageText == null) {
      // Jina fetches on our behalf, so validate the submitted destination
      // before forwarding it and validate Jina's own connection
      // independently.
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
          pageText = '[$platform Content & Discussion]\n$truncated';
        }
      } catch (_) {}
    }

    // Verify: page text with real target-language signal is the lesson.
    if (pageText != null &&
        TargetLanguageGuard.hasSignal(
          text: pageText,
          targetLanguage: targetLanguage,
        )) {
      return pageText;
    }

    // Repair: the German is spoken (reels, TikToks), not written. Download
    // the media audio and transcribe it, same path as the YouTube fallback.
    // Needs yt-dlp + ffmpeg on the server and a Meta key; without them the
    // page text (or the guidance below) is what the learner gets.
    if (metaApiKey.isNotEmpty) {
      try {
        final wav = await _audioDownloader(url);
        if (wav != null && wav.isNotEmpty) {
          final transcript = (await _audioTranscriber(
            wav,
            metaApiKey,
          ))?.trim();
          if (transcript != null &&
              transcript.length >= _minAudioTranscriptChars &&
              TargetLanguageGuard.hasSignal(
                text: transcript,
                targetLanguage: targetLanguage,
              )) {
            return '[$platform content: audio-transcription: spoken '
                '${targetLanguage.toUpperCase()} transcribed by Muse Voice '
                'from the first ${_audioFallbackSeconds ~/ 60} minutes; '
                'words may be misheard]\n$transcript';
          }
        }
      } catch (_) {
        // Fall through to page text / guidance below.
      }
    }

    if (pageText != null) return pageText;

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
      'bilibili.com',
      'b23.tv',
      'xiaohongshu.com',
      'xhslink.com',
      'xueqiu.com',
      'xiaoyuzhoufm.com',
      'linkedin.com',
      'twitter.com',
      'x.com',
      'github.com',
      'v2ex.com',
      'zhipin.com',
      'bosszhipin.com',
    ].any((domain) => normalized == domain || normalized.endsWith('.$domain'));
  }

  Future<({int exitCode, String stdout})> _runExtractor(
    String executable,
    String url,
  ) async {
    final process = await Process.start(executable, [
      'scripts/extract_youtube.py',
      url,
      youTubeTargetLanguage,
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

  /// Extracts text from document/photo images using Meta multimodal AI
  /// (Muse Spark vision via the Meta Model API) or Base64 decoding.
  /// Runs one of the stdlib extractor scripts (PDF/DOCX) over [bytes].
  /// Returns null on any failure; callers turn that into guidance.
  Future<String?> _extractViaScript(String script, Uint8List bytes) async {
    Process? process;
    try {
      final localPython = Platform.isWindows
          ? '.venv/Scripts/python.exe'
          : '.venv/bin/python';
      final python =
          Platform.environment['TALKLOOM_PYTHON_EXECUTABLE'] ??
          (await File(localPython).exists() ? localPython : 'python3');
      process = await Process.start(python, ['scripts/$script']);
      final output = process.stdout.transform(utf8.decoder).join();
      final errors = process.stderr.drain<void>();
      process.stdin.add(bytes);
      await process.stdin.close();
      final code = await process.exitCode.timeout(
        const Duration(seconds: 30),
      );
      final text = await output.timeout(const Duration(seconds: 2));
      await errors;
      if (code == 0 && text.trim().isNotEmpty) return text.trim();
      return null;
    } catch (_) {
      return null;
    } finally {
      process?.kill();
    }
  }

  Future<String> extractTextFromMedia({
    required String base64Data,
    required String mimeType,
    String metaApiKey = '',
  }) async {
    // Meta Model API is the default multimodal path for image sources.
    if (mimeType == 'application/pdf') {
      final payload = base64Data.contains(',')
          ? base64Data.substring(base64Data.indexOf(',') + 1)
          : base64Data;
      final bytes = base64Decode(payload);
      if (bytes.length > 8 * 1024 * 1024) {
        throw ImportException(
          code: 'unreadable',
          message: 'This PDF is too large. Try a smaller file.',
        );
      }
      final text = await _extractViaScript('extract_pdf.py', bytes);
      if (text != null) return text;
      throw ImportException(
        code: 'unreadable',
        message:
            'Could not read this PDF. Use a PDF with selectable text, '
            'or share a clear image of the page.',
      );
    }
    const docxMime =
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (mimeType == docxMime || mimeType == 'application/msword') {
      final payload = base64Data.contains(',')
          ? base64Data.substring(base64Data.indexOf(',') + 1)
          : base64Data;
      final bytes = base64Decode(payload);
      if (bytes.length > 8 * 1024 * 1024) {
        throw ImportException(
          code: 'unreadable',
          message: 'This document is too large. Try a smaller file.',
        );
      }
      final text = await _extractViaScript('extract_docx.py', bytes);
      if (text != null) return text;
      throw ImportException(
        code: 'unreadable',
        message: mimeType == 'application/msword'
            ? 'Talkloom cannot read old .doc files. Save it as .docx or '
                  'PDF and try again.'
            : 'Could not read this document. Try saving it as PDF, '
                  'or paste the text instead.',
      );
    }
    if (mimeType == 'text/html') {
      final payload = base64Data.contains(',')
          ? base64Data.substring(base64Data.indexOf(',') + 1)
          : base64Data;
      final html = utf8.decode(base64Decode(payload), allowMalformed: true);
      final text = DwLearnGerman.stripHtml(html);
      if (text.length > 40) return text;
      throw ImportException(
        code: 'unreadable',
        message: 'Could not read this HTML file. Paste the text instead.',
      );
    }
    if (metaApiKey.isNotEmpty && mimeType.startsWith('image/')) {
      try {
        final cleanBase64 = base64Data.contains(',')
            ? base64Data.split(',').last
            : base64Data;
        final response = await _client.post(
          Uri.parse('$kMetaBaseUrl/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $metaApiKey',
          },
          body: jsonEncode({
            'model': kMetaMultimodalModel,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'text',
                    'text':
                        'Extract all readable text from this image verbatim. Return only the extracted text.',
                  },
                  {
                    'type': 'image_url',
                    'image_url': {
                      'url': 'data:$mimeType;base64,$cleanBase64',
                    },
                  },
                ],
              },
            ],
            'temperature': 0,
            'max_tokens': 4096,
          }),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = data['choices'][0]['message']['content'] as String;
          if (text.trim().isNotEmpty) return text.trim();
        }
      } catch (_) {}
    }
    // 1. Plain-text documents decode locally; Meta vision handles images.
    try {
      if (!mimeType.startsWith('text/')) {
        throw const FormatException('Binary media requires an extractor.');
      }
      final cleanBase64 = base64Data.contains(',')
          ? base64Data.split(',').last
          : base64Data;
      final decodedBytes = base64Decode(cleanBase64);
      final utf8String = utf8.decode(decodedBytes);
      final printableCount = utf8String.runes
          .where((r) => r >= 32 && r <= 126 || r > 160)
          .length;
      if (printableCount > utf8String.length * 0.7 &&
          utf8String.trim().length > 10) {
        return utf8String.trim();
      }
    } catch (_) {}

    // Never substitute sample text: the learner must study their own file.
    throw ImportException(
      code: 'unreadable',
      message:
          'Talkloom could not read text from this file. '
          'Try a clearer photo, or paste the text instead.',
    );
  }
}

/// Language German learners should get captions in.
const youTubeTargetLanguage = 'de';

/// Builds the header line that tells downstream compilation which kind of
/// captions the transcript came from.
String youTubeCaptionHeader({
  required String title,
  required String author,
  String? language,
  bool isGenerated = false,
  bool translated = false,
  String target = youTubeTargetLanguage,
}) {
  final lang = (language ?? '').trim();
  if (lang.isEmpty) return '[YouTube Video: $title by $author]';
  final kind = translated
      ? 'machine-translated'
      : (isGenerated ? 'auto-generated' : 'manual');
  final inTarget = lang.toLowerCase().split(RegExp(r'[-_]')).first == target;
  final note = isGenerated && !translated && !inTarget
      ? ' | note: captions are machine-generated in another language and '
            'German words may be misheard'
      : '';
  return '[YouTube Video: $title by $author | captions: $lang, $kind$note]';
}
