import 'dart:convert';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../client.dart';
import '../data/lesson_repository.dart';
import '../domain/language.dart';
import '../domain/learning_session.dart';
import '../domain/lesson_content.dart';
import '../domain/word_tracking_analytics.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden during bootstrap'),
);

class AppThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      ref.watch(sharedPreferencesProvider).getBool('talkloom.dark-mode') == true
      ? ThemeMode.dark
      : ThemeMode.light;
  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    ref
        .read(sharedPreferencesProvider)
        .setBool('talkloom.dark-mode', state == ThemeMode.dark);
  }
}

final appThemeProvider = NotifierProvider<AppThemeController, ThemeMode>(
  AppThemeController.new,
);

class AppPreferences {
  const AppPreferences({
    this.readReplies = true,
    this.reduceMotion = false,
    this.speechVoice = defaultSpeechVoiceId,
  });
  final bool readReplies;
  final bool reduceMotion;

  /// Open-voice id used for server speech (2 female + 2 male German
  /// voices). Falls back to on-device speech when the server voice
  /// is unreachable.
  final String speechVoice;
}

/// Open German voices served by the self-hosted worker, in display order.
class SpeechVoiceOption {
  const SpeechVoiceOption({
    required this.id,
    required this.name,
    required this.detail,
  });
  final String id;
  final String name;
  final String detail;
}

const defaultSpeechVoiceId = 'de-thorsten-m';

const speechVoiceOptions = [
  SpeechVoiceOption(
    id: 'de-thorsten-m',
    name: 'Thorsten · Male',
    detail: 'Neutral German voice',
  ),
  SpeechVoiceOption(
    id: 'de-ramona-f',
    name: 'Ramona · Female',
    detail: 'Clear standard German',
  ),
  SpeechVoiceOption(
    id: 'de-kerstin-f',
    name: 'Kerstin · Female',
    detail: 'Warm and calm',
  ),
  SpeechVoiceOption(
    id: 'de-karlsson-m',
    name: 'Karlsson · Male',
    detail: 'Deep and steady',
  ),
];

class AppPreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppPreferences(
      readReplies: prefs.getBool('talkloom.read-replies') ?? true,
      reduceMotion: prefs.getBool('talkloom.reduce-motion') ?? false,
      speechVoice:
          prefs.getString('talkloom.speech-voice') ?? defaultSpeechVoiceId,
    );
  }

  Future<void> setReadReplies(bool value) async {
    state = AppPreferences(
      readReplies: value,
      reduceMotion: state.reduceMotion,
      speechVoice: state.speechVoice,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool('talkloom.read-replies', value);
  }

  Future<void> setReduceMotion(bool value) async {
    state = AppPreferences(
      readReplies: state.readReplies,
      reduceMotion: value,
      speechVoice: state.speechVoice,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setBool('talkloom.reduce-motion', value);
  }

  Future<void> setSpeechVoice(String value) async {
    final valid = speechVoiceOptions.any((option) => option.id == value);
    final id = valid ? value : defaultSpeechVoiceId;
    state = AppPreferences(
      readReplies: state.readReplies,
      reduceMotion: state.reduceMotion,
      speechVoice: id,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setString('talkloom.speech-voice', id);
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesController, AppPreferences>(
      AppPreferencesController.new,
    );

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(client),
);

/// The learner's chosen languages and level.
///
/// Persisted locally so the app opens straight into the right language, and
/// exposed as the single source of truth replacing the hardcoded `'de'`.
class LearningSessionController extends Notifier<LearningSession> {
  static const _key = 'talkloom.session.v1';

  @override
  LearningSession build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return LearningSession.guestDefault();
    try {
      return LearningSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return LearningSession.guestDefault();
    }
  }

  Future<void> save(LearningSession session) async {
    final previousTarget = state.target.code;
    state = session;
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setString(_key, jsonEncode(session.toJson()));
    final targets =
        preferences.getStringList(_languagesKey) ?? [previousTarget];
    if (!targets.contains(session.target.code)) {
      await preferences.setStringList(_languagesKey, [
        ...targets,
        session.target.code,
      ]);
    }
    final profiles = _readProfiles(preferences.getString(_profilesKey));
    profiles[session.target.code] = session.toJson();
    await preferences.setString(_profilesKey, jsonEncode(profiles));
  }

  Future<void> switchTarget(Language language) async {
    final current = state;
    if (current.target == language) return;
    final preferences = ref.read(sharedPreferencesProvider);
    final profiles = _readProfiles(preferences.getString(_profilesKey));
    profiles[current.target.code] = current.toJson();
    final stored = profiles[language.code];
    final next = stored == null
        ? current.copyWith(target: language)
        : LearningSession.fromJson(stored).copyWith(support: current.support);
    await save(next);
    profiles[language.code] = next.toJson();
    await preferences.setString(_profilesKey, jsonEncode(profiles));
  }

  Future<void> updateLevel(Language language, CefrLevel level) async {
    final preferences = ref.read(sharedPreferencesProvider);
    final profiles = _readProfiles(preferences.getString(_profilesKey));
    final profile =
        profiles[language.code] ??
        {
          'target': language.code,
          'support': state.support.code,
          'level': level.code,
        };
    profiles[language.code] = {...profile, 'level': level.code};
    await preferences.setString(_profilesKey, jsonEncode(profiles));
    final targets = preferences.getStringList(_languagesKey) ?? <String>[];
    if (!targets.contains(language.code)) {
      await preferences.setStringList(_languagesKey, [
        ...targets,
        language.code,
      ]);
    }
    if (state.target == language) {
      state = state.copyWith(level: level);
      await preferences.setString(_key, jsonEncode(state.toJson()));
    }
  }

  static const _languagesKey = 'talkloom.languages.v1';
  static const _profilesKey = 'talkloom.language-profiles.v1';

  Map<String, Map<String, dynamic>> _readProfiles(String? raw) {
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
      );
    } on Object {
      return {};
    }
  }
}

final learningSessionProvider =
    NotifierProvider<LearningSessionController, LearningSession>(
      LearningSessionController.new,
    );

/// True once the learner has chosen what they are learning or has persisted preferences.
final isOnboardedProvider = Provider<bool>(
  (ref) =>
      ref.watch(sharedPreferencesProvider).containsKey('talkloom.session.v1'),
);

/// Imported sources for the active target language.
final sourcesProvider = FutureProvider.autoDispose<List<Source>>((ref) async {
  final session = ref.watch(learningSessionProvider);
  return ref.watch(lessonRepositoryProvider).listSources(session);
});

/// Agent-Reach channel catalog: which connected sources this server can
/// read. Empty while loading or when unreachable (never blocks importing).
final connectedSourcesProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
      return ref.watch(lessonRepositoryProvider).connectedChannels();
    });

/// Vocabulary progress for the active target language.
final learnerStateProvider = FutureProvider.autoDispose<LearnerState?>((
  ref,
) async {
  final session = ref.watch(learningSessionProvider);
  return ref.watch(lessonRepositoryProvider).learnerState(session);
});

/// Server-verified evidence per word/grammar target for the active language.
final wordEvidenceProvider =
    FutureProvider.autoDispose<List<WordEvidenceSummary>>((ref) {
      final session = ref.watch(learningSessionProvider);
      return ref.watch(lessonRepositoryProvider).wordEvidence(session);
    });

/// Computed word tracking and privacy-preserving vocabulary analytics across
/// all of the learner's lessons and evidence.
final wordTrackingAnalyticsProvider = Provider<WordTrackingAnalytics>((ref) {
  final lessons = ref.watch(lessonsProvider).asData?.value ?? const [];
  final learnerState = ref.watch(learnerStateProvider).asData?.value;
  final evidence = ref.watch(wordEvidenceProvider).asData?.value ?? const [];
  return WordTrackingAnalytics.fromData(
    lessons: lessons,
    learnerState: learnerState,
    evidence: evidence,
  );
});

/// The lesson currently being worked through.
class ActiveLessonController extends Notifier<LessonContent?> {
  @override
  LessonContent? build() => null;

  void open(LessonContent lesson) => state = lesson;

  void clear() => state = null;
}

final activeLessonProvider =
    NotifierProvider<ActiveLessonController, LessonContent?>(
      ActiveLessonController.new,
    );

class SelectedSourceController extends Notifier<Source?> {
  @override
  Source? build() => null;

  void select(Source source) => state = source;
  void clear() => state = null;
}

final selectedSourceProvider =
    NotifierProvider<SelectedSourceController, Source?>(
      SelectedSourceController.new,
    );

final lessonsProvider = FutureProvider.autoDispose<List<Lesson>>((ref) {
  return ref
      .watch(lessonRepositoryProvider)
      .listLessons(
        ref.watch(learningSessionProvider),
      );
});

final sourceLessonProvider = FutureProvider.autoDispose.family<Lesson?, int>(
  (ref, id) => ref.watch(lessonRepositoryProvider).lessonForSource(id),
);

/// Drives the import action and exposes its loading and error states, so the
/// UI can no longer show a spinner that silently stops.
class ImportController extends Notifier<AsyncValue<LessonContent?>> {
  @override
  AsyncValue<LessonContent?> build() => const AsyncValue.data(null);

  Future<LessonContent?> importText({
    required String title,
    required String text,
  }) {
    return _run(
      (repository, session) => repository.compileFromText(
        session: session,
        title: title,
        text: text,
        onProgress: _setStage,
      ),
    );
  }

  Future<LessonContent?> importMedia({
    required String title,
    required String base64Content,
    String type = 'document',
  }) {
    return _run(
      (repository, session) => repository.compileFromMedia(
        session: session,
        title: title,
        base64Content: base64Content,
        type: type,
        onProgress: _setStage,
      ),
    );
  }

  Future<LessonContent?> importUrl({
    required String title,
    required String url,
  }) {
    return _run(
      (repository, session) => repository.compileFromUrl(
        session: session,
        title: title,
        url: url,
        onProgress: _setStage,
      ),
    );
  }

  void _setStage(String stage) =>
      ref.read(importProgressProvider.notifier).setStage(stage);

  Future<LessonContent?> _run(
    Future<Lesson> Function(LessonRepository, LearningSession) action,
  ) async {
    final session = ref.read(learningSessionProvider);

    state = const AsyncValue.loading();
    ref.read(importProgressProvider.notifier).setStage('reading');
    try {
      final content = LessonContent.fromLesson(
        await action(ref.read(lessonRepositoryProvider), session),
      );
      state = AsyncValue.data(content);
      ref.read(importProgressProvider.notifier).setStage('ready');
      ref.read(activeLessonProvider.notifier).open(content);
      if (content.sourceId != null) {
        ref.invalidate(sourceLessonProvider(content.sourceId!));
      }
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      return content;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      ref.read(importProgressProvider.notifier).setStage('failed');
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }

  void reset() {
    if (!state.isLoading) state = const AsyncValue.data(null);
  }
}

final importControllerProvider =
    NotifierProvider<ImportController, AsyncValue<LessonContent?>>(
      ImportController.new,
    );

class ImportProgressController extends Notifier<String> {
  @override
  String build() => 'reading';
  void setStage(String stage) => state = stage;
}

final importProgressProvider =
    NotifierProvider<ImportProgressController, String>(
      ImportProgressController.new,
    );

/// Client-side Bring-Your-Own-Key (BYOK) Configuration.
/// Meta Model API is the sole AI provider.
enum ByokProvider { meta }

class ByokConfig {
  const ByokConfig({
    this.activeProvider = ByokProvider.meta,
    this.metaKey = '',
    this.isCustomKeyEnabled = false,
  });

  final ByokProvider activeProvider;
  final String metaKey;
  final bool isCustomKeyEnabled;

  bool get hasActiveKey {
    return metaKey.trim().isNotEmpty;
  }

  String get activeKey {
    return metaKey.trim();
  }

  ByokConfig copyWith({
    ByokProvider? activeProvider,
    String? metaKey,
    bool? isCustomKeyEnabled,
  }) {
    return ByokConfig(
      activeProvider: activeProvider ?? this.activeProvider,
      metaKey: metaKey ?? this.metaKey,
      isCustomKeyEnabled: isCustomKeyEnabled ?? this.isCustomKeyEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeProvider': activeProvider.name,
    'metaKey': metaKey,
    'isCustomKeyEnabled': isCustomKeyEnabled,
  };

  factory ByokConfig.fromJson(Map<String, dynamic> json) {
    return ByokConfig(
      activeProvider: ByokProvider.meta,
      metaKey: json['metaKey'] as String? ?? '',
      isCustomKeyEnabled: json['isCustomKeyEnabled'] as bool? ?? false,
    );
  }
}

class ByokSettingsController extends Notifier<ByokConfig> {
  static const _key = 'talkloom.byok.settings.v2';

  @override
  ByokConfig build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const ByokConfig();
    try {
      return ByokConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return const ByokConfig();
    }
  }

  Future<void> updateConfig(ByokConfig config) async {
    state = config;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(config.toJson()));
  }

  Future<void> setProvider(ByokProvider provider) async {
    await updateConfig(state.copyWith(activeProvider: provider));
  }

  Future<void> setKey({
    required ByokProvider provider,
    required String key,
  }) async {
    final next = state.copyWith(metaKey: key.trim());
    await updateConfig(next);
  }

  Future<void> toggleCustomKey(bool enabled) async {
    await updateConfig(state.copyWith(isCustomKeyEnabled: enabled));
  }
}

final byokSettingsProvider =
    NotifierProvider<ByokSettingsController, ByokConfig>(
      ByokSettingsController.new,
    );
