import 'package:flutter/material.dart';
import '../design/theme.dart';

/// Keeps the phone-first UI at a readable width on tablets, desktop browsers
/// and landscape phones instead of stretching it edge to edge.
///
/// Wrap the navigator with this (`MaterialApp.builder`). The app bar,
/// navigation bar, sheets and snackbars all live inside the capped column, and
/// the [MediaQuery] seen by descendants reports the capped width so
/// width-dependent layout stays correct. Side insets (display cutouts) that
/// fall inside the empty gutters are not applied twice.
class TlAppViewport extends StatelessWidget {
  const TlAppViewport({
    super.key,
    required this.child,
    this.maxWidth = maxAppWidth,
  });

  /// Widest the app column is allowed to become. Phone-width (480) so the
  /// web build renders the same mobile view, centered, instead of a
  /// stretched desktop layout.
  static const double maxAppWidth = 480;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    if (width <= maxWidth) return child;

    final gutter = (width - maxWidth) / 2;
    EdgeInsets trim(EdgeInsets insets) => insets.copyWith(
      left: (insets.left - gutter).clamp(0, double.infinity),
      right: (insets.right - gutter).clamp(0, double.infinity),
    );

    return ColoredBox(
      color: context.colors.canvas,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(
            data: media.copyWith(
              size: Size(maxWidth, media.size.height),
              padding: trim(media.padding),
              viewPadding: trim(media.viewPadding),
              viewInsets: trim(media.viewInsets),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
