// Responsive matrix: pumps every screen and sheet at phone/tablet/landscape
// sizes, 1.0x and 1.5x text scale, with a safe-area inset and with a keyboard
// inset, and fails on any layout overflow or framework exception.
//
// Run: flutter test test/responsive_matrix_test.dart
// A per-screen x per-size matrix is printed at the end of the run.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/app/app_viewport.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/app/router.dart';
import 'package:talkloom_flutter/client.dart' as app_client;
import 'package:talkloom_flutter/data/lesson_repository.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/learning_session.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/features/arena/conversation_themes.dart';
import 'package:talkloom_flutter/features/arena/talk_canvas_screen.dart';
import 'package:talkloom_flutter/features/arena/voice_arena_screen.dart';
import 'package:talkloom_flutter/features/content/source_detail_screen.dart';
import 'package:talkloom_flutter/features/content/source_activity_screen.dart';
import 'package:talkloom_flutter/features/ingest/universal_ingest_sheet.dart';
import 'package:talkloom_flutter/features/lesson/activity_view.dart';
import 'package:talkloom_flutter/features/lesson/lesson_screen.dart';
import 'package:talkloom_flutter/features/onboarding/onboarding_screen.dart';
import 'package:talkloom_flutter/features/profile/profile_screen.dart';
import 'package:talkloom_flutter/features/sanctuary/sanctuary_screen.dart';
import 'package:talkloom_flutter/features/settings/api_keys_screen.dart';
import 'package:talkloom_flutter/features/shell/app_shell.dart';
import 'package:talkloom_flutter/features/speak/immersive_voice_modal.dart';
import 'package:talkloom_flutter/features/speak/speak_screen.dart';
import 'package:talkloom_flutter/features/stories/story_weaver_screen.dart';
import 'package:talkloom_flutter/features/themes/themes_screen.dart';
import 'package:talkloom_flutter/features/vault/lexicon_vault_screen.dart';
import 'package:talkloom_flutter/features/words/words_screen.dart';
import 'package:talkloom_flutter/screens/sign_in_screen.dart';
import 'package:talkloom_flutter/core/platform/web_voice_service.dart';
import 'package:talkloom_flutter/domain/practice_engine.dart';
import 'package:talkloom_flutter/features/practice/practice_session_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures. Deliberately long strings: a long title, a long compound word and a
// long explanation are what break phone layouts, not the happy-path sample.
// ---------------------------------------------------------------------------

final _source = Source(
  id: 7,
  userId: 'test',
  type: 'text',
  title:
      'A very long morning at the neighbourhood café with an unusually long '
      'title that must wrap',
  rawText: 'Ich hätte gern einen Kaffee. Zum Mitnehmen, bitte. ' * 12,
  targetLanguage: 'de',
  cefrLevel: 'A2',
  createdAt: DateTime.utc(2026, 10, 5),
);

final _lesson = Lesson(
  id: 9,
  userId: 'test',
  sourceId: 7,
  targetLanguage: 'de',
  supportLanguage: 'en',
  objectives: [
    'Order a coffee and explain exactly what you would like to the person '
        'behind the counter.',
    'Ask politely for something to take away.',
  ],
  vocabulary:
      '[{"id":"de:mitnehmen","lemma":"mitnehmen","meaning":"to take away with you when leaving","sourceContext":"Zum Mitnehmen, bitte."},'
      '{"id":"de:abs","lemma":"Donaudampfschifffahrtsgesellschaftskapitaen","article":"der","meaning":"a deliberately very long compound noun","sourceContext":"Der Donaudampfschifffahrtsgesellschaftskapitaen kommt."},'
      '{"id":"de:haus","lemma":"Haus","article":"das","meaning":"house"},'
      '{"id":"de:tisch","lemma":"Tisch","article":"der","meaning":"table"}]',
  grammar:
      '[{"concept":"Polite requests with the Konjunktiv II","sourceSentence":"Ich hätte gern einen Kaffee.","explanation":"Use hätte gern to ask politely instead of a direct demand."}]',
  activities:
      '[{"type":"context_choice","question":"Which phrase would you use to politely order a coffee to go?","options":["Ich hätte gern einen Kaffee zum Mitnehmen.","Gib mir Kaffee.","Wo ist der Bahnhof?"],"correctIndex":0},'
      '{"type":"sentence_builder","target":"Ich hätte gern einen Kaffee zum Mitnehmen bitte","scrambledTokens":["Kaffee","hätte","Ich","zum","gern","einen","Mitnehmen","bitte"]},'
      '{"type":"speak_response","objective":"Order a coffee and say you would like it to take away."}]',
  conversationPlan:
      '{"role":"barista","situation":"Ordering at a busy café during the morning rush","hiddenTargets":["de:mitnehmen"],"culturalNotes":["Tipping is small."]}',
  createdAt: DateTime.utc(2026, 10, 5),
);

final _content = LessonContent.fromLesson(_lesson);

final _learnerState = LearnerState(
  userId: 'test',
  targetLanguage: 'de',
  recognizedWords: ['mitnehmen', 'Haus'],
  activeWords: ['Tisch'],
  grammarMastery: '{}',
  updatedAt: DateTime.utc(2026, 10, 5),
);

class _FakeRepository extends LessonRepository {
  _FakeRepository() : super(Client('http://localhost:1/'));

  @override
  Future<ConversationTurn> speak({
    required LearningSession session,
    required String role,
    required String situation,
    required List<String> hiddenTargets,
    required List<String> previousTurns,
    required String utterance,
    required double latencySec,
    int? lessonId,
  }) async => ConversationTurn.fromJson({'reply': 'Guten Tag'}, latencySec);
}

class _ActiveLesson extends ActiveLessonController {
  @override
  LessonContent? build() => _content;
}

class _SelectedSource extends SelectedSourceController {
  @override
  Source? build() => _source;
}

// ---------------------------------------------------------------------------
// Screen catalogue
// ---------------------------------------------------------------------------

class _Screen {
  const _Screen(this.name, this.build, {this.open});
  final String name;
  final Widget Function() build;

  /// Opens a modal sheet over the host once it has been pumped.
  final void Function(BuildContext context)? open;
}

Widget _button(void Function(BuildContext) open) => Builder(
  builder: (context) => Center(
    child: TextButton(onPressed: () => open(context), child: const Text('x')),
  ),
);

final _screens = <_Screen>[
  _Screen('sign-in', () => const SignInScreen()),
  _Screen('onboarding', () => const OnboardingScreen()),
  _Screen('shell: Home', () => const AppShell(initialIndex: 0)),
  _Screen('shell: My learning', () => const AppShell(initialIndex: 1)),
  _Screen('shell: Profile', () => const AppShell(initialIndex: 2)),
  _Screen('Your languages', () => const LanguagesScreen()),
  _Screen('Add a language', () => const AddLanguageScreen()),
  _Screen('source detail', () => const SourceDetailScreen(sourceId: 7)),
  _Screen('vocabulary', () => const VocabularyActivityScreen()),
  _Screen('grammar', () => const GrammarActivityScreen()),
  _Screen(
    'Play',
    () => PracticeSessionScreen(
      args: PracticeSessionArgs(
        title: _source.title,
        set: PracticeBuilder().build(
          vocabulary: _content.vocabulary,
          grammar: _content.grammar,
          activities: _content.activities,
          canSpeak: false,
        ),
      ),
    ),
  ),
  _Screen('lesson', () => const LessonScreen()),
  _Screen(
    'activity: context choice',
    () => _activity(_content.activities[0]),
  ),
  _Screen(
    'activity: sentence builder',
    () => _activity(_content.activities[1]),
  ),
  _Screen('activity: speak prompt', () => _activity(_content.activities[2])),
  _Screen('speak', () => const SpeakScreen()),
  _Screen(
    'immersive voice modal',
    () => _button(ImmersiveVoiceModal.show),
    open: ImmersiveVoiceModal.show,
  ),
  _Screen(
    'ingest sheet',
    () => _button(UniversalIngestSheet.show),
    open: UniversalIngestSheet.show,
  ),
  _Screen(
    'settings (API keys sheet)',
    () => _button(ApiKeysSheet.show),
    open: ApiKeysSheet.show,
  ),
  _Screen('vault', () => const LexiconVaultScreen()),
  _Screen('sanctuary', () => const SanctuaryScreen()),
  _Screen('stories', () => const StoryWeaverScreen()),
  _Screen('themes', () => const ThemesScreen()),
  _Screen('words', () => const WordsScreen()),
  _Screen('voice arena', () => const VoiceArenaScreen()),
  _Screen('talk canvas', () => const TalkCanvasScreen()),
  _Screen(
    'themes picker sheet',
    () => _button((c) => ThemesPickerSheet.show(c, onSelectTheme: (_) {})),
    open: (c) => ThemesPickerSheet.show(c, onSelectTheme: (_) {}),
  ),
];

Widget _activity(LessonActivity activity) => SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
    child: ActivityView(activity: activity, onCompleted: () {}),
  ),
);

// ---------------------------------------------------------------------------
// Variants
// ---------------------------------------------------------------------------

class _Size {
  const _Size(this.label, this.w, this.h);
  final String label;
  final double w;
  final double h;
}

const _portraits = [
  _Size('320x568', 320, 568),
  _Size('375x812', 375, 812),
  _Size('414x896', 414, 896),
  _Size('768x1024', 768, 1024),
];
const _landscapes = [_Size('812x375', 812, 375), _Size('568x320', 568, 320)];
const _desktop = [_Size('1280x800', 1280, 800)];

enum _Inset { none, safeArea, keyboard }

const _dpr = 2.0;

class _Variant {
  const _Variant(this.size, this.scale, this.inset);
  final _Size size;
  final double scale;
  final _Inset inset;
  @override
  String toString() => '${size.label} @${scale}x ${inset.name}';
}

final _variants = <_Variant>[
  for (final size in [..._portraits, ..._landscapes, ..._desktop])
    for (final scale in const [1.0, 1.5])
      for (final inset in _Inset.values)
        // Landscape and desktop windows have no soft keyboard that leaves a
        // usable app (landscape IMEs go full screen), so that case is skipped.
        if (inset != _Inset.keyboard || size.h > size.w)
          _Variant(size, scale, inset),
];

/// Links drawn by serverpod_auth_idp_flutter's email form inside a hard-coded
/// 24px-high SizedBox; they cannot be resized from this app (documented in the
/// report), so they are excluded from the touch-target audit.
const _thirdPartyLinks = {'Forgot password?', 'Sign up'};

/// Results collected for the final matrix: screen -> size label -> failures.
final _results = <String, Map<String, List<String>>>{};

/// Distinct findings per screen: finding -> number of variants it appears in.
final _findings = <String, Map<String, int>>{};

Future<List<String>> _runVariant(
  WidgetTester tester,
  _Screen screen,
  _Variant v,
  SharedPreferences prefs,
) async {
  final view = tester.view;
  view.devicePixelRatio = _dpr;
  view.physicalSize = Size(v.size.w * _dpr, v.size.h * _dpr);
  const top = 47.0, bottom = 34.0;
  final landscape = v.size.w > v.size.h;
  final side = landscape ? 47.0 : 0.0;
  switch (v.inset) {
    case _Inset.none:
      view.padding = FakeViewPadding.zero;
      view.viewPadding = FakeViewPadding.zero;
      view.viewInsets = FakeViewPadding.zero;
    case _Inset.safeArea:
      final p = FakeViewPadding(
        left: side * _dpr,
        right: side * _dpr,
        top: (landscape ? 0 : top) * _dpr,
        bottom: bottom * _dpr,
      );
      view.padding = p;
      view.viewPadding = p;
      view.viewInsets = FakeViewPadding.zero;
    case _Inset.keyboard:
      // With the keyboard up the OS reports padding.bottom as 0 while
      // viewPadding keeps the home-indicator inset.
      view.padding = FakeViewPadding(top: (landscape ? 0 : top) * _dpr);
      view.viewPadding = FakeViewPadding(
        top: (landscape ? 0 : top) * _dpr,
        bottom: bottom * _dpr,
      );
      view.viewInsets = const FakeViewPadding(bottom: 300 * _dpr);
  }
  tester.platformDispatcher.textScaleFactorTestValue = v.scale;

  final errors = <String>[];
  final captureKey = GlobalKey();
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    final summary = text.split('\n').first;
    final isOverflow = summary.contains('overflowed');
    final where = RegExp(
      r'lib/[\w/]+\.dart:\d+',
    ).firstMatch(details.toString());
    errors.add(
      isOverflow
          ? 'overflow: ${summary.replaceAll('A RenderFlex overflowed by ', '')} '
                '@ ${where?.group(0) ?? '?'}'
          : 'exception: $summary @ ${where?.group(0) ?? '?'}',
    );
  };
  try {
    await tester.pumpWidget(
      ProviderScope(
        key: UniqueKey(),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          lessonRepositoryProvider.overrideWithValue(_FakeRepository()),
          authRouteStateProvider.overrideWith(
            (ref) => AuthRouteState(isAuthenticated: () => true),
          ),
          sourcesProvider.overrideWith((ref) async => [_source]),
          lessonsProvider.overrideWith((ref) async => [_lesson]),
          learnerStateProvider.overrideWith((ref) async => _learnerState),
          wordEvidenceProvider.overrideWith((ref) async => const []),
          sourceLessonProvider(7).overrideWith((ref) async => _lesson),
          activeLessonProvider.overrideWith(_ActiveLesson.new),
          selectedSourceProvider.overrideWith(_SelectedSource.new),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTalkloomTheme(Brightness.light),
          builder: (context, child) => RepaintBoundary(
            key: captureKey,
            child: TlAppViewport(child: child ?? const SizedBox.shrink()),
          ),
          home: Material(child: _Host(screen)),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    if (screen.open != null) {
      screen.open!(tester.element(find.byType(TextButton).first));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
    }
    // Touch targets are size-independent, so audit them once per scale on a
    // common phone viewport rather than in every variant.
    if (v.size.label == '375x812' && v.inset == _Inset.none) {
      if (const bool.fromEnvironment('CAPTURE_DESIGN') && v.scale == 1) {
        await tester.runAsync(
          () => precacheImage(
            const AssetImage('assets/illustrations/share-and-learn.png'),
            tester.element(find.byType(MaterialApp)),
          ),
        );
        await tester.pump();
        await tester.runAsync(() async {
          final boundary =
              captureKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final shot = await boundary.toImage(pixelRatio: 2);
          final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/design-review').createSync(recursive: true);
          await File(
            'build/design-review/${screen.name.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-').toLowerCase()}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          shot.dispose();
        });
      }
      final handle = tester.ensureSemantics();
      await tester.pump();
      final result = await iOSTapTargetGuideline.evaluate(tester);
      handle.dispose();
      if (!result.passed) {
        for (final line in (result.reason ?? '').split('\n')) {
          final label = RegExp(r'label: "([^"]*)"').firstMatch(line)?.group(1);
          final size = RegExp(r'found Size\(([^)]*)\)').firstMatch(line);
          if (size == null) continue;
          if (screen.name == 'sign-in' && _thirdPartyLinks.contains(label)) {
            continue;
          }
          errors.add('touch: ${label ?? 'unlabelled'} ${size.group(1)}');
        }
      }
    }
    // Tear down inside the guarded region so dispose-time errors count too.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  } catch (e) {
    errors.add('exception: ${e.toString().split('\n').first}');
  } finally {
    FlutterError.onError = original;
    tester.takeException();
  }
  return errors.toSet().toList();
}

class _Host extends StatelessWidget {
  const _Host(this.screen);
  final _Screen screen;
  @override
  Widget build(BuildContext context) => screen.build();
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    WebVoiceService.instance.debugCanSpeak = false;
    await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
          rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
        ))
        .load();
    // flutter test renders every glyph as a full-em Ahem square, which makes
    // text ~1.8x wider than reality and floods the matrix with false
    // overflows. Load the bundled fonts so measurements are realistic.
    for (final font in {
      'Newsreader': 'newsreader',
      'Inter': 'inter',
      'PlusJakartaSans': 'plusjakartasans',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          File('assets/fonts/${font.value}.ttf').readAsBytes().then(
            (bytes) => ByteData.sublistView(bytes),
          ),
        );
      await loader.load();
    }
    // SignInScreen reads the global client; point it at an unreachable host.
    app_client.client = Client('http://localhost:1/')
      ..authSessionManager = FlutterAuthSessionManager(
        storage: app_client.MemoryAuthStorage(),
      );
    await app_client.client.auth.initialize();
  });

  tearDownAll(() {
    WebVoiceService.instance.debugCanSpeak = null;
    final sizes = [..._portraits, ..._landscapes, ..._desktop];
    final buf = StringBuffer('\n=== RESPONSIVE MATRIX (P=pass F=fail) ===\n');
    buf.writeln(
      '${'screen'.padRight(28)}${sizes.map((s) => s.label.padRight(10)).join()}',
    );
    for (final screen in _screens) {
      final row = _results[screen.name] ?? {};
      buf.write(screen.name.padRight(28));
      for (final s in sizes) {
        final fails = row[s.label] ?? const [];
        buf.write((fails.isEmpty ? 'P' : 'F(${fails.length})').padRight(10));
      }
      buf.writeln();
    }
    buf.writeln('\n=== DISTINCT FINDINGS (variants affected) ===');
    for (final screen in _screens) {
      final f = _findings[screen.name];
      if (f == null) continue;
      buf.writeln(screen.name);
      for (final e in f.entries) {
        buf.writeln('  ${e.value.toString().padLeft(3)}  ${e.key}');
      }
    }
    // ignore: avoid_print
    print(buf);
  });

  for (final screen in _screens) {
    testWidgets('responsive: ${screen.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      addTearDown(() {
        tester.view.reset();
        tester.platformDispatcher.clearAllTestValues();
      });
      final failures = <String>[];
      final row = _results.putIfAbsent(screen.name, () => {});
      for (final v in _variants) {
        final errors = await _runVariant(tester, screen, v, prefs);
        row.putIfAbsent(v.size.label, () => []);
        if (errors.isNotEmpty) {
          row[v.size.label]!.add('$v');
          failures.add('$v -> ${errors.take(4).join(' | ')}');
          final seen = _findings.putIfAbsent(screen.name, () => {});
          for (final e in errors) {
            final key = e.replaceAll(RegExp(r'[\d.]+ pixels'), 'N px');
            seen[key] = (seen[key] ?? 0) + 1;
          }
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
