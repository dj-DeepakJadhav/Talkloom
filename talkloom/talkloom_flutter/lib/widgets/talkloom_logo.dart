import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// The Talkloom Custom Brandmark Logo:
/// Represents interlocking speech loops ("Talking" woven together in a "Loom").
/// Two organic interlocking rings forming an infinite conversational thread.
class TalkloomLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color accentColor;

  const TalkloomLogo({
    super.key,
    this.size = 36.0,
    this.primaryColor = TlPalette.brassGold,
    this.accentColor = TlPalette.emeraldActive,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TalkloomLogoPainter(
          primaryColor: primaryColor,
          accentColor: accentColor,
        ),
      ),
    );
  }
}

class _TalkloomLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color accentColor;

  _TalkloomLogoPainter({
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;

    // Warm rounded tile backing
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.32),
    );
    final bgPaint = Paint()..color = primaryColor;
    canvas.drawRRect(rrect, bgPaint);

    // 3D lip at bottom of tile
    final lipPaint = Paint()..color = TlPalette.apricot600;
    final lipRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.88, size.width, size.height * 0.12),
      Radius.circular(size.width * 0.1),
    );
    canvas.drawRRect(lipRect, lipPaint);

    // The Weaving Speech Loops (White iconographic monogram inside)
    final loopPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Left speech wave curve
    path.moveTo(size.width * 0.30, size.height * 0.60);
    path.cubicTo(
      size.width * 0.15,
      size.height * 0.32,
      size.width * 0.45,
      size.height * 0.22,
      size.width * 0.50,
      size.height * 0.42,
    );
    // Interlocking right speech wave curve (the Loom weave)
    path.cubicTo(
      size.width * 0.55,
      size.height * 0.62,
      size.width * 0.85,
      size.height * 0.52,
      size.width * 0.70,
      size.height * 0.28,
    );

    canvas.drawPath(path, loopPaint);

    // Little conversational accent dot
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.65),
      strokeWidth * 0.6,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TalkloomLogoPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}
