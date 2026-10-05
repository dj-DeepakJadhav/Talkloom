import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme.dart';
import 'tl_button.dart';

/// Shown when a surface has no content yet. Every list must provide one.
class TlEmptyState extends StatelessWidget {
  const TlEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: TlSpace.xxl,
        horizontal: TlSpace.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: colors.textMuted),
          ),
          const SizedBox(height: TlSpace.md),
          Text(title, style: context.type.title, textAlign: TextAlign.center),
          const SizedBox(height: TlSpace.xs),
          Text(
            message,
            style: context.type.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: TlSpace.lg),
            TlButton(
              label: actionLabel!,
              onPressed: onAction,
              size: TlButtonSize.compact,
              isFullWidth: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown when an operation fails.
///
/// This exists because the previous client swallowed every exception, leaving
/// the user with a spinner that silently stopped. Failures must always be
/// visible and always offer a retry.
class TlErrorState extends StatelessWidget {
  const TlErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.isCompact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TlSpace.md),
      decoration: BoxDecoration(
        color: colors.dangerSoft,
        borderRadius: TlRadius.controlRadius,
        border: Border.all(color: colors.danger.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.triangleAlert, size: 18, color: colors.danger),
              const SizedBox(width: TlSpace.sm),
              Expanded(
                child: Text(
                  message,
                  style: context.type.bodySmall.copyWith(
                    color: colors.dangerText,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: TlSpace.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TlButton(
                label: 'Try again',
                onPressed: onRetry,
                tone: TlButtonTone.neutral,
                size: TlButtonSize.compact,
                isFullWidth: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer placeholder used while content loads, instead of a bare spinner.
class TlSkeleton extends StatefulWidget {
  const TlSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = TlRadius.sm,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<TlSkeleton> createState() => _TlSkeletonState();
}

class _TlSkeletonState extends State<TlSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Fade-and-rise entrance. Applied to list items with an increasing [index] to
/// stagger them.
class TlEntrance extends StatelessWidget {
  const TlEntrance({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: TlMotion.medium + TlMotion.stagger * index,
      curve: TlMotion.standard,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
