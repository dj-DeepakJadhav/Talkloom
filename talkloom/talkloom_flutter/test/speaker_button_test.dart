import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/app_icons.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/domain/practice_engine.dart';
import 'package:talkloom_flutter/features/practice/practice_session_screen.dart';

const _brot = VocabularyItem(id: 'brot', lemma: 'Brot', meaning: 'bread');

/// No backend or audio hardware in widget tests: the mocked channels make
/// playback fail fast so the button must settle back to idle on the real
/// completion future instead of hanging or relying on a fixed timer.
void _mockAudioChannels() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (
    call,
  ) async {
    if (call.method == 'speak') {
      throw PlatformException(code: 'unavailable');
    }
    if (call.method == 'getVoices') return <Map<String, String>>[];
    return 1;
  });
}

Future<Widget> _app() async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    child: MaterialApp(
      theme: buildTalkloomTheme(Brightness.light),
      home: PracticeSessionScreen(
        args: PracticeSessionArgs(
          title: 'Test link',
          set: PracticeSet(
            exercises: const [WordIntroExercise(_brot)],
            words: const [_brot],
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(_mockAudioChannels);

  testWidgets('speaker button follows real playback, not a fixed timer', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());
    await tester.pumpAndSettle();

    // Intro card renders its large speaker button idle.
    expect(find.byIcon(AppIcons.volume1), findsOneWidget);
    expect(find.byIcon(AppIcons.volume2), findsNothing);

    // Tapping plays (failing fast with no backend) and always settles
    // back to idle through the real completion future.
    await tester.tap(find.byTooltip('Listen'));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.volume1), findsOneWidget);
    expect(find.byIcon(AppIcons.volume2), findsNothing);
  });
}
