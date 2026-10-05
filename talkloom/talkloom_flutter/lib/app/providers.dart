import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../client.dart';
import '../data/lesson_repository.dart';
import '../domain/language.dart';
import '../domain/learning_session.dart';
import '../domain/lesson_content.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden during bootstrap'),
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
    state = session;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> switchTarget(Language language) async {
    final current = state;
    if (current.target == language) return;
    await save(current.copyWith(target: language));
  }
}

final learningSessionProvider =
    NotifierProvider<LearningSessionController, LearningSession>(
      LearningSessionController.new,
    );

/// True once the learner has chosen what they are learning or has persisted preferences.
final isOnboardedProvider = Provider<bool>(
  (ref) => ref.watch(sharedPreferencesProvider).containsKey('talkloom.session.v1'),
);

/// Imported sources for the active target language.
final sourcesProvider = FutureProvider.autoDispose<List<Source>>((ref) async {
  final session = ref.watch(learningSessionProvider);
  return ref.watch(lessonRepositoryProvider).listSources(session);
});

/// Vocabulary progress for the active target language.
final learnerStateProvider = FutureProvider.autoDispose<LearnerState?>((
  ref,
) async {
  final session = ref.watch(learningSessionProvider);
  return ref.watch(lessonRepositoryProvider).learnerState(session);
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
      ),
    );
  }

  Future<LessonContent?> importUrl({
    required String title,
    required String url,
  }) {
    return _run(
      (repository, session) =>
          repository.compileFromUrl(session: session, title: title, url: url),
    );
  }

  Future<LessonContent?> _run(
    Future<Lesson> Function(LessonRepository, LearningSession) action,
  ) async {
    final session = ref.read(learningSessionProvider);

    state = const AsyncValue.loading();
    try {
      final content = LessonContent.fromLesson(
        await action(ref.read(lessonRepositoryProvider), session),
      );
      state = AsyncValue.data(content);
      ref.read(activeLessonProvider.notifier).open(content);
      ref.invalidate(sourcesProvider);
      return content;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

final importControllerProvider =
    NotifierProvider<ImportController, AsyncValue<LessonContent?>>(
      ImportController.new,
    );

/// Client-side Bring-Your-Own-Key (BYOK) Configuration
/// Follows Mural architecture reference (https://github.com/Chuloo/mural)
enum ByokProvider { gemini, nvidia, groq }

class ByokConfig {
  const ByokConfig({
    this.activeProvider = ByokProvider.nvidia,
    this.geminiKey = '',
    this.nvidiaKey = '',
    this.groqKey = '',
    this.isCustomKeyEnabled = false,
  });

  final ByokProvider activeProvider;
  final String geminiKey;
  final String nvidiaKey;
  final String groqKey;
  final bool isCustomKeyEnabled;

  bool get hasActiveKey {
    return switch (activeProvider) {
      ByokProvider.gemini => geminiKey.trim().isNotEmpty,
      ByokProvider.nvidia => nvidiaKey.trim().isNotEmpty,
      ByokProvider.groq => groqKey.trim().isNotEmpty,
    };
  }

  String get activeKey {
    return switch (activeProvider) {
      ByokProvider.gemini => geminiKey.trim(),
      ByokProvider.nvidia => nvidiaKey.trim(),
      ByokProvider.groq => groqKey.trim(),
    };
  }

  ByokConfig copyWith({
    ByokProvider? activeProvider,
    String? geminiKey,
    String? nvidiaKey,
    String? groqKey,
    bool? isCustomKeyEnabled,
  }) {
    return ByokConfig(
      activeProvider: activeProvider ?? this.activeProvider,
      geminiKey: geminiKey ?? this.geminiKey,
      nvidiaKey: nvidiaKey ?? this.nvidiaKey,
      groqKey: groqKey ?? this.groqKey,
      isCustomKeyEnabled: isCustomKeyEnabled ?? this.isCustomKeyEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'activeProvider': activeProvider.name,
        'geminiKey': geminiKey,
        'nvidiaKey': nvidiaKey,
        'groqKey': groqKey,
        'isCustomKeyEnabled': isCustomKeyEnabled,
      };

  factory ByokConfig.fromJson(Map<String, dynamic> json) {
    final providerStr = json['activeProvider'] as String? ?? 'nvidia';
    final provider = ByokProvider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => ByokProvider.nvidia,
    );
    final storedNvidia = json['nvidiaKey'] as String? ?? '';
    final storedGemini = json['geminiKey'] as String? ?? '';
    return ByokConfig(
      activeProvider: provider,
      geminiKey: storedGemini,
      nvidiaKey: storedNvidia,
      groqKey: json['groqKey'] as String? ?? '',
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
    final next = switch (provider) {
      ByokProvider.gemini => state.copyWith(geminiKey: key.trim()),
      ByokProvider.nvidia => state.copyWith(nvidiaKey: key.trim()),
      ByokProvider.groq => state.copyWith(groqKey: key.trim()),
    };
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
