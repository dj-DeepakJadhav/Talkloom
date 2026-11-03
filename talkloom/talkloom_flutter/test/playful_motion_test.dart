import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/design/components/tl_sticker.dart';
import 'package:talkloom_flutter/design/components/tl_arrival.dart';
import 'package:talkloom_flutter/design/components/tl_surface.dart';

Widget _host(
  Widget child, {
  bool reduced = false,
  Brightness brightness = Brightness.light,
}) => MaterialApp(
  key: UniqueKey(),
  theme: buildTalkloomTheme(brightness),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('decorative motion finishes and leaves no perpetual frame loop', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TlDiscoveryScene()));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion presents every sticker without starting animation',
    (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _host(
            Wrap(
              children: [
                for (final kind in TlStickerKind.values)
                  TlArrival(child: TlSticker(kind: kind, size: 80)),
              ],
            ),
            reduced: true,
            brightness: brightness,
          ),
        );
        await tester.pump();
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('inactive screens do not start decorative tickers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const TickerMode(enabled: false, child: TlDiscoveryScene())),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets(
    'press feedback fires the action once and does not delay navigation',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          TlPressable(
            semanticLabel: 'Open lesson',
            onTap: () => taps++,
            child: const SizedBox(
              width: 100,
              height: 56,
              child: Text('Open lesson'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open lesson'));
      expect(taps, 1);
      await tester.pumpAndSettle();
      expect(taps, 1);
    },
  );
}
