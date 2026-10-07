import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../design/theme.dart';

enum VoiceOrbState {
  idle,
  listening,
  thinking,
  speaking,
}

/// A reactive fluid voice orb inspired by Apple Intelligence and Siri.
///
/// Features:
/// - Multi-layer harmonic sine deformation
/// - Fluid mesh gradients blending iridescent brass gold, electric cyan, violet, and deep obsidian
/// - Dynamic amplitude and speed modulation based on conversational state
/// - Ambient bloom glow and glass refraction rim
class FluidVoiceOrb extends StatefulWidget {
  const FluidVoiceOrb({
    super.key,
    required this.state,
    this.size = 220.0,
    this.soundLevel = 0.5,
  });

  final VoiceOrbState state;
  final double size;
  final double soundLevel; // 0.0 - 1.0 (microphone intensity)

  @override
  State<FluidVoiceOrb> createState() => _FluidVoiceOrbState();
}

class _FluidVoiceOrbState extends State<FluidVoiceOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        // Dynamic speed & deform based on state
        final double speedMultiplier = switch (widget.state) {
          VoiceOrbState.idle => 0.5,
          VoiceOrbState.listening => 1.8,
          VoiceOrbState.thinking => 2.5,
          VoiceOrbState.speaking => 1.6,
        };

        final double amplitude = switch (widget.state) {
          VoiceOrbState.idle => 0.04,
          VoiceOrbState.listening => 0.12 + (widget.soundLevel * 0.15),
          VoiceOrbState.thinking => 0.08,
          VoiceOrbState.speaking =>
            0.18 + (math.sin(progress * math.pi * 12).abs() * 0.14),
        };

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ambient Glow Aura
              Container(
                width: widget.size * 0.95,
                height: widget.size * 0.95,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      switch (widget.state) {
                        VoiceOrbState.idle => TlPalette.brassGold.withValues(
                          alpha: 0.15,
                        ),
                        VoiceOrbState.listening => const Color(
                          0xFF00E5FF,
                        ).withValues(alpha: 0.28),
                        VoiceOrbState.thinking => const Color(
                          0xFFA855F7,
                        ).withValues(alpha: 0.32),
                        VoiceOrbState.speaking =>
                          TlPalette.brassGoldLight.withValues(alpha: 0.35),
                      },
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.9],
                  ),
                ),
              ),

              // Morphing Fluid Blob Canvas
              CustomPaint(
                size: Size(widget.size * 0.85, widget.size * 0.85),
                painter: _FluidBlobPainter(
                  progress: (progress * speedMultiplier) % 1.0,
                  amplitude: amplitude,
                  state: widget.state,
                ),
              ),

              // Central Inner Glass Highlight
              Container(
                width: widget.size * 0.35,
                height: widget.size * 0.35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    colors: [
                      Colors.white.withValues(alpha: 0.45),
                      Colors.white.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FluidBlobPainter extends CustomPainter {
  _FluidBlobPainter({
    required this.progress,
    required this.amplitude,
    required this.state,
  });

  final double progress;
  final double amplitude;
  final VoiceOrbState state;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2.3;
    final path = Path();

    const int points = 90;
    final double angleStep = (math.pi * 2) / points;

    // Harmonic wave parameters
    final double t = progress * math.pi * 2;

    for (int i = 0; i <= points; i++) {
      final double theta = i * angleStep;

      // 3 overlapping frequencies for organic deformation
      final double wave1 = math.sin(theta * 3 + t * 2);
      final double wave2 = math.cos(theta * 2 - t * 3);
      final double wave3 = math.sin(theta * 5 + t);

      final double combinedWave = (wave1 * 0.5 + wave2 * 0.3 + wave3 * 0.2);
      final double r = baseRadius * (1.0 + amplitude * combinedWave);

      final double x = center.dx + r * math.cos(theta);
      final double y = center.dy + r * math.sin(theta);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fluid Mesh Gradient Colors
    final List<Color> gradientColors = switch (state) {
      VoiceOrbState.idle => [
        const Color(0xFFD4AF37), // Soft brass
        const Color(0xFF996515), // Deep gold
        const Color(0xFF1E1B18), // Obsidian
        const Color(0xFFE5C158), // Light gold
      ],
      VoiceOrbState.listening => [
        const Color(0xFF00E5FF), // Electric cyan
        const Color(0xFF3B82F6), // Azure blue
        const Color(0xFF8B5CF6), // Royal violet
        const Color(0xFF06B6D4), // Teal
      ],
      VoiceOrbState.thinking => [
        const Color(0xFFA855F7), // Magenta purple
        const Color(0xFFEC4899), // Pink
        const Color(0xFF6366F1), // Indigo
        const Color(0xFF8B5CF6), // Violet
      ],
      VoiceOrbState.speaking => [
        const Color(0xFFFFD700), // Brilliant gold
        const Color(0xFFFF8A00), // Amber flame
        const Color(0xFF9333EA), // Purple accent
        const Color(0xFFFFC000), // Warm brass
      ],
    };

    final paint = Paint()
      ..shader = SweepGradient(
        center: FractionalOffset.center,
        startAngle: 0.0,
        endAngle: math.pi * 2,
        colors: gradientColors,
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius))
      ..style = PaintingStyle.fill;

    // Outer subtle shadow
    canvas.drawShadow(
      path,
      gradientColors.first.withValues(alpha: 0.4),
      16,
      true,
    );
    canvas.drawPath(path, paint);

    // Inner Specular Rim Glow
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.1),
          gradientColors.first.withValues(alpha: 0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: baseRadius));

    canvas.drawPath(path, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _FluidBlobPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.amplitude != amplitude ||
        oldDelegate.state != state;
  }
}
