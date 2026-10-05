import 'package:flutter/material.dart';

/// Spacing, radius and layout constants on a 4px grid.
abstract final class TlSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;

  /// Horizontal page gutter.
  static const double gutter = 20;

  /// Mobile-shaped column width on wide screens.
  static const double maxContentWidth = 480;
}

/// Sizes for non-text glyphs (flag emoji) that still need an explicit size.
abstract final class TlGlyph {
  static const double sm = 17;
  static const double md = 24;
  static const double lg = 26;
}

abstract final class TlRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(md),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}

/// Single source of truth for motion. Every animation in the app uses one of
/// these durations and curves so timing feels coherent rather than arbitrary.
abstract final class TlMotion {
  /// Press feedback and colour changes.
  static const Duration instant = Duration(milliseconds: 90);

  /// Standard element transitions.
  static const Duration fast = Duration(milliseconds: 180);

  /// Page and card transitions.
  static const Duration medium = Duration(milliseconds: 280);

  /// Celebratory or attention-drawing moments.
  static const Duration slow = Duration(milliseconds: 460);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve exit = Curves.easeInCubic;

  /// Per-item delay for staggered list entrances.
  static const Duration stagger = Duration(milliseconds: 55);
}
