import 'package:flutter/material.dart';
import 'theme.dart';

/// The two woven loops echo Talkloom's double “o” and a conversation thread.
/// One crossing passes over and the other under; the tail makes it a dialogue.
class TalkloomMark extends StatelessWidget {
  const TalkloomMark({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: TalkloomMarkPainter(
          ink: context.colors.textPrimary,
          thread: context.colors.success,
          background: context.colors.canvas,
        ),
      ),
    ),
  );
}

class TalkloomMarkPainter extends CustomPainter {
  const TalkloomMarkPainter({
    required this.ink,
    required this.thread,
    required this.background,
  });
  final Color ink;
  final Color thread;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024, size.height / 1024);
    final tail = Path()
      ..moveTo(274, 552)
      ..lineTo(242, 770)
      ..lineTo(426, 612)
      ..close();
    canvas.drawPath(tail, Paint()..color = ink);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    const left = Rect.fromLTWH(216, 264, 352, 352);
    const right = Rect.fromLTWH(456, 264, 352, 352);
    canvas.drawOval(left, stroke(ink, 80));
    canvas.drawOval(right, stroke(thread, 80));
    // The lower crossing belongs to the first loop; the upper to the second.
    canvas.drawArc(
      left,
      .70,
      .25,
      false,
      stroke(background, 116)..strokeCap = StrokeCap.butt,
    );
    canvas.drawArc(left, .52, .61, false, stroke(ink, 80));
    canvas.restore();
  }

  @override
  bool shouldRepaint(TalkloomMarkPainter old) =>
      old.ink != ink || old.thread != thread || old.background != background;
}

class TalkloomWordmark extends StatelessWidget {
  const TalkloomWordmark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Talkloom',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TalkloomMark(size: 34),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'talk', style: context.type.wordmarkLead),
                TextSpan(text: 'loom', style: context.type.wordmarkTail),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
