// Native (Android/iOS) speech input behind WebVoiceService, driven by a fake
// recognizer: denial, unsupported, interim -> final, stop, runtime errors, and
// that the voice screens keep a typed fallback when the mic cannot be used.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show ByteData, FontLoader, MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/core/platform/speech_engine.dart';
import 'package:talkloom_flutter/core/platform/web_voice_service.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/features/arena/talk_canvas_screen.dart';
import 'package:talkloom_flutter/features/arena/voice_arena_screen.dart';
import 'package:talkloom_flutter/features/speak/immersive_voice_modal.dart';
import 'package:talkloom_flutter/features/speak/speak_screen.dart';

class _ActiveLesson extends ActiveLessonController {
  @override
  LessonContent? build() => const LessonContent(
    lessonId: 1,
    objectives: ['Order a coffee'],
    vocabulary: [],
    activities: [],
    conversation: ConversationPlan.empty,
  );
}

class FakeSpeechEngine implements SpeechEngine {
  FakeSpeechEngine({
    this.initOk = true,
    this.permission = true,
    this.listenThrows = false,
  });

  bool initOk;
  bool permission;
  bool listenThrows;
  int initCalls = 0;
  int stopCalls = 0;
  String? lastLocale;
  void Function(String code, bool permanent)? _onError;
  void Function(String status)? _onStatus;
  void Function(String words, bool isFinal)? _onResult;

  @override
  Future<bool> initialize({
    required void Function(String code, bool permanent) onError,
    required void Function(String status) onStatus,
  }) async {
    initCalls++;
    _onError = onError;
    _onStatus = onStatus;
    return initOk;
  }

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
  }) async {
    if (listenThrows) throw StateError('recognizer busy');
    lastLocale = localeId;
    _onResult = onResult;
    _onStatus?.call('listening');
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _onStatus?.call('notListening');
    _onStatus?.call('done');
  }

  @override
  Future<void> cancel() async {}

  void emit(String words, {bool isFinal = false}) =>
      _onResult?.call(words, isFinal);
  void error(String code, {bool permanent = true}) =>
      _onError?.call(code, permanent);
  void status(String s) => _onStatus?.call(s);
}

void _resetCallbacks(WebVoiceService voice) {
  voice
    ..onTranscriptReceived = null
    ..onFinalTranscript = null
    ..onListeningChanged = null
    ..onError = null;
}

void main() {
  final voice = WebVoiceService.instance;

  setUpAll(() async {
    // No OS in widget tests: report the microphone as granted so the fake
    // recognizer stays the permission authority, as before permission_handler
    // was introduced. The denial paths are driven by FakeSpeechEngine flags.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          (call) async {
            if (call.method == 'checkPermissionStatus') return 1;
            if (call.method == 'requestPermissions') return {0: 1};
            return null;
          },
        );
    // Real fonts instead of Ahem squares, as in responsive_matrix_test.
    for (final font in {
      'Newsreader': 'newsreader',
      'Inter': 'inter',
      'PlusJakartaSans': 'plusjakartasans',
    }.entries) {
      await (FontLoader(font.key)..addFont(
            File(
              'assets/fonts/${font.value}.ttf',
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          ))
          .load();
    }
  });

  tearDown(() {
    _resetCallbacks(voice);
    voice.debugEngine = null;
  });

  group('native voice service', () {
    test(
      'permission denied reports failure and never claims success',
      () async {
        final engine = FakeSpeechEngine(initOk: false, permission: false);
        voice.debugEngine = engine;
        final errors = <VoiceInputFailure>[];
        voice.onError = (failure, _) => errors.add(failure);

        final started = await voice.startListening();

        expect(started, isFalse);
        expect(voice.isListening, isFalse);
        expect(voice.state, VoiceInputState.error);
        expect(voice.lastFailure, VoiceInputFailure.permissionDenied);
        expect(errors, [VoiceInputFailure.permissionDenied]);
        expect(voice.lastFailureMessage, contains('Settings'));
        expect(voice.lastFailureMessage, contains('type your reply'));
      },
    );

    test(
      'initialize fails with permission granted means unsupported',
      () async {
        voice.debugEngine = FakeSpeechEngine(initOk: false, permission: true);

        expect(await voice.startListening(), isFalse);
        expect(voice.lastFailure, VoiceInputFailure.unsupported);
        expect(voice.lastFailureMessage, contains('not available'));
      },
    );

    test('a recognizer that throws is treated as unsupported', () async {
      voice.debugEngine = _ThrowingEngine();

      expect(await voice.startListening(), isFalse);
      expect(voice.lastFailure, VoiceInputFailure.unsupported);
    });

    test('listen failure is reported as an error', () async {
      voice.debugEngine = FakeSpeechEngine(listenThrows: true);

      expect(await voice.startListening(), isFalse);
      expect(voice.isListening, isFalse);
      expect(voice.lastFailure, VoiceInputFailure.error);
    });

    test('defaults to de-DE and streams interim then final results', () async {
      final engine = FakeSpeechEngine();
      voice.debugEngine = engine;
      final interim = <String>[];
      final finals = <String>[];
      voice.onTranscriptReceived = interim.add;
      voice.onFinalTranscript = finals.add;

      expect(await voice.startListening(), isTrue);
      expect(engine.lastLocale, 'de-DE');
      expect(voice.isListening, isTrue);
      expect(voice.state, VoiceInputState.listening);

      engine.emit('Ich hätte');
      engine.emit('Ich hätte gern');
      engine.emit('Ich hätte gern einen Kaffee', isFinal: true);

      expect(interim, [
        'Ich hätte',
        'Ich hätte gern',
        'Ich hätte gern einen Kaffee',
      ]);
      expect(finals, ['Ich hätte gern einen Kaffee']);
    });

    test('stop ends the session and reports idle', () async {
      final engine = FakeSpeechEngine();
      voice.debugEngine = engine;
      expect(await voice.startListening(), isTrue);

      voice.stopListening();
      await Future<void>.delayed(Duration.zero);

      expect(engine.stopCalls, 1);
      expect(voice.isListening, isFalse);
      expect(voice.state, VoiceInputState.idle);
      expect(voice.lastFailure, isNull);
    });

    test('recognizer stopping on its own notifies listeners', () async {
      final engine = FakeSpeechEngine();
      voice.debugEngine = engine;
      final changes = <bool>[];
      voice.onListeningChanged = changes.add;
      expect(await voice.startListening(), isTrue);

      engine.status('notListening');

      expect(changes.last, isFalse);
      expect(voice.isListening, isFalse);
      expect(voice.state, VoiceInputState.idle);
    });

    test('runtime permission error mid-session maps to denial', () async {
      final engine = FakeSpeechEngine();
      voice.debugEngine = engine;
      final errors = <VoiceInputFailure>[];
      voice.onError = (failure, _) => errors.add(failure);
      expect(await voice.startListening(), isTrue);

      engine.error('error_no_match', permanent: false);
      engine.error('error_permission');

      expect(errors, [
        VoiceInputFailure.noSpeech,
        VoiceInputFailure.permissionDenied,
      ]);
      expect(voice.isListening, isFalse);
    });

    test('initialization is retried after a denial', () async {
      final engine = FakeSpeechEngine(initOk: false, permission: false);
      voice.debugEngine = engine;
      expect(await voice.startListening(), isFalse);

      engine
        ..initOk = true
        ..permission = true;
      expect(await voice.startListening(), isTrue);
      expect(engine.initCalls, 2);
      expect(voice.lastFailure, isNull);
    });
  });

  group('voice screens fall back to typing', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Future<void> pumpScreen(WidgetTester tester, Widget child) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeLessonProvider.overrideWith(_ActiveLesson.new),
          ],
          child: MaterialApp(
            theme: buildTalkloomTheme(Brightness.light),
            home: Scaffold(body: child),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 6));
    }

    testWidgets('speak: denial shows honest error, Open Settings, composer', (
      tester,
    ) async {
      voice.debugEngine = FakeSpeechEngine(initOk: false, permission: false);
      await pumpScreen(tester, const SpeakScreen());

      await tester.tap(find.byIcon(Icons.mic_none).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Turn it on in Settings'), findsWidgets);
      expect(find.text('Open Settings'), findsOneWidget);
      // Mic button is back to idle, not stuck on "Stop".
      expect(find.byIcon(Icons.stop), findsNothing);
      // The typed composer is still there and usable.
      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.enabled, isNot(false));
      await unmount(tester);
    });

    testWidgets('speak: interim transcript fills the composer', (tester) async {
      final engine = FakeSpeechEngine();
      voice.debugEngine = engine;
      await pumpScreen(tester, const SpeakScreen());

      await tester.tap(find.byIcon(Icons.mic_none).first);
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsWidgets);

      engine.emit('Guten');
      await tester.pump();
      engine.emit('Guten Morgen', isFinal: true);
      await tester.pump();

      expect(find.text('Guten Morgen'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('immersive modal: unsupported keeps typed reply', (
      tester,
    ) async {
      voice.debugEngine = FakeSpeechEngine(initOk: false, permission: true);
      await pumpScreen(tester, const ImmersiveVoiceModal());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('not available on this device'), findsWidgets);
      expect(find.text('Open Settings'), findsNothing);
      expect(find.byKey(const ValueKey('typed-reply-field')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('voice arena: denial keeps typed reply', (tester) async {
      voice.debugEngine = FakeSpeechEngine(initOk: false, permission: false);
      await pumpScreen(tester, const VoiceArenaScreen());
      expect(find.byKey(const ValueKey('typed-reply-field')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('talk canvas: denial shows error and Type instead', (
      tester,
    ) async {
      voice.debugEngine = FakeSpeechEngine(initOk: false, permission: false);
      await pumpScreen(tester, const TalkCanvasScreen());

      await tester.tap(find.bySemanticsLabel('Start speaking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Turn it on in Settings'), findsWidgets);
      expect(find.text('Type instead'), findsOneWidget);
      await unmount(tester);
    });
  });
}

class _ThrowingEngine extends FakeSpeechEngine {
  @override
  Future<bool> initialize({
    required void Function(String code, bool permanent) onError,
    required void Function(String status) onStatus,
  }) => Future.error(Exception('MissingPluginException'));

  @override
  Future<bool> hasPermission() => Future.error(Exception('no plugin'));
}
