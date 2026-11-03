import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/core/platform/web_voice_service.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/features/lesson/activity_view.dart';

Widget _host() => MaterialApp(
  theme: buildTalkloomTheme(Brightness.light),
  home: Scaffold(
    body: SingleChildScrollView(
      child: ActivityView(
        activity: const SentenceBuilderActivity(
          target: 'Ich lerne Deutsch',
          scrambledTokens: ['Deutsch', 'Ich', 'lerne'],
        ),
        onCompleted: () {},
      ),
    ),
  ),
);

void main() {
  tearDown(() => WebVoiceService.instance.debugCanSpeak = null);

  testWidgets('Listen button is disabled with an honest label without audio', (
    t,
  ) async {
    WebVoiceService.instance.debugCanSpeak = false;
    await t.pumpWidget(_host());
    expect(find.text('Audio unavailable'), findsOneWidget);
    expect(find.text('Listen'), findsNothing);
    expect(
      find.byTooltip('Audio is not available on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('Listen button is offered when audio is available', (t) async {
    WebVoiceService.instance.debugCanSpeak = true;
    await t.pumpWidget(_host());
    expect(find.text('Listen'), findsOneWidget);
    expect(find.text('Audio unavailable'), findsNothing);
  });
}
