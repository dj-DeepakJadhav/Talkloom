import 'package:flutter/material.dart';

/// A short paper-card entrance; reduced motion goes directly to the final pose.
class TlArrival extends StatelessWidget {
  const TlArrival({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: Transform.scale(scale: .96 + .04 * value, child: child),
        ),
      ),
    );
  }
}
