import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../../design/theme.dart';
import '../../design/app_icons.dart';

/// Matches the tutor micro-syntax for unlearned vocabulary:
///
/// `[[new:word:meaning]]` or `[[new:word]]`.
final RegExp vocabPillPattern = RegExp(r'\[\[new:([^:|\]]+)(?::([^\]]+))?\]\]');

/// Strips the `[[new:word:meaning]]` micro-syntax down to the plain word.
///
/// Use for spoken output (TTS) so the markup is never read aloud.
String stripVocabMarkup(String raw) =>
    raw.replaceAllMapped(vocabPillPattern, (match) => match.group(1)!);

/// Renders tutor markdown with tappable vocabulary pills.
///
/// The `[[new:word:meaning]]` micro-syntax becomes a pill with the existing
/// Tooltip meaning behavior; everything else falls back to normal markdown.
class TutorMarkdown extends StatelessWidget {
  const TutorMarkdown(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base =
        style ??
        context.type.body.copyWith(
          color: colors.textPrimary,
          fontSize: 14,
          height: 1.35,
        );
    return GptMarkdown(
      text,
      style: base,
      textAlign: textAlign,
      inlinePatterns: [
        InlinePattern(
          pattern: vocabPillPattern,
          builder: (context, match, style) {
            final word = (match.group(1) ?? '').trim();
            final meaning = (match.group(2) ?? '').trim();
            final colors = context.colors;
            final type = context.type;
            return WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Tooltip(
                message: meaning.isNotEmpty
                    ? 'New: $meaning'
                    : 'New vocabulary',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: TlRadius.controlRadius,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: word,
                          style: type.bodyStrong.copyWith(
                            color: colors.primary,
                            fontSize: 13,
                          ),
                        ),
                        if (meaning.isNotEmpty)
                          TextSpan(
                            text: ' ($meaning)',
                            style: type.caption.copyWith(
                              color: colors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Shared chat bubble: avatar row, max-width bubble, per-turn replay slot
/// ([replayButton]) and typing-indicator slot ([footer]).
///
/// Set [showAvatar] for the labelled avatar-row layout (speak screen) or
/// leave it false for the plain aligned-bubble layout (arena, modal).
class ChatMessageView extends StatelessWidget {
  const ChatMessageView({
    super.key,
    required this.isLearner,
    this.label,
    this.showAvatar = false,
    this.headerExtra,
    required this.content,
    this.replayButton,
    this.footer,
    this.maxWidthFactor = 0.78,
    this.bubbleColor,
    this.bubbleBorder,
    this.verticalMargin = 5,
  });

  final bool isLearner;
  final String? label;
  final bool showAvatar;
  final Widget? headerExtra;
  final Widget content;
  final Widget? replayButton;
  final Widget? footer;
  final double maxWidthFactor;
  final Color? bubbleColor;
  final Border? bubbleBorder;
  final double verticalMargin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (showAvatar) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: isLearner
                  ? colors.primarySoft
                  : colors.surfaceRaised,
              child: Icon(
                isLearner ? AppIcons.userRound : AppIcons.messagesSquare,
                size: 18,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null) Text(label!, style: context.type.caption),
                  ...[headerExtra].whereType<Widget>(),
                  if (label != null || headerExtra != null)
                    const SizedBox(height: 5),
                  content,
                  ...[replayButton, footer].whereType<Widget>(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isLearner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * maxWidthFactor,
        ),
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor ?? (isLearner ? colors.primary : colors.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isLearner ? 16 : 4),
            bottomRight: Radius.circular(isLearner ? 4 : 16),
          ),
          border:
              bubbleBorder ??
              (isLearner
                  ? null
                  : Border.all(color: colors.border.withValues(alpha: 0.8))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            ...[replayButton, footer].whereType<Widget>(),
          ],
        ),
      ),
    );
  }
}
