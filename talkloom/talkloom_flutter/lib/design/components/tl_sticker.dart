import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../app_icons.dart';

enum TlStickerKind {
  book,
  grammar,
  play,
  speak,
  link,
  file,
  image,
  text,
  celebrate,
}

TlStickerKind stickerKindForIcon(IconData icon) =>
    {
      AppIcons.bookOpenText: TlStickerKind.book,
      AppIcons.spellCheck: TlStickerKind.grammar,
      AppIcons.gamepad2: TlStickerKind.play,
      AppIcons.speech: TlStickerKind.speak,
      AppIcons.link: TlStickerKind.link,
      AppIcons.fileUp: TlStickerKind.file,
      AppIcons.image: TlStickerKind.image,
      AppIcons.fileText: TlStickerKind.text,
    }[icon] ??
    TlStickerKind.book;

/// Native slab illustrations. Motion keys are adapted from fun-isometric's
/// MIT-licensed `hop` preset; attribution lives in Docs/design/motion-sources.md.
/// One short action, then a still hold. No network or animation-player runtime.
class TlSticker extends StatefulWidget {
  const TlSticker({
    super.key,
    required this.kind,
    this.size = 96,
    this.animate = true,
  });
  final TlStickerKind kind;
  final double size;
  final bool animate;

  @override
  State<TlSticker> createState() => _TlStickerState();
}

class _TlStickerState extends State<TlSticker>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
      _clock.value = 1;
    } else if (TickerMode.valuesOf(context).enabled && _clock.value == 0) {
      _clock.forward();
    }
  }

  @override
  void didUpdateWidget(TlSticker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kind != widget.kind &&
        widget.animate &&
        !MediaQuery.disableAnimationsOf(context)) {
      _clock.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => CustomPaint(
            painter: _StickerPainter(
              widget.kind,
              context.colors,
              math.min(_clock.value * 180, 94.0),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Key {
  const _Key(this.frame, this.value, [this.ease = Curves.easeOut]);
  final double frame;
  final double value;
  final Curve ease;
}

double _track(double frame, List<_Key> keys) {
  if (frame <= keys.first.frame) return keys.first.value;
  for (var i = 0; i < keys.length - 1; i++) {
    final a = keys[i], b = keys[i + 1];
    if (frame <= b.frame) {
      final t = a.ease.transform(
        ((frame - a.frame) / (b.frame - a.frame)).clamp(0, 1),
      );
      return a.value + (b.value - a.value) * t;
    }
  }
  return keys.last.value;
}

class _StickerPainter extends CustomPainter {
  _StickerPainter(this.kind, this.colors, this.frame);
  final TlStickerKind kind;
  final TlColors colors;
  final double frame;

  Color get ink => colors.textPrimary;
  Color get paper => colors.surfaceRaised;
  Color get gold => TlPalette.twine;
  Color get sand => TlPalette.bananaMilk;

  Path poly(List<Offset> points) => Path()..addPolygon(points, true);
  Path box(double x, double y, double w, double h, [double r = 4]) =>
      Path()..addRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
      );

  void shape(Canvas c, Path path, Color fill, {double depth = 0, Color? side}) {
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round;
    if (depth > 0) {
      final back = path.shift(Offset(-depth * .6, depth));
      c.drawPath(back, Paint()..color = side ?? gold);
      c.drawPath(back, pen);
      // Close the extrusion with intermediate slabs, keeping one silhouette.
      for (var d = depth; d > 0; d -= .4) {
        c.drawPath(
          path.shift(Offset(-d * .6, d)),
          Paint()..color = side ?? gold,
        );
      }
      c.drawPath(back, pen);
    }
    c.drawPath(path, Paint()..color = fill);
    c.drawPath(path, pen);
  }

  void line(Canvas c, List<Offset> points, {Color? color, double width = 1.6}) {
    final p = Path()..addPolygon(points, false);
    c.drawPath(
      p,
      Paint()
        ..color = color ?? ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void dot(Canvas c, double x, double y, double r, Color fill) => shape(
    c,
    Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)),
    fill,
  );

  void sparkle(Canvas c, double x, double y, double radius) {
    shape(
      c,
      poly([
        Offset(x, y - radius),
        Offset(x + radius * .3, y - radius * .3),
        Offset(x + radius, y),
        Offset(x + radius * .3, y + radius * .3),
        Offset(x, y + radius),
        Offset(x - radius * .3, y + radius * .3),
        Offset(x - radius, y),
        Offset(x - radius * .3, y - radius * .3),
      ]),
      paper,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);
    final dy =
        _track(frame, const [
          _Key(0, 0, Cubic(.64, 0, .47, 1)),
          _Key(36, -24.25, Cubic(.59, 0, .52, 1)),
          _Key(54, 23.25, Cubic(.24, 0, .16, 1)),
          _Key(88, 0),
        ]) /
        5 *
        .6;
    final turn =
        _track(frame, const [
          _Key(0, 0, Cubic(.44, 0, .42, 1)),
          _Key(36, 9, Cubic(.42, 0, .44, 1)),
          _Key(54, -4, Cubic(.59, 0, .66, 1)),
          _Key(72, 2, Cubic(.37, 0, .51, 1)),
          _Key(94, 0),
        ]) *
        math.pi /
        180 *
        .6;
    canvas.save();
    canvas.translate(50, 50 + dy);
    canvas.rotate(turn);
    canvas.translate(-50, -50);
    // A leaned face and down-left side create actual slab depth.
    canvas.transform(
      (Matrix4.identity()
            ..setEntry(0, 1, -.14)
            ..setEntry(1, 0, .08))
          .storage,
    );
    switch (kind) {
      case TlStickerKind.book:
        shape(
          canvas,
          poly(const [
            Offset(24, 32),
            Offset(49, 35),
            Offset(72, 29),
            Offset(77, 64),
            Offset(51, 74),
            Offset(23, 67),
          ]),
          gold,
          depth: 6,
        );
        shape(
          canvas,
          poly(const [
            Offset(26, 28),
            Offset(50, 32),
            Offset(51, 67),
            Offset(27, 61),
          ]),
          paper,
          depth: 2,
        );
        shape(
          canvas,
          poly(const [
            Offset(50, 32),
            Offset(72, 25),
            Offset(74, 60),
            Offset(51, 67),
          ]),
          sand,
          depth: 2,
        );
        for (var i = 0; i < 3; i++) {
          line(canvas, [
            Offset(32, 37 + i * 7),
            Offset(44, 39 + i * 7),
          ], color: gold);
          line(canvas, [
            Offset(56, 38 + i * 7),
            Offset(67, 34 + i * 7),
          ], color: gold);
        }
        line(canvas, const [Offset(50, 33), Offset(51, 67)]);
      case TlStickerKind.grammar:
        shape(canvas, box(33, 24, 43, 47, 7), colors.infoSoft, depth: 5);
        shape(canvas, box(23, 32, 43, 43, 7), sand, depth: 4);
        line(canvas, const [Offset(32, 57), Offset(39, 42), Offset(46, 57)]);
        line(canvas, const [Offset(35, 52), Offset(43, 52)]);
        line(canvas, const [Offset(52, 45), Offset(52, 58), Offset(59, 58)]);
        shape(canvas, box(33, 64, 24, 4, 2), paper, depth: 1);
      case TlStickerKind.play:
        final p = Path()
          ..moveTo(32, 36)
          ..quadraticBezierTo(50, 40, 68, 36)
          ..quadraticBezierTo(75, 36, 79, 58)
          ..quadraticBezierTo(82, 76, 69, 70)
          ..lineTo(60, 60)
          ..lineTo(42, 60)
          ..lineTo(31, 70)
          ..quadraticBezierTo(20, 76, 23, 59)
          ..quadraticBezierTo(25, 39, 32, 36)
          ..close();
        shape(canvas, p, gold, depth: 6, side: TlPalette.muddyWater);
        shape(canvas, box(31, 44, 16, 6, 1), paper, depth: 1);
        shape(canvas, box(36, 39, 6, 16, 1), paper, depth: 1);
        dot(canvas, 65, 44, 3, paper);
        dot(canvas, 71, 52, 3, sand);
        line(canvas, const [Offset(49, 55), Offset(55, 55)]);
      case TlStickerKind.speak:
        final p = Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(22, 28, 55, 36),
              const Radius.circular(10),
            ),
          )
          ..moveTo(34, 62)
          ..lineTo(32, 75)
          ..lineTo(49, 63)
          ..close();
        shape(canvas, p, colors.infoSoft, depth: 5, side: gold);
        dot(canvas, 36, 46, 2.6, ink);
        dot(canvas, 49, 46, 2.6, ink);
        dot(canvas, 62, 46, 2.6, ink);
        shape(canvas, box(63, 18, 17, 13, 4), sand, depth: 2);
      case TlStickerKind.link:
        canvas.save();
        canvas.translate(51, 49);
        canvas.rotate(-.6);
        canvas.translate(-51, -49);
        shape(canvas, box(28, 33, 30, 20, 9), gold, depth: 4);
        shape(canvas, box(48, 45, 30, 20, 9), paper, depth: 4);
        line(canvas, const [Offset(43, 45), Offset(62, 54)], width: 4);
        canvas.restore();
      case TlStickerKind.file:
      case TlStickerKind.text:
        shape(
          canvas,
          poly(const [
            Offset(29, 23),
            Offset(60, 23),
            Offset(74, 37),
            Offset(74, 75),
            Offset(29, 75),
          ]),
          paper,
          depth: 5,
        );
        shape(
          canvas,
          poly(const [Offset(60, 23), Offset(60, 37), Offset(74, 37)]),
          sand,
          depth: 1,
        );
        for (var i = 0; i < 3; i++) {
          line(
            canvas,
            [Offset(38, 46 + i * 8), Offset(i == 2 ? 56 : 65, 46 + i * 8)],
            color: TlPalette.muddyWater,
            width: 2.8,
          );
        }
      case TlStickerKind.image:
        shape(canvas, box(23, 28, 55, 43, 5), paper, depth: 5);
        shape(canvas, box(28, 33, 45, 32, 2), sand);
        dot(canvas, 61, 41, 4, gold);
        shape(
          canvas,
          poly(const [
            Offset(29, 63),
            Offset(42, 44),
            Offset(54, 59),
            Offset(62, 51),
            Offset(72, 63),
          ]),
          colors.successSoft,
        );
      case TlStickerKind.celebrate:
        shape(
          canvas,
          poly(const [
            Offset(36, 61),
            Offset(33, 81),
            Offset(48, 73),
            Offset(57, 82),
            Offset(61, 59),
          ]),
          gold,
          depth: 2,
        );
        final medal = Path()..addOval(const Rect.fromLTWH(25, 22, 50, 50));
        shape(canvas, medal, sand, depth: 5);
        dot(canvas, 50, 47, 18, paper);
        line(canvas, const [
          Offset(39, 47),
          Offset(47, 55),
          Offset(62, 39),
        ], width: 3.5);
    }
    canvas.restore();
    // Secondary accent follows the action six frames later, then rests.
    final accent = _track(frame - 6, const [
      _Key(0, 0, Cubic(.75, 0, .25, 1)),
      _Key(10, 1.1, Cubic(.75, 0, .25, 1)),
      _Key(30, 1),
    ]);
    canvas.save();
    canvas.translate(81, 22);
    canvas.scale(accent);
    sparkle(canvas, 0, 0, 5);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StickerPainter old) =>
      old.kind != kind || old.colors != colors || old.frame != frame;
}

/// One foreground hero with supporting stickers. All actions stop after 3s.
class TlDiscoveryScene extends StatelessWidget {
  const TlDiscoveryScene({super.key, this.height = 190});
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 420.0);
          return Center(
            child: SizedBox(
              width: width,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: height * .12,
                    child: Transform.rotate(
                      angle: -.08,
                      child: Container(
                        width: width * .72,
                        height: height * .28,
                        decoration: BoxDecoration(
                          color: context.colors.primarySoft,
                          borderRadius: BorderRadius.circular(80),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .02,
                    top: height * .12,
                    child: TlSticker(
                      kind: TlStickerKind.image,
                      size: height * .65,
                      animate: false,
                    ),
                  ),
                  TlSticker(kind: TlStickerKind.book, size: height * 1.05),
                  Positioned(
                    right: width * .01,
                    bottom: 0,
                    child: TlSticker(
                      kind: TlStickerKind.speak,
                      size: height * .65,
                      animate: false,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}
