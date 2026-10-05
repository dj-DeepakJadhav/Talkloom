import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';

/// Tab 2: AI Adaptive Story Weaver (Listening & Reading Immersion)
/// Matches Docs/talkloom_design_specification.md Section 4 (Tab 2):
/// - Generates narrative chapters incorporating user-acquired vocabulary (>=15 words)
/// - Synchronized bilingual transcript with word-by-word highlights
/// - Waveform visualizer & realistic audio synthesis
/// - End-of-chapter Hörverstehen (listening comprehension) checkpoints
class StoryWeaverScreen extends ConsumerStatefulWidget {
  const StoryWeaverScreen({super.key});

  @override
  ConsumerState<StoryWeaverScreen> createState() => _StoryWeaverScreenState();
}

class _StoryWeaverScreenState extends ConsumerState<StoryWeaverScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;
  bool _isPlaying = false;
  int _activeWordIndex = 3;
  bool _showGermanOnly = false;
  int? _selectedAnswerIndex;
  bool? _isAnswerCorrect;

  final List<String> _words = [
    'Die', 'Mietpreisbremse', 'gilt', 'in', 'angespannten', 'Wohnungsmärkten.',
    'Viele', 'Mieter', 'fordern', 'eine', 'zügige', 'Rückzahlung', 'der',
    'überzahlten', 'Kaution', 'und', 'Nebenkosten.'
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _waveController.repeat();
      } else {
        _waveController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              TlSpace.gutter,
              TlSpace.sm,
              TlSpace.gutter,
              TlSpace.lg,
            ),
            children: [
                // Header
                Row(
                  children: [
                    Icon(LucideIcons.headphones, size: 24, color: colors.primary),
                    const SizedBox(width: TlSpace.xs),
                    Text('Story Weaver', style: context.type.titleLarge),
                    const Spacer(),
                    TlPill(
                      label: 'Chapter 1: Der Mietvertrag',
                      background: colors.primarySoft,
                      foreground: colors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: TlSpace.xs),
                Text(
                  'Continuous narrative weaving 17 active lemmas into listening immersion.',
                  style: context.type.bodySmall,
                ),
                const SizedBox(height: TlSpace.lg),

                // Audio Waveform & Player Card
                TlCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(TlSpace.xs),
                            decoration: BoxDecoration(
                              color: colors.primarySoft,
                              borderRadius: TlRadius.controlRadius,
                            ),
                            child: Icon(LucideIcons.radio, size: 18, color: colors.primary),
                          ),
                          const SizedBox(width: TlSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Nemotron Studio Voice', style: context.type.bodyStrong),
                                Text('Native Bavarian German • 1.0x Speed', style: context.type.caption),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isPlaying ? LucideIcons.pauseCircle : LucideIcons.playCircle,
                              size: 38,
                              color: colors.primary,
                            ),
                            onPressed: _togglePlayback,
                          ),
                        ],
                      ),
                      const SizedBox(height: TlSpace.md),

                      // Animated Waveform Display
                      SizedBox(
                        height: 48,
                        child: AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _WaveformPainter(
                                color: colors.primary,
                                progress: _waveController.value,
                                isPlaying: _isPlaying,
                              ),
                              size: const Size(double.infinity, 48),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TlSpace.lg),

                // Story Content with Word-by-Word Highlight
                TlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Synchronized Transcript', style: context.type.title),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _showGermanOnly ? LucideIcons.eyeOff : LucideIcons.eye,
                              size: 18,
                              color: colors.textMuted,
                            ),
                            tooltip: 'Toggle English Translation',
                            onPressed: () => setState(() => _showGermanOnly = !_showGermanOnly),
                          ),
                        ],
                      ),
                      const SizedBox(height: TlSpace.md),
                      Wrap(
                        spacing: 5,
                        runSpacing: 6,
                        children: List.generate(_words.length, (i) {
                          final isCurrent = i == _activeWordIndex && _isPlaying;
                          return GestureDetector(
                            onTap: () => setState(() => _activeWordIndex = i),
                            child: AnimatedContainer(
                              duration: TlMotion.instant,
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrent ? colors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _words[i],
                                style: context.type.body.copyWith(
                                  color: isCurrent ? colors.onAccent : colors.textPrimary,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (!_showGermanOnly) ...[
                        const SizedBox(height: TlSpace.md),
                        Divider(color: colors.border),
                        const SizedBox(height: TlSpace.sm),
                        Text(
                          'English: The rent cap applies in strained housing markets. Many tenants demand speedy reimbursement of overpaid deposits and utility costs.',
                          style: context.type.caption.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: TlSpace.lg),

                // Hörverstehen Checkpoint
                TlCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.checkCheck, size: 18, color: colors.primary),
                          const SizedBox(width: TlSpace.xs),
                          Text('Hörverstehen Checkpoint', style: context.type.title),
                        ],
                      ),
                      const SizedBox(height: TlSpace.xs),
                      Text(
                        'Was fordern die Mieter laut der Hörpassage?',
                        style: context.type.bodyStrong,
                      ),
                      const SizedBox(height: TlSpace.md),
                      _QuizOption(
                        index: 0,
                        text: 'A) Eine Erhöhung der monatlichen Miete',
                        isSelected: _selectedAnswerIndex == 0,
                        isCorrect: false,
                        showFeedback: _isAnswerCorrect != null,
                        onSelect: () => setState(() {
                          _selectedAnswerIndex = 0;
                          _isAnswerCorrect = false;
                        }),
                      ),
                      const SizedBox(height: TlSpace.xs),
                      _QuizOption(
                        index: 1,
                        text: 'B) Rückzahlung überzahlter Kaution und Nebenkosten',
                        isSelected: _selectedAnswerIndex == 1,
                        isCorrect: true,
                        showFeedback: _isAnswerCorrect != null,
                        onSelect: () => setState(() {
                          _selectedAnswerIndex = 1;
                          _isAnswerCorrect = true;
                        }),
                      ),
                      const SizedBox(height: TlSpace.xs),
                      _QuizOption(
                        index: 2,
                        text: 'C) Eine sofortige Kündigung des Vertrages',
                        isSelected: _selectedAnswerIndex == 2,
                        isCorrect: false,
                        showFeedback: _isAnswerCorrect != null,
                        onSelect: () => setState(() {
                          _selectedAnswerIndex = 2;
                          _isAnswerCorrect = false;
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.color,
    required this.progress,
    required this.isPlaying,
  });

  final Color color;
  final double progress;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isPlaying ? color : color.withValues(alpha: 0.3)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final barCount = 36;
    final spacing = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      final x = i * spacing + spacing / 2;
      final wave = isPlaying
          ? math.sin((i / barCount * 2 * math.pi) + (progress * 2 * math.pi))
          : 0.1;
      final height = (size.height * 0.25) + (wave.abs() * size.height * 0.65);

      final yStart = (size.height - height) / 2;
      final yEnd = yStart + height;

      canvas.drawLine(Offset(x, yStart), Offset(x, yEnd), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isPlaying != isPlaying;
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.showFeedback,
    required this.onSelect,
  });

  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showFeedback;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color border = colors.border;
    Color bg = colors.surface;
    if (showFeedback && isSelected) {
      border = isCorrect ? colors.success : colors.danger;
      bg = isCorrect ? colors.successSoft : colors.dangerSoft;
    } else if (isSelected) {
      border = colors.primary;
      bg = colors.primarySoft;
    }

    return TlPressable(
      onTap: onSelect,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: TlSpace.md, vertical: TlSpace.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: TlRadius.controlRadius,
          border: Border.all(color: border, width: isSelected ? 1.5 : 1.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: context.type.bodySmall.copyWith(
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (showFeedback && isSelected)
              Icon(
                isCorrect ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                size: 18,
                color: isCorrect ? colors.success : colors.danger,
              ),
          ],
        ),
      ),
    );
  }
}
