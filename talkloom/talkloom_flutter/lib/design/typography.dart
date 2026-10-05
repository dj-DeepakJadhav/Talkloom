import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The complete type scale. Nothing outside this file may declare a `fontSize`.
///
/// Sizes were raised from the 11–13px demo scale: body is now 16px, matching
/// what consumer apps use. Small text is a deliberate, rare choice, not a
/// default.
@immutable
class TlTypography extends ThemeExtension<TlTypography> {
  const TlTypography({
    required this.display,
    required this.headline,
    required this.titleLarge,
    required this.title,
    required this.body,
    required this.bodyStrong,
    required this.bodySmall,
    required this.label,
    required this.labelSmall,
    required this.buttonLabel,
    required this.caption,
    required this.numeric,
  });

  /// Onboarding and hero moments only.
  final TextStyle display;

  /// Screen titles.
  final TextStyle headline;

  /// Card titles.
  final TextStyle titleLarge;

  /// Row and section titles.
  final TextStyle title;

  /// Default reading size.
  final TextStyle body;
  final TextStyle bodyStrong;

  /// Secondary reading size — supporting copy, never primary content.
  final TextStyle bodySmall;

  /// Tabs and pills.
  final TextStyle label;

  /// Compact labels inside chips and toolbar controls.
  final TextStyle labelSmall;

  /// Button faces.
  final TextStyle buttonLabel;

  /// Metadata. The smallest permitted size.
  final TextStyle caption;

  /// Tabular figures for counters and stats.
  final TextStyle numeric;

  static TlTypography resolve(Color primary, Color secondary) {
    TextStyle jakarta(
      double size,
      FontWeight weight,
      Color color, {
      double? spacing,
      double height = 1.3,
    }) => GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
      color: color,
    );

    TextStyle inter(
      double size,
      FontWeight weight,
      Color color, {
      double height = 1.5,
    }) => GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );

    return TlTypography(
      display: jakarta(
        32,
        FontWeight.w800,
        primary,
        spacing: -0.8,
        height: 1.15,
      ),
      headline: jakarta(
        24,
        FontWeight.w800,
        primary,
        spacing: -0.5,
        height: 1.2,
      ),
      titleLarge: jakarta(20, FontWeight.w700, primary, spacing: -0.3),
      title: jakarta(17, FontWeight.w700, primary, spacing: -0.2),
      body: inter(16, FontWeight.w400, secondary),
      bodyStrong: inter(16, FontWeight.w600, primary),
      bodySmall: inter(15, FontWeight.w400, secondary),
      label: jakarta(14, FontWeight.w700, primary, spacing: 0.1, height: 1.2),
      labelSmall: jakarta(
        13,
        FontWeight.w700,
        primary,
        spacing: 0.1,
        height: 1.2,
      ),
      buttonLabel: jakarta(
        16,
        FontWeight.w700,
        primary,
        spacing: 0.1,
        height: 1.2,
      ),
      caption: inter(12, FontWeight.w500, secondary, height: 1.35),
      numeric: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  @override
  TlTypography copyWith({
    TextStyle? display,
    TextStyle? headline,
    TextStyle? titleLarge,
    TextStyle? title,
    TextStyle? body,
    TextStyle? bodyStrong,
    TextStyle? bodySmall,
    TextStyle? label,
    TextStyle? labelSmall,
    TextStyle? buttonLabel,
    TextStyle? caption,
    TextStyle? numeric,
  }) {
    return TlTypography(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      titleLarge: titleLarge ?? this.titleLarge,
      title: title ?? this.title,
      body: body ?? this.body,
      bodyStrong: bodyStrong ?? this.bodyStrong,
      bodySmall: bodySmall ?? this.bodySmall,
      label: label ?? this.label,
      labelSmall: labelSmall ?? this.labelSmall,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      caption: caption ?? this.caption,
      numeric: numeric ?? this.numeric,
    );
  }

  @override
  TlTypography lerp(ThemeExtension<TlTypography>? other, double t) {
    if (other is! TlTypography) return this;
    return TlTypography(
      display: TextStyle.lerp(display, other.display, t)!,
      headline: TextStyle.lerp(headline, other.headline, t)!,
      titleLarge: TextStyle.lerp(titleLarge, other.titleLarge, t)!,
      title: TextStyle.lerp(title, other.title, t)!,
      body: TextStyle.lerp(body, other.body, t)!,
      bodyStrong: TextStyle.lerp(bodyStrong, other.bodyStrong, t)!,
      bodySmall: TextStyle.lerp(bodySmall, other.bodySmall, t)!,
      label: TextStyle.lerp(label, other.label, t)!,
      labelSmall: TextStyle.lerp(labelSmall, other.labelSmall, t)!,
      buttonLabel: TextStyle.lerp(buttonLabel, other.buttonLabel, t)!,
      caption: TextStyle.lerp(caption, other.caption, t)!,
      numeric: TextStyle.lerp(numeric, other.numeric, t)!,
    );
  }
}
