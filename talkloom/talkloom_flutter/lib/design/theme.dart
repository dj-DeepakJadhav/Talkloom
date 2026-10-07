import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'colors.dart';
import 'metrics.dart';
import 'typography.dart';

export 'colors.dart';
export 'metrics.dart';
export 'tokens.dart';
export 'typography.dart';

/// Ambient access to the design system.
///
/// Usage: `context.colors.surface`, `context.type.body`.
extension TlThemeAccess on BuildContext {
  TlColors get colors => Theme.of(this).extension<TlColors>()!;
  TlTypography get type => Theme.of(this).extension<TlTypography>()!;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

ThemeData buildTalkloomTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colors = isDark ? TlColors.dark : TlColors.light;
  final type = TlTypography.resolve(colors.textPrimary, colors.textSecondary);

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    brightness: brightness,
    scaffoldBackgroundColor: colors.canvas,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onAccent,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.danger,
    ),
    extensions: <ThemeExtension<dynamic>>[colors, type],
    textTheme: TextTheme(
      displaySmall: type.display,
      headlineMedium: type.headline,
      titleLarge: type.titleLarge,
      titleMedium: type.title,
      bodyLarge: type.body,
      bodyMedium: type.bodySmall,
      labelLarge: type.label,
      labelSmall: type.caption,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: type.titleLarge,
      iconTheme: IconThemeData(color: colors.textPrimary),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: colors.textPrimary,
      contentTextStyle: type.bodySmall.copyWith(color: colors.canvas),
      shape: const RoundedRectangleBorder(borderRadius: TlRadius.controlRadius),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceSunken,
      hintStyle: type.body.copyWith(color: colors.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: TlSpace.md,
        vertical: TlSpace.md,
      ),
      border: OutlineInputBorder(
        borderRadius: TlRadius.controlRadius,
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: TlRadius.controlRadius,
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: TlRadius.controlRadius,
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: TlRadius.controlRadius,
        borderSide: BorderSide(color: colors.danger),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      },
    ),
  );
}
