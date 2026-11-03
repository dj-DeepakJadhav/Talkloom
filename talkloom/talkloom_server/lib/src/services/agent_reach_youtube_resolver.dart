import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Agent Reach-inspired first upstream for YouTube caption resolution.
///
/// The resolver uses yt-dlp when it is installed and healthy. Callers should
/// fall back to Talkloom's existing platform resolver when this returns null.
/// It intentionally does not install tools or download video/audio.
class AgentReachYouTubeResolver {
  static const _healthTtl = Duration(minutes: 2);
  static const _commandTimeout = Duration(seconds: 30);
  static const _maxTranscriptBytes = 2 * 1024 * 1024;
  static const _maxStdoutBytes = 64 * 1024;
  static const _maxStderrBytes = 16 * 1024;

  static final Map<String, ({DateTime checkedAt, bool healthy})> _health = {};

  final String? executableOverride;

  AgentReachYouTubeResolver({this.executableOverride});

  /// Returns real captions from yt-dlp, or null when the upstream is unhealthy
  /// or cannot provide captions. No synthetic transcript is produced.
  Future<AgentReachCaptionResult?> resolve(
    String url, {
    required String targetLanguage,
  }) async {
    final videoUri = _parseYouTubeUrl(url);
    if (videoUri == null) return null;

    final executable = _executable();
    if (!await _isHealthy(executable)) return null;

    final directory = await Directory.systemTemp.createTemp(
      'talkloom-agent-reach-',
    );
    try {
      final languages = _languagePreferences(targetLanguage);
      final result = await _runBounded(executable, [
        '--no-warnings',
        '--no-progress',
        '--skip-download',
        '--write-subs',
        '--write-auto-subs',
        '--sub-langs',
        languages.join(','),
        '--sub-format',
        'vtt/best',
        '--print',
        'title',
        '-o',
        '${directory.path}${Platform.pathSeparator}%(id)s.%(ext)s',
        videoUri.toString(),
      ]);
      if (result.exitCode != 0) return null;

      final files = await directory
          .list(followLinks: false)
          .where((entry) => entry is File && entry.path.endsWith('.vtt'))
          .cast<File>()
          .toList();
      if (files.isEmpty) return null;

      files.sort((left, right) {
        final leftRank = _subtitleRank(left.path, languages);
        final rightRank = _subtitleRank(right.path, languages);
        return leftRank.compareTo(rightRank);
      });

      for (final file in files) {
        final bytes = await file.length();
        if (bytes == 0 || bytes > _maxTranscriptBytes) continue;
        final transcript = _parseVtt(await file.readAsString());
        if (transcript.isEmpty) continue;
        return AgentReachCaptionResult(
          title: result.stdout.trim().split('\n').first.trim(),
          language: _languageFromPath(file.path, languages),
          transcript: transcript,
        );
      }
      return null;
    } on ProcessException {
      _health.remove(executable);
      return null;
    } on TimeoutException {
      return null;
    } on FileSystemException {
      return null;
    } finally {
      try {
        await directory.delete(recursive: true);
      } on FileSystemException {
        // Temporary caption files are best-effort cleanup after a failed read.
      }
    }
  }

  String _executable() {
    final configured =
        executableOverride ?? Platform.environment['TALKLOOM_YTDLP_EXECUTABLE'];
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    return Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
  }

  Future<bool> _isHealthy(String executable) async {
    final cached = _health[executable];
    final now = DateTime.now();
    if (cached != null && now.difference(cached.checkedAt) < _healthTtl) {
      return cached.healthy;
    }

    var healthy = false;
    try {
      final result = await Process.run(executable, const ['--version']).timeout(
        const Duration(seconds: 3),
      );
      healthy =
          result.exitCode == 0 && (result.stdout as String).trim().isNotEmpty;
    } on Object {
      healthy = false;
    }
    _health[executable] = (checkedAt: now, healthy: healthy);
    return healthy;
  }

  Future<_BoundedProcessResult> _runBounded(
    String executable,
    List<String> arguments,
  ) async {
    final process = await Process.start(executable, arguments);
    final stdout = BytesBuilder(copy: false);
    var stdoutSize = 0;
    var overflow = false;
    final stdoutDone = process.stdout.listen((chunk) {
      stdoutSize += chunk.length;
      if (stdoutSize > _maxStdoutBytes) {
        overflow = true;
        process.kill();
      } else {
        stdout.add(chunk);
      }
    }).asFuture<void>();
    var stderrSize = 0;
    final stderrDone = process.stderr.listen((chunk) {
      // Drain stderr to avoid blocking the process but never retain or log it.
      stderrSize += chunk.length;
      if (stderrSize > _maxStderrBytes) stderrSize = _maxStderrBytes;
    }).asFuture<void>();

    final exitCode = await process.exitCode.timeout(
      _commandTimeout,
      onTimeout: () {
        process.kill();
        throw TimeoutException('yt-dlp caption request timed out.');
      },
    );
    await Future.wait([stdoutDone, stderrDone]).timeout(
      const Duration(seconds: 2),
      onTimeout: () => <void>[],
    );
    if (overflow) return const _BoundedProcessResult(-1, '');
    return _BoundedProcessResult(
      exitCode,
      utf8.decode(stdout.takeBytes(), allowMalformed: true),
    );
  }

  Uri? _parseYouTubeUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme != 'https') return null;
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (host != 'youtube.com' && host != 'youtu.be') return null;
    final videoId = host == 'youtu.be'
        ? (uri.pathSegments.isEmpty ? null : uri.pathSegments.first)
        : uri.path == '/watch'
        ? uri.queryParameters['v']
        : null;
    if (videoId == null || !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(videoId)) {
      return null;
    }
    return Uri.https('www.youtube.com', '/watch', {'v': videoId});
  }

  List<String> _languagePreferences(String targetLanguage) {
    final target = targetLanguage.trim().replaceAll('_', '-');
    final base = target.split('-').first;
    final candidates = <String>[if (target.isNotEmpty) target, base, 'en'];
    return candidates.toSet().toList();
  }

  int _subtitleRank(String path, List<String> languages) {
    final name = path.split(Platform.pathSeparator).last.toLowerCase();
    for (var index = 0; index < languages.length; index++) {
      final language = languages[index].toLowerCase();
      if (name.contains('.$language.') || name.endsWith('.$language.vtt')) {
        return index;
      }
    }
    return languages.length;
  }

  String? _languageFromPath(String path, List<String> languages) {
    final name = path.split(Platform.pathSeparator).last.toLowerCase();
    for (final language in languages) {
      if (name.contains('.${language.toLowerCase()}.')) return language;
    }
    return null;
  }

  String _parseVtt(String source) {
    final cues = <String>[];
    String? previous;
    for (final rawLine in source.split(RegExp(r'\r?\n'))) {
      final line = rawLine.trim();
      if (line.isEmpty ||
          line == 'WEBVTT' ||
          line.startsWith('NOTE') ||
          line.startsWith('STYLE') ||
          line.startsWith('REGION') ||
          RegExp(r'^\d+$').hasMatch(line) ||
          RegExp(r'^\d{2}:\d{2}').hasMatch(line)) {
        continue;
      }
      final text = line
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&lt;'), '<')
          .replaceAll(RegExp(r'&gt;'), '>')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (text.isEmpty || text == previous) continue;
      cues.add(text);
      previous = text;
    }
    return cues.join(' ').trim();
  }
}

class AgentReachCaptionResult {
  final String title;
  final String? language;
  final String transcript;

  const AgentReachCaptionResult({
    required this.title,
    required this.language,
    required this.transcript,
  });
}

class _BoundedProcessResult {
  final int exitCode;
  final String stdout;

  const _BoundedProcessResult(this.exitCode, this.stdout);
}
