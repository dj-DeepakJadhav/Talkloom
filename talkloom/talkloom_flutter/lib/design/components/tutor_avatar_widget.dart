import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// The reactive emotional and conversational states of the Tutor Persona.
enum TutorAvatarState {
  listening,
  thinking,
  speaking,
  celebrating,
}

/// An interactive, state-driven visual tutor persona avatar.
///
/// Provides responsive non-verbal presence:
/// - **Listening**: Gentle breathing, occasional blinking, leaning in.
/// - **Thinking**: Soft upward gaze, thinking indicator orbit.
/// - **Speaking**: Dynamic viseme lip-movement driven by sine oscillation.
/// - **Celebrating**: Joyful smile, bounce, and radiant gold halo when the learner hits a target.
class TutorAvatarWidget extends StatefulWidget {
  const TutorAvatarWidget({
    super.key,
    required this.state,
    this.size = 110.0,
    this.personaName = 'Loom Tutor',
    this.personaRole = 'Pedagogical Partner',
  });

  final TutorAvatarState state;
  final double size;
  final String personaName;
  final String personaRole;

  @override
  State<TutorAvatarWidget> createState() => _TutorAvatarWidgetState();
}

class _TutorAvatarWidgetState extends State<TutorAvatarWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 1. Ambient Glow Halo
                _buildAmbientHalo(colors),

                // 2. Persona Avatar Core
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surfaceRaised,
                        colors.surface,
                      ],
                    ),
                    border: Border.all(
                      color: _getStateBorderColor(colors),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getStateBorderColor(colors).withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CustomPaint(
                      painter: _AvatarPainter(
                        animationValue: _anim.value,
                        state: widget.state,
                        colors: colors,
                      ),
                    ),
                  ),
                ),

                // 3. State Pill Badge
                Positioned(
                  bottom: 0,
                  child: _buildStateBadge(colors),
                ),
              ],
            ),
            const SizedBox(height: TlSpace.xs),
            Text(
              widget.personaName,
              style: context.type.bodyStrong.copyWith(color: colors.textPrimary),
            ),
            Text(
              widget.personaRole,
              style: context.type.caption.copyWith(color: colors.textMuted),
            ),
          ],
        );
      },
    );
  }

  Color _getStateBorderColor(TlColors colors) {
    switch (widget.state) {
      case TutorAvatarState.listening:
        return colors.primary;
      case TutorAvatarState.thinking:
        return colors.info;
      case TutorAvatarState.speaking:
        return colors.primary;
      case TutorAvatarState.celebrating:
        return const Color(0xFFFFB800); // Gold celebration
    }
  }

  Widget _buildAmbientHalo(TlColors colors) {
    double scale = 1.0;
    if (widget.state == TutorAvatarState.speaking) {
      scale = 1.0 + 0.08 * math.sin(_anim.value * 2 * math.pi * 3);
    } else if (widget.state == TutorAvatarState.celebrating) {
      scale = 1.0 + 0.15 * math.sin(_anim.value * 2 * math.pi * 2);
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size + 18,
        height: widget.size + 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _getStateBorderColor(colors).withValues(alpha: 0.12),
        ),
      ),
    );
  }

  Widget _buildStateBadge(TlColors colors) {
    String label;
    IconData icon;
    Color badgeColor;

    switch (widget.state) {
      case TutorAvatarState.listening:
        label = 'Listening';
        icon = Icons.hearing;
        badgeColor = colors.primary;
        break;
      case TutorAvatarState.thinking:
        label = 'Reasoning';
        icon = Icons.auto_awesome;
        badgeColor = colors.info;
        break;
      case TutorAvatarState.speaking:
        label = 'Speaking';
        icon = Icons.volume_up;
        badgeColor = colors.primary;
        break;
      case TutorAvatarState.celebrating:
        label = 'Bravo!';
        icon = Icons.star;
        badgeColor = const Color(0xFFFFB800);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom procedural 2D vector face painter for the tutor persona.
class _AvatarPainter extends CustomPainter {
  _AvatarPainter({
    required this.animationValue,
    required this.state,
    required this.colors,
  });

  final double animationValue;
  final TutorAvatarState state;
  final TlColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Head base skin tone
    final skinPaint = Paint()..color = const Color(0xFFFBE4D8);
    canvas.drawCircle(center, radius * 0.72, skinPaint);

    // Hair / Accent cap
    final hairPaint = Paint()..color = const Color(0xFF2C3E50);
    final hairPath = Path()
      ..addArc(
        Rect.fromCircle(center: center.translate(0, -radius * 0.12), radius: radius * 0.73),
        math.pi,
        math.pi,
      );
    canvas.drawPath(hairPath, hairPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1E272E);
    final eyeY = center.dy - radius * 0.05;
    final leftEyeX = center.dx - radius * 0.25;
    final rightEyeX = center.dx + radius * 0.25;

    // Eye blinking logic (every ~2.4s, quick blink)
    bool isBlink = (animationValue > 0.94 && animationValue < 0.98);
    if (state == TutorAvatarState.celebrating) {
      // Happy curved eyes: ^ ^
      final smileEyePaint = Paint()
        ..color = const Color(0xFF1E272E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(leftEyeX, eyeY), radius: 5),
        math.pi,
        math.pi,
        false,
        smileEyePaint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(rightEyeX, eyeY), radius: 5),
        math.pi,
        math.pi,
        false,
        smileEyePaint,
      );
    } else if (isBlink) {
      final blinkPaint = Paint()
        ..color = const Color(0xFF1E272E)
        ..strokeWidth = 2.0;
      canvas.drawLine(
        Offset(leftEyeX - 4, eyeY),
        Offset(leftEyeX + 4, eyeY),
        blinkPaint,
      );
      canvas.drawLine(
        Offset(rightEyeX - 4, eyeY),
        Offset(rightEyeX + 4, eyeY),
        blinkPaint,
      );
    } else {
      // Normal or thinking eyes
      double lookOffsetY = (state == TutorAvatarState.thinking) ? -3.0 : 0.0;
      canvas.drawCircle(Offset(leftEyeX, eyeY + lookOffsetY), 4.0, eyePaint);
      canvas.drawCircle(Offset(rightEyeX, eyeY + lookOffsetY), 4.0, eyePaint);

      // Eye catchlight sparkles
      final catchLight = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(leftEyeX - 1.2, eyeY - 1.2 + lookOffsetY), 1.2, catchLight);
      canvas.drawCircle(Offset(rightEyeX - 1.2, eyeY - 1.2 + lookOffsetY), 1.2, catchLight);
    }

    // Cheeks blushing
    final blushPaint = Paint()..color = const Color(0xFFFF7675).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(leftEyeX - 5, eyeY + 10), 5.5, blushPaint);
    canvas.drawCircle(Offset(rightEyeX + 5, eyeY + 10), 5.5, blushPaint);

    // Mouth / Viseme Animation
    final mouthPaint = Paint()
      ..color = const Color(0xFFD63031)
      ..style = PaintingStyle.fill;

    final mouthY = center.dy + radius * 0.28;

    switch (state) {
      case TutorAvatarState.speaking:
        // Oscillating open mouth (viseme simulation)
        double mouthOpen = 2.0 + 5.0 * (0.5 + 0.5 * math.sin(animationValue * 2 * math.pi * 5));
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, mouthY), width: 14, height: mouthOpen),
          mouthPaint,
        );
        break;
      case TutorAvatarState.celebrating:
        // Broad happy smile
        final smilePath = Path()
          ..moveTo(center.dx - 10, mouthY - 2)
          ..quadraticBezierTo(center.dx, mouthY + 8, center.dx + 10, mouthY - 2)
          ..close();
        canvas.drawPath(smilePath, mouthPaint);
        break;
      case TutorAvatarState.thinking:
        // Small focused mouth
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, mouthY), width: 6, height: 4),
          mouthPaint,
        );
        break;
      case TutorAvatarState.listening:
        // Soft encouraging smile line
        final smileStroke = Paint()
          ..color = const Color(0xFFD63031)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        final smilePath = Path()
          ..moveTo(center.dx - 7, mouthY)
          ..quadraticBezierTo(center.dx, mouthY + 4, center.dx + 7, mouthY);
        canvas.drawPath(smilePath, smileStroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.state != state;
  }
}
