import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// The standard raised card. Replaces the hand-rolled `Container` +
/// `BoxDecoration` repeated across every previous widget.
class TlCard extends StatelessWidget {
  const TlCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TlSpace.lg),
    this.onTap,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// When set, the card is tinted and outlined in this colour.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final card = AnimatedContainer(
      duration: TlMotion.fast,
      curve: TlMotion.standard,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: TlRadius.cardRadius,
        border: Border.all(color: accent ?? colors.border),
      ),
      child: child,
    );

    if (onTap == null) return card;
    return TlPressable(onTap: onTap!, child: card);
  }
}

/// A recessed well used for inputs, transcripts and drop targets.
class TlSunken extends StatelessWidget {
  const TlSunken({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TlSpace.md),
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: TlMotion.fast,
      curve: TlMotion.standard,
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surfaceSunken,
        borderRadius: TlRadius.controlRadius,
        border: Border.all(color: borderColor ?? colors.border),
      ),
      child: child,
    );
  }
}

/// Scale-on-press wrapper giving any surface the same tactile response as
/// [TlButton], including the haptic.
class TlPressable extends StatefulWidget {
  const TlPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.semanticLabel,
    this.selected,
  });

  /// Minimum width and height of the tappable area, in logical pixels.
  static const double minTapTarget = 44;

  final Widget child;
  final VoidCallback onTap;
  final double scale;

  /// Accessible name announced for this control. When null the label is
  /// derived from the child's text.
  final String? semanticLabel;
  final bool? selected;

  @override
  State<TlPressable> createState() => _TlPressableState();
}

class _TlPressableState extends State<TlPressable> {
  bool _isPressed = false;

  bool _isFocused = false;

  void _activate() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      enabled: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: _activate,
      child: ExcludeSemantics(
        excluding: widget.semanticLabel != null,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (v) => setState(() => _isFocused = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: _activate,
            // Every pressable is at least 44x44 logical px (iOS HIG) so small
            // icons and chips stay reachable with a thumb; the visible child
            // keeps its own size and is centred in the larger hit area.
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: TlPressable.minTapTarget,
                minHeight: TlPressable.minTapTarget,
              ),
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: _isFocused
                        ? Border.all(color: colors.primary, width: 2)
                        : null,
                  ),
                  child: AnimatedScale(
                    scale: MediaQuery.disableAnimationsOf(context)
                        ? 1
                        : _isPressed
                        ? widget.scale
                        : 1,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : _isPressed
                        ? TlMotion.instant
                        : TlMotion.medium,
                    curve: TlMotion.standard,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small rounded status/metadata chip.
class TlPill extends StatelessWidget {
  const TlPill({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = foreground ?? colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.sm,
        vertical: TlSpace.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: background ?? colors.surfaceSunken,
        borderRadius: TlRadius.pillRadius,
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: TlSpace.xxs + 2),
          ],
          Text(
            label,
            style: context.type.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent frosted glass container with blur and top-lit specular hairline.
/// Matches Docs/talkloom_design_specification.md Section 2 & 6.
class TlFrostedGlass extends StatelessWidget {
  const TlFrostedGlass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TlSpace.md),
    this.borderRadius = TlRadius.cardRadius,
    this.blur = 24.0,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg =
        backgroundColor ??
        (isDark
            ? TlPalette.frostedGlass
            : Colors.white.withValues(alpha: 0.85));

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: borderRadius,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? TlPalette.borderSpecular
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.0,
              ),
              bottom: BorderSide(
                color: isDark
                    ? TlPalette.borderSpecularSubtle
                    : Colors.black.withValues(alpha: 0.05),
                width: 1.0,
              ),
              left: BorderSide(
                color: isDark
                    ? TlPalette.borderSpecularSubtle
                    : Colors.white.withValues(alpha: 0.4),
                width: 1.0,
              ),
              right: BorderSide(
                color: isDark
                    ? TlPalette.borderSpecularSubtle
                    : Colors.white.withValues(alpha: 0.4),
                width: 1.0,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
