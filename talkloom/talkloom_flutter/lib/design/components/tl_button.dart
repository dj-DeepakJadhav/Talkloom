import 'package:flutter/material.dart';
import '../theme.dart';
import 'tl_surface.dart';

enum TlButtonTone { primary, success, info, neutral }

enum TlButtonSize { regular, compact }

/// The application's only button.
///
/// Presses translate the face down onto a solid 3px lip and fire a haptic, so
/// every action has a physical response. Disabled and busy states are handled
/// here rather than by each caller.
class TlButton extends StatefulWidget {
  const TlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = TlButtonTone.primary,
    this.size = TlButtonSize.regular,
    this.isBusy = false,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final TlButtonTone tone;
  final TlButtonSize size;
  final bool isBusy;
  final bool isFullWidth;

  @override
  State<TlButton> createState() => _TlButtonState();
}

class _TlButtonState extends State<TlButton> {
  static const double _lip = 3;

  bool get _isEnabled => widget.onPressed != null && !widget.isBusy;

  ({Color face, Color lip, Color label}) _tones(TlColors c) {
    return switch (widget.tone) {
      TlButtonTone.primary => (
        face: c.primary,
        lip: c.primaryPressed,
        label: c.onAccent,
      ),
      TlButtonTone.success => (
        face: c.success,
        lip: c.successPressed,
        label: c.onAccent,
      ),
      TlButtonTone.info => (
        face: c.info,
        lip: c.infoPressed,
        label: c.onAccent,
      ),
      TlButtonTone.neutral => (
        face: c.surfaceSunken,
        lip: c.borderStrong,
        label: c.textPrimary,
      ),
    };
  }

  void _handleTap() {
    if (!_isEnabled) return;
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = _tones(colors);
    final height = widget.size == TlButtonSize.regular ? 54.0 : 44.0;
    final opacity = _isEnabled ? 1.0 : 0.45;

    // The face is a minimum height, not a fixed one, so a long label or a
    // larger text scale grows the button instead of clipping the label.
    final face = Opacity(
      opacity: opacity,
      child: SizedBox(
        width: widget.isFullWidth ? double.infinity : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tone.lip,
            borderRadius: TlRadius.controlRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: _lip),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tone.face,
                  borderRadius: TlRadius.controlRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TlSpace.md,
                    vertical: TlSpace.xs,
                  ),
                  child: Center(
                    widthFactor: widget.isFullWidth ? null : 1,
                    child: _buildContent(context, tone.label),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Enabled buttons go through TlPressable for keyboard focus/activation and
    // semantics; disabled ones are exposed as disabled and not focusable.
    if (!_isEnabled) {
      return Semantics(
        button: true,
        enabled: false,
        label: widget.label,
        child: ExcludeSemantics(child: face),
      );
    }
    return TlPressable(
      semanticLabel: widget.label,
      scale: 0.98,
      onTap: _handleTap,
      child: face,
    );
  }

  Widget _buildContent(BuildContext context, Color labelColor) {
    if (widget.isBusy) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2.4, color: labelColor),
      );
    }

    final label = Text(
      widget.label,
      textAlign: TextAlign.center,
      style: context.type.buttonLabel.copyWith(color: labelColor),
    );

    if (widget.icon == null) return label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon, color: labelColor, size: 19),
        const SizedBox(width: TlSpace.xs),
        Flexible(child: label),
      ],
    );
  }
}
