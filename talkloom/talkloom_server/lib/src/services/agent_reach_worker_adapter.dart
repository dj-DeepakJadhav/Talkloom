import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Runs the official Agent Reach CLI as a health-checked Serverpod worker.
///
/// The CLI is optional. If it is not installed, not healthy, or cannot read a
/// public source, callers continue through Talkloom's regular resolver. Each
/// Talkloom identity, including a guest, gets an isolated Agent Reach HOME.
class AgentReachWorkerAdapter {
  static const _healthTtl = Duration(minutes: 2);
  static const _healthTimeout = Duration(seconds: 5);
  static const _requestTimeout = Duration(seconds: 35);
  static const _maxOutputBytes = 4 * 1024 * 1024;
  static const _maxTimeoutSeconds = 1800;

  static final Map<String, ({DateTime checkedAt, bool healthy})> _health = {};
  static Future<void> _commandQueue = Future<void>.value();

  final String? executableOverride;

  AgentReachWorkerAdapter({this.executableOverride});

  /// Resolves YouTube subtitles using Agent Reach's yt-dlp channel.
  Future<AgentReachResolvedContent?> resolveYouTubeTranscript(
    Uri uri, {
    required String targetLanguage,
    String? userScopeId,
  }) async {
    if (!_isYouTubeHost(uri.host) ||
        !await _isHealthy(userScopeId: userScopeId)) {
      return null;
    }
    final payload = await _runJson([
      'youtube',
      'subtitle',
      uri.toString(),
      '--lang',
      '$targetLanguage,en',
      '--timeout',
      '30',
    ], userScopeId: userScopeId);
    return _parseContent(payload, channel: 'YouTube');
  }

  /// Lets Agent Reach route any public URL to channel-specific read actions.
  /// Login-backed extraction is scoped to the caller's isolated HOME.
  Future<AgentReachResolvedContent?> resolveUrlContent(
    Uri uri, {
    String? userScopeId,
  }) async {
    if (!await _isHealthy(userScopeId: userScopeId)) {
      return null;
    }
    if (_isBilibiliHost(uri.host)) {
      final payload = await _runJson([
        'bilibili',
        'read',
        uri.toString(),
        '--backend',
        'bilibili-api',
        '--timeout',
        '30',
      ], userScopeId: userScopeId);
      return _parseContent(payload, channel: 'Bilibili');
    }

    final payload = await _runJson([
      'read',
      uri.toString(),
      '--timeout',
      '30',
    ], userScopeId: userScopeId);
    return _parseContent(payload, channel: _channelForHost(uri.host));
  }

  /// Returns Agent Reach's complete channel/action catalog as JSON.
  Future<String> channels({required String userScopeId}) async {
    final payload = await _runJson(['channels'], userScopeId: userScopeId);
    return jsonEncode(
      payload ?? _errorPayload('NEED_SETUP', 'Agent Reach is unavailable.'),
    );
  }

  /// Returns the per-user channel health report emitted by `agent-reach doctor`.
  Future<String> doctor({required String userScopeId}) async {
    final payload = await _runJson(['doctor'], userScopeId: userScopeId);
    return jsonEncode(
      payload ?? _errorPayload('NEED_SETUP', 'Agent Reach is unavailable.'),
    );
  }

  /// Executes any read-only channel action advertised by `agent-reach channels`.
  /// A separate HOME per Talkloom identity isolates browser profiles, cookies,
  /// local tool sessions, and Agent Reach state.
  Future<String> runAction({
    required String userScopeId,
    required String channel,
    required String action,
    required Map<String, dynamic> parameters,
    String? backend,
    int timeoutSeconds = 30,
  }) async {
    if (userScopeId.isEmpty ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,39}$').hasMatch(channel) ||
        !RegExp(r'^[a-z][a-z0-9_-]{0,39}$').hasMatch(action)) {
      return jsonEncode(
        _errorPayload(
          'BAD_INPUT',
          'Choose a valid Agent Reach channel/action.',
        ),
      );
    }
    if (timeoutSeconds < 1 || timeoutSeconds > _maxTimeoutSeconds) {
      return jsonEncode(
        _errorPayload(
          'BAD_INPUT',
          'Timeout must be between 1 and $_maxTimeoutSeconds seconds.',
        ),
      );
    }

    try {
      final catalog = await _runJson(
        ['channels'],
        userScopeId: userScopeId,
      );
      final channels = catalog?['channels'];
      if (catalog?['ok'] != true || channels is! List) {
        return jsonEncode(
          catalog ?? _errorPayload('NEED_SETUP', 'Agent Reach is unavailable.'),
        );
      }

      final selectedChannel = channels.whereType<Map>().firstWhere(
        (item) => item['name'] == channel,
        orElse: () => const <String, dynamic>{},
      );
      final actions = selectedChannel['actions'];
      if (actions is! List) {
        return jsonEncode(
          _errorPayload('BAD_INPUT', 'Unknown Agent Reach channel.'),
        );
      }
      final selectedAction = actions.whereType<Map>().firstWhere(
        (item) => item['name'] == action,
        orElse: () => const <String, dynamic>{},
      );
      final paramSpecs = selectedAction['params'];
      if (paramSpecs is! List) {
        return jsonEncode(
          _errorPayload('BAD_INPUT', 'Unknown Agent Reach action.'),
        );
      }

      final allowedNames = paramSpecs
          .whereType<Map>()
          .map((spec) => spec['name']?.toString())
          .whereType<String>()
          .toSet();
      final unknownNames = parameters.keys.toSet().difference(allowedNames);
      if (unknownNames.isNotEmpty) {
        return jsonEncode(
          _errorPayload(
            'BAD_INPUT',
            'Unsupported parameter(s): ${unknownNames.join(', ')}.',
          ),
        );
      }

      final arguments = <String>[channel, action];
      for (final spec in paramSpecs.whereType<Map>()) {
        final name = spec['name']?.toString();
        if (name == null || name.isEmpty) continue;
        final value = parameters[name];
        final required = spec['required'] == true;
        if (value == null) {
          if (required) {
            return jsonEncode(
              _errorPayload('BAD_INPUT', 'Missing required parameter: $name.'),
            );
          }
          continue;
        }
        final type = spec['type']?.toString();
        if (type == 'int' && value is! int) {
          return jsonEncode(
            _errorPayload('BAD_INPUT', '$name must be an integer.'),
          );
        }
        if (type == 'str' && value is! String) {
          return jsonEncode(
            _errorPayload('BAD_INPUT', '$name must be text.'),
          );
        }
        final valueString = value.toString();
        if (valueString.isEmpty || valueString.length > 12000) {
          return jsonEncode(
            _errorPayload('BAD_INPUT', '$name is empty or too large.'),
          );
        }
        if (required) {
          arguments.add(valueString);
        } else {
          arguments
            ..add('--$name')
            ..add(valueString);
        }
      }

      if (backend != null && backend.isNotEmpty) {
        final backends =
            (selectedAction['backends'] as List?)
                ?.whereType<String>()
                .toSet() ??
            <String>{};
        final publicWeb =
            (selectedAction['public_web'] as List?)?.isNotEmpty == true;
        if (!backends.contains(backend) &&
            !(backend == 'public-web' && publicWeb)) {
          return jsonEncode(
            _errorPayload('BAD_INPUT', 'Unsupported upstream for this action.'),
          );
        }
        arguments
          ..add('--backend')
          ..add(backend);
      }
      arguments
        ..add('--timeout')
        ..add(timeoutSeconds.toString());

      final result = await _runBounded(
        arguments,
        timeout: Duration(seconds: timeoutSeconds + 5),
        userScopeId: userScopeId,
      );
      final payload = _decodeObject(result.stdout);
      if (payload != null) return jsonEncode(payload);
      return jsonEncode(
        _errorPayload(
          result.exitCode == 0 ? 'UPSTREAM_BROKEN' : 'NEED_SETUP',
          'Agent Reach returned an unreadable response.',
        ),
      );
    } on Object {
      return jsonEncode(
        _errorPayload('NEED_SETUP', 'Agent Reach is unavailable.'),
      );
    }
  }

  String _executable() {
    final configured =
        executableOverride ??
        Platform.environment['TALKLOOM_AGENT_REACH_EXECUTABLE'];
    if (configured != null && configured.trim().isNotEmpty) {
      return configured.trim();
    }
    final local = Platform.isWindows
        ? '.venv/Scripts/agent-reach.exe'
        : '.venv/bin/agent-reach';
    if (File(local).existsSync()) return File(local).absolute.path;
    return Platform.isWindows ? 'agent-reach.exe' : 'agent-reach';
  }

  Future<bool> _isHealthy({String? userScopeId}) async {
    final home = await _userHome(userScopeId);
    final key = '${_executable()}|${home ?? ''}';
    final now = DateTime.now();
    final cached = _health[key];
    if (cached != null && now.difference(cached.checkedAt) < _healthTtl) {
      return cached.healthy;
    }

    var healthy = false;
    try {
      final result = await _runBounded(
        ['doctor'],
        timeout: _healthTimeout,
        userScopeId: userScopeId,
      );
      if (result.exitCode == 0) {
        healthy = _decodeObject(result.stdout) != null;
      }
    } on Object {
      healthy = false;
    }
    _health[key] = (checkedAt: now, healthy: healthy);
    return healthy;
  }

  Future<Map<String, dynamic>?> _runJson(
    List<String> arguments, {
    String? userScopeId,
  }) async {
    try {
      final result = await _runBounded(
        arguments,
        timeout: _requestTimeout,
        userScopeId: userScopeId,
      );
      return _decodeObject(result.stdout);
    } on Object {
      return null;
    }
  }

  Future<_AgentReachProcessResult> _runBounded(
    List<String> arguments, {
    required Duration timeout,
    String? userScopeId,
  }) async {
    final previous = _commandQueue;
    final release = Completer<void>();
    _commandQueue = release.future;
    await previous;
    try {
      return await _runBoundedUnlocked(
        arguments,
        timeout: timeout,
        userScopeId: userScopeId,
      );
    } finally {
      release.complete();
    }
  }

  Future<_AgentReachProcessResult> _runBoundedUnlocked(
    List<String> arguments, {
    required Duration timeout,
    String? userScopeId,
  }) async {
    final home = await _userHome(userScopeId);
    final executable = _executable();
    final environment = <String, String>{
      if (home != null) 'HOME': home,
      if (home != null) 'USERPROFILE': home,
    };
    if (executable.contains(Platform.pathSeparator)) {
      final separator = Platform.isWindows ? ';' : ':';
      environment['PATH'] =
          '${File(executable).absolute.parent.path}'
          '$separator${Platform.environment['PATH'] ?? ''}';
    }
    final process = await Process.start(
      executable,
      arguments,
      environment: environment,
    );
    final stdout = BytesBuilder(copy: false);
    var stdoutSize = 0;
    var outputTooLarge = false;
    final stdoutDone = process.stdout.listen((chunk) {
      stdoutSize += chunk.length;
      if (stdoutSize > _maxOutputBytes) {
        outputTooLarge = true;
        process.kill();
      } else if (!outputTooLarge) {
        stdout.add(chunk);
      }
    }).asFuture<void>();
    // Drain diagnostics to prevent a blocked child process; they may include
    // user URLs or upstream details, so they are not retained or logged.
    final stderrDone = process.stderr.listen((_) {}).asFuture<void>();

    final exitCode = await process.exitCode.timeout(
      timeout,
      onTimeout: () {
        process.kill();
        throw TimeoutException('Agent Reach request timed out.');
      },
    );
    await Future.wait([stdoutDone, stderrDone]).timeout(
      const Duration(seconds: 2),
      onTimeout: () => <void>[],
    );
    if (outputTooLarge) return const _AgentReachProcessResult(-1, '');
    return _AgentReachProcessResult(
      exitCode,
      utf8.decode(stdout.takeBytes(), allowMalformed: true).trim(),
    );
  }

  Future<String?> _userHome(String? userScopeId) async {
    if (userScopeId == null) return null;
    if (userScopeId.isEmpty) throw ArgumentError('User scope is required.');
    final encodedId = base64Url
        .encode(utf8.encode(userScopeId))
        .replaceAll('=', '');
    final configuredRoot =
        Platform.environment['TALKLOOM_AGENT_REACH_DATA_DIR'] ??
        '.agent-reach-users';
    final root = Directory(configuredRoot).absolute;
    await root.create(recursive: true);
    final home = Directory('${root.path}${Platform.pathSeparator}$encodedId');
    await home.create(recursive: true);
    if (!Platform.isWindows) {
      final chmod = await Process.run('chmod', ['700', home.path]);
      if (chmod.exitCode != 0) {
        throw FileSystemException('Could not secure Agent Reach user storage.');
      }
    }
    return home.path;
  }

  Map<String, dynamic>? _decodeObject(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> _errorPayload(String code, String message) => {
    'schema_version': 1,
    'ok': false,
    'items': <Object>[],
    'error': {'code': code, 'message': message},
  };

  AgentReachResolvedContent? _parseContent(
    Map<String, dynamic>? payload, {
    required String channel,
  }) {
    if (payload?['ok'] != true) return null;
    final items = payload?['items'];
    if (items is! List) return null;
    final content = <String>[];
    String? title;
    String? author;
    for (final item in items) {
      if (item is! Map) continue;
      final itemTitle = item['title']?.toString().trim();
      final itemAuthor = item['author']?.toString().trim();
      final text = item['text']?.toString().trim();
      title ??= itemTitle == null || itemTitle.isEmpty ? null : itemTitle;
      author ??= itemAuthor == null || itemAuthor.isEmpty ? null : itemAuthor;
      if (text != null && text.isNotEmpty) content.add(text);
    }
    final text = content.join('\n\n').trim();
    if (text.isEmpty || utf8.encode(text).length > _maxOutputBytes) return null;
    return AgentReachResolvedContent(
      channel: channel,
      title: title,
      author: author,
      text: text,
    );
  }

  bool _isYouTubeHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return normalized == 'youtube.com' || normalized == 'youtu.be';
  }

  bool _isBilibiliHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    return normalized == 'bilibili.com' ||
        normalized.endsWith('.bilibili.com') ||
        normalized == 'b23.tv';
  }

  String _channelForHost(String host) {
    final normalized = host.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
    if (normalized == 'bilibili.com' || normalized == 'b23.tv') {
      return 'Bilibili';
    }
    if (normalized == 'facebook.com' ||
        normalized == 'fb.com' ||
        normalized == 'fb.watch') {
      return 'Facebook';
    }
    if (normalized == 'instagram.com' || normalized == 'instagr.am') {
      return 'Instagram';
    }
    if (normalized == 'linkedin.com') return 'LinkedIn';
    if (normalized == 'reddit.com' || normalized == 'redd.it') return 'Reddit';
    if (normalized == 'twitter.com' || normalized == 'x.com') return 'X';
    if (normalized == 'xiaohongshu.com' || normalized == 'xhslink.com') {
      return 'Xiaohongshu';
    }
    if (normalized == 'xueqiu.com') return 'Xueqiu';
    if (normalized == 'xiaoyuzhoufm.com') return 'Xiaoyuzhou';
    if (normalized == 'github.com') return 'GitHub';
    if (normalized == 'v2ex.com') return 'V2EX';
    if (normalized == 'zhipin.com' || normalized == 'bosszhipin.com') {
      return 'Boss';
    }
    return 'Web';
  }
}

class AgentReachResolvedContent {
  final String channel;
  final String? title;
  final String? author;
  final String text;

  const AgentReachResolvedContent({
    required this.channel,
    required this.title,
    required this.author,
    required this.text,
  });
}

class _AgentReachProcessResult {
  final int exitCode;
  final String stdout;

  const _AgentReachProcessResult(this.exitCode, this.stdout);
}
