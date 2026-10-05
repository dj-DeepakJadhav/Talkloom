import 'package:flutter/material.dart';

/// Raw palette. These are the only literal colours in the application.
/// Nothing outside this file may declare a `Color(0x...)`.
///
/// "Organic Warmth" — warm sand canvas, apricot accent, eucalyptus growth.
/// Calibrated for long reading and speaking sessions in both themes.
abstract final class TlPalette {
  // Apricot — primary action
  static const apricot50 = Color(0xFFFFF7ED);
  static const apricot100 = Color(0xFFFDEBD2);
  static const apricot400 = Color(0xFFF39C38);
  static const apricot600 = Color(0xFFD47C1C);
  static const apricot900 = Color(0xFF7A430A);

  // Eucalyptus — progress, success, speech
  static const sage50 = Color(0xFFF0FDF4);
  static const sage100 = Color(0xFFD6F2E3);
  static const sage400 = Color(0xFF2A9D6F);
  static const sage600 = Color(0xFF1B704E);
  static const sage900 = Color(0xFF0B3B29);

  // Slate teal — discovery, practice
  static const teal50 = Color(0xFFF0F9FA);
  static const teal100 = Color(0xFFD5EDF1);
  static const teal400 = Color(0xFF388E9E);
  static const teal600 = Color(0xFF236572);
  static const teal900 = Color(0xFF0E353D);

  // Berry — error, correction
  static const berry50 = Color(0xFFFFF1F2);
  static const berry100 = Color(0xFFFBDDE0);
  static const berry400 = Color(0xFFE05666);
  static const berry600 = Color(0xFFB83A49);
  static const berry900 = Color(0xFF5E1C24);

  // Heather — secondary / informational
  static const heather50 = Color(0xFFF7F4FB);
  static const heather100 = Color(0xFFE7DFF3);
  static const heather400 = Color(0xFF8B6CB5);
  static const heather600 = Color(0xFF6B4F94);

  // Warm neutrals — light theme (Crisp warm studio)
  static const sand0 = Color(0xFFFFFFFF);     // Pure crisp white card surfaces
  static const sand50 = Color(0xFFF4EFEB);    // Distinct, warm tactile canvas
  static const sand100 = Color(0xFFEBE5DD);   // Recessed sunken wells & inputs
  static const sand200 = Color(0xFFD3C9BD);   // Crisp visible card borders (high contrast)
  static const sand300 = Color(0xFFBDB1A3);   // Strong outline & divider borders
  static const ink900 = Color(0xFF19181B);    // Deep readable ink (15:1 contrast)
  static const ink600 = Color(0xFF555259);    // Clear secondary body text (7:1 contrast)
  static const ink400 = Color(0xFF7E7A85);    // Visible captions & hints (4.6:1 contrast)

  // 100x Luxury Palette (Docs/talkloom_design_specification.md)
  // "Editorial Precision Instrument" (Leica, Braun, Teenage Engineering & The New Yorker)
  static const obsidian = Color(0xFF0B0D11);         // Primary dark canvas
  static const surfaceElevated = Color(0xFF14171F);  // Elevated container & card surface
  static const frostedGlass = Color(0xA614171F);     // 65% translucent frosted glass (0xA6 = 166/255)
  static const brassGold = Color(0xFFE5A93C);        // Hero signature accent & gold pill
  static const brassGoldLight = Color(0xFFF3C766);   // Audio waveform crests & hover glow
  static const brassGoldDeep = Color(0xFF9E6D1C);    // 3D lip & pressed tone
  static const borderSpecular = Color(0x1FFFFFFF);   // Hairline top specular edge (12% white)
  static const borderSpecularSubtle = Color(0x05FFFFFF); // Bottom fade edge (2% white)
  static const textPrimaryDark = Color(0xFFF5F5F3);  // Editorial primary broadsheet ink
  static const textMutedDark = Color(0xFF8A8F9E);    // Secondary metadata ink
  static const emeraldActive = Color(0xFF10B981);    // Spontaneous production & success

  // Warm espresso neutrals — dark theme legacy mapping
  static const espresso0 = Color(0xFF0B0D11);
  static const espresso50 = Color(0xFF14171F);
  static const espresso100 = Color(0xFF1A1E29);
  static const espresso200 = Color(0xFF262B3B);
  static const espresso300 = Color(0xFF3B435C);
  static const cream0 = Color(0xFFF5F5F3);
  static const cream300 = Color(0xFFC0C5D6);
  static const cream500 = Color(0xFF8A8F9E);

  static const white = Color(0xFFFFFFFF);
}
