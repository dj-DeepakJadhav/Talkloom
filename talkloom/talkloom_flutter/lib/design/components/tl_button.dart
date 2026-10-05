import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

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

  bool _isPressed = false;

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

  void _setPressed(bool value) {
    if (!_isEnabled || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  void _handleTap() {
    if (!_isEnabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = _tones(colors);
    final height = widget.size == TlButtonSize.regular ? 54.0 : 42.0;
    final opacity = _isEnabled ? 1.0 : 0.45;

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.label,
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _handleTap,
          child: SizedBox(
            width: widget.isFullWidth ? double.infinity : null,
            height: height + _lip,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tone.lip,
                      borderRadius: TlRadius.controlRadius,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: TlMotion.instant,
                  curve: TlMotion.standard,
                  left: 0,
                  right: 0,
                  top: _isPressed ? _lip : 0,
                  height: height,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tone.face,
                      borderRadius: TlRadius.controlRadius,
                    ),
                    child: Center(child: _buildContent(context, tone.label)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
