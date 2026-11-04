import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/app/router.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/stories/story_weaver_screen.dart';
import 'package:talkloom_flutter/features/words/words_screen.dart';

final _source = Source(
  id: 7,
  userId: 'test',
  type: 'text',
  title: 'A morning at the café',
  rawText: 'Ich hätte gern einen Kaffee. Zum Mitnehmen, bitte.',
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
  objectives: ['Order a coffee and explain what you would like.'],
  vocabulary:
      '[{"id":"de:mitnehmen","lemma":"mitnehmen","meaning":"to take away","sourceContext":"Zum Mitnehmen, bitte."}]',
  grammar:
      '[{"concept":"Polite requests","sourceSentence":"Ich hätte gern einen Kaffee.","explanation":"Use hätte gern to ask politely."}]',
  activities: '[]',
  conversationPlan:
      '{"role":"barista","situation":"Ordering at a café","hiddenTargets":["de:mitnehmen"]}',
  createdAt: DateTime.utc(2026, 10, 5),
);

final _captureKey = GlobalKey();

class _BackgroundImport extends ImportController {
  void start() => state = const AsyncValue.loading();
  void fail() =>
      state = AsyncValue.error(Exception('Import failed'), StackTrace.current);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_DESIGN')) return;
  await tester.runAsync(() async {
    final boundary =
        _captureKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/design-review')
      ..createSync(recursive: true);
    await File(
      '${directory.path}/$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _mount(
  WidgetTester tester, {
  bool empty = false,
  bool unfinished = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(800, 1700);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        importControllerProvider.overrideWith(_BackgroundImport.new),
        sharedPreferencesProvider.overrideWithValue(preferences),
        authRouteStateProvider.overrideWith(
          (ref) => AuthRouteState(isAuthenticated: () => true),
        ),
        sourcesProvider.overrideWith((ref) async => empty ? [] : [_source]),
        lessonsProvider.overrideWith((ref) async => empty ? [] : [_lesson]),
        sourceLessonProvider(
          7,
        ).overrideWith((ref) async => unfinished ? null : _lesson),
      ],
      child: Consumer(
        builder: (context, ref, _) => RepaintBoundary(
          key: _captureKey,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: buildTalkloomTheme(Brightness.light),
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('background preparation remains visible and can be reopened', (
    tester,
  ) async {
    await _mount(tester, empty: true);
    final container = ProviderScope.containerOf(
      tester.element(find.text('Add content')),
    );
    (container.read(importControllerProvider.notifier) as _BackgroundImport)
        .start();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Preparing your content'), findsOneWidget);
    await tester.tap(find.text('View progress'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Getting ready'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Practice later'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Preparing your content'), findsOneWidget);
    expect(container.read(importControllerProvider).isLoading, isTrue);
    (container.read(importControllerProvider.notifier) as _BackgroundImport)
        .fail();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Could not prepare content'), findsOneWidget);
    expect(find.text('Try another source'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'vocabulary and grammar load from a source without active lesson state',
    (tester) async {
      await _mount(tester);
      await tester.tap(find.byTooltip('Continue learning').first);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Vocabulary'));
      await tester.tap(find.text('Vocabulary'));
      await tester.pumpAndSettle();
      expect(find.text('mitnehmen'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      await _capture(tester, 'vocabulary');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Grammar'));
      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();
      expect(find.text('Polite requests'), findsOneWidget);
      expect(find.text('Use hätte gern to ask politely.'), findsOneWidget);
      await _capture(tester, 'grammar');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile exposes working audio and accessibility preferences', (
    tester,
  ) async {
    await _mount(tester);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await _capture(tester, 'profile');
    await tester.tap(find.text('Audio & speech'));
    await tester.pumpAndSettle();
    expect(find.text('Read replies aloud'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.text('Read replies aloud')),
    );
    expect(container.read(appPreferencesProvider).readReplies, isFalse);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Accessibility'));
    await tester.tap(find.text('Accessibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(container.read(appPreferencesProvider).reduceMotion, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source detail and My learning stay in the three-tab shell', (
    tester,
  ) async {
    await _mount(tester);
    await tester.tap(find.byTooltip('Continue learning').first);
    await tester.pumpAndSettle();
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('My learning').last);
    await tester.pumpAndSettle();
    expect(find.text('My learning'), findsWidgets);
    expect(find.text('Your next conversation'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'unfinished source offers preparation instead of a dead-end reload',
    (tester) async {
      await _mount(tester, unfinished: true);
      await tester.tap(find.byTooltip('Continue learning').first);
      await tester.pumpAndSettle();
      expect(find.text('Prepare my lesson'), findsOneWidget);
      expect(find.text('Check again'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  setUpAll(() async {
    if (!const bool.fromEnvironment('CAPTURE_DESIGN')) return;
    for (final font in {
      'Newsreader': 'newsreader',
      'Inter': 'inter',
      'PlusJakartaSans': 'plusjakartasans',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(
          File(
            'assets/fonts/${font.value}.ttf',
          ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
        );
      await loader.load();
    }
    var sdkDirectory = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 8; i++) {
      if (Directory(
        '${sdkDirectory.path}/bin/cache/artifacts/material_fonts',
      ).existsSync()) {
        break;
      }
      sdkDirectory = sdkDirectory.parent;
    }
    final icons = File(
      '${sdkDirectory.path}/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(
            icons.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          ))
          .load();
    }
  });

  testWidgets('shared content stays connected through detail and speaking', (
    tester,
  ) async {
    await _mount(tester);
    expect(find.text('Your next conversation'), findsOneWidget);
    await _capture(tester, 'today');
    await tester.tap(find.byTooltip('Continue learning').first);
    await tester.pumpAndSettle();
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Grammar'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Speak'), findsOneWidget);
    await _capture(tester, 'source-detail');
    await tester.ensureVisible(find.text('Speak').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speak').last);
    await tester.pumpAndSettle();
    expect(find.text('A morning at the café'), findsOneWidget);
    expect(find.text('What caught your attention?'), findsOneWidget);
    await _capture(tester, 'speaking');
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone keeps source and speaking controls accessible', (
    tester,
  ) async {
    await _mount(tester);
    tester.view.physicalSize = const Size(720, 1280);
    await tester.pumpAndSettle();
    expect(find.text('Your next conversation'), findsOneWidget);
    expect(find.byTooltip('Continue learning'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add content rejects an incomplete link before importing', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _mount(tester, empty: true);
    await tester.tap(find.text('Add content').first);
    await tester.pumpAndSettle();
    for (final label in ['Link', 'Text', 'Scan', 'Upload']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Learn now'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a complete video or web link.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('empty collection invites an import without sample lessons', (
    tester,
  ) async {
    await _mount(tester, empty: true);
    expect(find.text('Add content'), findsOneWidget);
    expect(find.textContaining('Kaution'), findsNothing);
    await tester.tap(find.text('My learning').last);
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Add content'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a source'), findsNothing);
    expect(find.text('Paste a link'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('words and grammar come from saved sources', (tester) async {
    await _mount(tester);
    await tester.tap(find.text('My learning').last);
    await tester.pumpAndSettle();
    expect(find.text('mitnehmen'), findsOneWidget);
    expect(find.text('From A morning at the café'), findsOneWidget);
    await _capture(tester, 'my-german');
    await tester.tap(find.textContaining('Grammar ('));
    await tester.pumpAndSettle();
    expect(find.text('Polite requests'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('words screen never substitutes sample words or mastery', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [lessonsProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.light),
          home: const Scaffold(body: WordsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Kaution'), findsNothing);
    expect(find.textContaining('Growing'), findsNothing);
    expect(find.text('Your words start here.'), findsOneWidget);
  });

  testWidgets('story screen labels unimplemented source audio honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.light),
          home: const Scaffold(body: StoryWeaverScreen()),
        ),
      ),
    );
    expect(
      find.textContaining('Stories from your content are not available yet'),
      findsOneWidget,
    );
  });
}
