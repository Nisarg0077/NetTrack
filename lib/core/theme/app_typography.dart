import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized, high-fidelity typography system for NetTrack.
///
/// Uses [Outfit] as the geometric primary display/body typeface and
/// [JetBrains Mono] with tabular figures for telemetry, numbers, and data speeds.
abstract class AppTypography {
  // Primary font family
  static const String fontFamilyPrimary = 'Outfit';
  static const String fontFamilyMono = 'JetBrains Mono';

  // Tabular figures feature for telemetry without number jitter
  static const List<FontFeature> monoFontFeatures = [
    FontFeature.tabularFigures(),
  ];

  /// Telemetry / Numbers font style generator
  static TextStyle mono({
    double fontSize = 13.0,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
    double letterSpacing = -0.2,
    double? height,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontFeatures: monoFontFeatures,
    );
  }

  /// Primary Display font style generator
  static TextStyle primary({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = -0.2,
    double? height,
  }) {
    return GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Complete Light Theme TextTheme
  static TextTheme lightTextTheme(TextTheme base) {
    const textPrimary = AppColors.lightTextPrimary;
    const textSecondary = AppColors.lightTextSecondary;

    return GoogleFonts.outfitTextTheme(base).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: textPrimary,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: textSecondary,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
    );
  }

  /// Complete Dark Theme TextTheme
  static TextTheme darkTextTheme(TextTheme base) {
    const textPrimary = AppColors.darkTextPrimary;
    const textSecondary = AppColors.darkTextSecondary;

    return GoogleFonts.outfitTextTheme(base).copyWith(
      displayLarge: GoogleFonts.outfit(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: textPrimary,
        height: 1.4,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        color: textSecondary,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.0,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
    );
  }
}
