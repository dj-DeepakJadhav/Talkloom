import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/design/components/tl_surface.dart';
import 'package:talkloom_flutter/features/words/words_screen.dart';

void main() {
  testWidgets('TlPressable is keyboard and semantics accessible', (t) async {
    var taps = 0;
    final handle = t.ensureSemantics();
    await t.pumpWidget(
      MaterialApp(
        theme: buildTalkloomTheme(Brightness.light),
        home: Scaffold(
          body: TlPressable(
            semanticLabel: 'Do it',
            onTap: () => taps++,
            child: const SizedBox(width: 48, height: 48),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Do it'), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pump();
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('Words empty state at 375px has no overflow or fake data', (
    t,
  ) async {
    t.view.physicalSize = const Size(375, 812);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      ProviderScope(
        overrides: [lessonsProvider.overrideWith((ref) async => [])],
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.light),
          home: const Scaffold(body: WordsScreen()),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Your words start here.'), findsOneWidget);
    expect(find.textContaining('Growing'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
