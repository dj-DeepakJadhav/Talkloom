import 'package:flutter/material.dart';
import 'tokens.dart';

/// Semantic colour roles resolved per theme.
///
/// Widgets read `context.tl.colors.surface` — never a `isDark ? a : b` ternary
/// and never a raw hex. Adding a theme means adding one factory here.
@immutable
class TlColors extends ThemeExtension<TlColors> {
  const TlColors({
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceRaised,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onAccent,
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.primaryText,
    required this.success,
    required this.successPressed,
    required this.successSoft,
    required this.successText,
    required this.info,
    required this.infoPressed,
    required this.infoSoft,
    required this.infoText,
    required this.danger,
    required this.dangerPressed,
    required this.dangerSoft,
    required this.dangerText,
    required this.shadow,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color surfaceRaised;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  /// Text/icon colour that sits on a filled accent (primary, success, ...).
  final Color onAccent;

  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;

  /// Readable text colour on top of [primarySoft].
  final Color primaryText;

  final Color success;
  final Color successPressed;
  final Color successSoft;
  final Color successText;

  final Color info;
  final Color infoPressed;
  final Color infoSoft;
  final Color infoText;

  final Color danger;
  final Color dangerPressed;
  final Color dangerSoft;
  final Color dangerText;

  final Color shadow;

  static const light = TlColors(
    canvas: TlPalette.paper,
    surface: TlPalette.sand0,
    surfaceSunken: TlPalette.sand100,
    surfaceRaised: TlPalette.white,
    border: TlPalette.ashGrey,
    borderStrong: TlPalette.coolSteel,
    textPrimary: TlPalette.deepWalnut,
    textSecondary: TlPalette.ink600,
    textMuted: TlPalette.ink400,
    onAccent: TlPalette.white,
    primary: TlPalette.coral,
    primaryPressed: TlPalette.coralPressed,
    primarySoft: TlPalette.coralSoft,
    primaryText: TlPalette.coralPressed,
    success: TlPalette.dustyOlive,
    successPressed: TlPalette.sage600,
    successSoft: Color(0xFFECEFDF),
    successText: TlPalette.deepWalnut,
    info: TlPalette.skyReflection,
    infoPressed: TlPalette.coolSteel,
    infoSoft: Color(0xFFE8F2F8),
    infoText: TlPalette.deepWalnut,
    danger: TlPalette.berry400,
    dangerPressed: TlPalette.berry600,
    dangerSoft: TlPalette.berry50,
    dangerText: TlPalette.berry900,
    shadow: Color(0x18201B14),
  );

  static const dark = TlColors(
    canvas: TlPalette.obsidian,
    surface: TlPalette.surfaceElevated,
    surfaceSunken: TlPalette.espresso100,
    surfaceRaised: TlPalette.espresso200,
    border: TlPalette.borderSpecular,
    borderStrong: TlPalette.borderSpecular,
    textPrimary: TlPalette.textPrimaryDark,
    textSecondary: TlPalette.textMutedDark,
    textMuted: TlPalette.cream500,
    onAccent: TlPalette.obsidian,
    primary: TlPalette.coralLight,
    primaryPressed: TlPalette.coral,
    primarySoft: Color(0xFF38221D),
    primaryText: TlPalette.coralLight,
    success: TlPalette.emeraldActive,
    successPressed: Color(0xFF0D9467),
    successSoft: Color(0xFF0F2C23),
    successText: Color(0xFF6EE7B7),
    info: TlPalette.teal400,
    infoPressed: TlPalette.teal600,
    infoSoft: Color(0xFF152E33),
    infoText: TlPalette.teal100,
    danger: TlPalette.berry400,
    dangerPressed: TlPalette.berry600,
    dangerSoft: Color(0xFF331D21),
    dangerText: TlPalette.berry100,
    shadow: Color(0x99000000),
  );

  @override
  TlColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSunken,
    Color? surfaceRaised,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? onAccent,
    Color? primary,
    Color? primaryPressed,
    Color? primarySoft,
    Color? primaryText,
    Color? success,
    Color? successPressed,
    Color? successSoft,
    Color? successText,
    Color? info,
    Color? infoPressed,
    Color? infoSoft,
    Color? infoText,
    Color? danger,
    Color? dangerPressed,
    Color? dangerSoft,
    Color? dangerText,
    Color? shadow,
  }) {
    return TlColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      onAccent: onAccent ?? this.onAccent,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryText: primaryText ?? this.primaryText,
      success: success ?? this.success,
      successPressed: successPressed ?? this.successPressed,
      successSoft: successSoft ?? this.successSoft,
      successText: successText ?? this.successText,
      info: info ?? this.info,
      infoPressed: infoPressed ?? this.infoPressed,
      infoSoft: infoSoft ?? this.infoSoft,
      infoText: infoText ?? this.infoText,
      danger: danger ?? this.danger,
      dangerPressed: dangerPressed ?? this.dangerPressed,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      dangerText: dangerText ?? this.dangerText,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  TlColors lerp(ThemeExtension<TlColors>? other, double t) {
    if (other is! TlColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return TlColors(
      canvas: c(canvas, other.canvas),
      surface: c(surface, other.surface),
      surfaceSunken: c(surfaceSunken, other.surfaceSunken),
      surfaceRaised: c(surfaceRaised, other.surfaceRaised),
      border: c(border, other.border),
      borderStrong: c(borderStrong, other.borderStrong),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textMuted: c(textMuted, other.textMuted),
      onAccent: c(onAccent, other.onAccent),
      primary: c(primary, other.primary),
      primaryPressed: c(primaryPressed, other.primaryPressed),
      primarySoft: c(primarySoft, other.primarySoft),
      primaryText: c(primaryText, other.primaryText),
      success: c(success, other.success),
      successPressed: c(successPressed, other.successPressed),
      successSoft: c(successSoft, other.successSoft),
      successText: c(successText, other.successText),
      info: c(info, other.info),
      infoPressed: c(infoPressed, other.infoPressed),
      infoSoft: c(infoSoft, other.infoSoft),
      infoText: c(infoText, other.infoText),
      danger: c(danger, other.danger),
      dangerPressed: c(dangerPressed, other.dangerPressed),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      dangerText: c(dangerText, other.dangerText),
      shadow: c(shadow, other.shadow),
    );
  }
}
