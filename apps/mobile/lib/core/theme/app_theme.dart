import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fittrack_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    const colors = FitTrackColors.dark;

    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(bodyColor: colors.textPrimary, displayColor: colors.textPrimary);

    final displayStyle = GoogleFonts.barlowCondensed(
      color: colors.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    );

    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.dark,
      primary: colors.primary,
      onPrimary: colors.primaryForeground,
      secondary: colors.accent,
      onSecondary: colors.accentForeground,
      surface: colors.surface,
      onSurface: colors.textPrimary,
      error: colors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      textTheme: baseTextTheme.copyWith(
        displayLarge: displayStyle.copyWith(fontSize: 48),
        displayMedium: displayStyle.copyWith(fontSize: 36),
        displaySmall: displayStyle.copyWith(fontSize: 28),
        headlineMedium: displayStyle.copyWith(fontSize: 22),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.border),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      extensions: const [colors],
    );
  }
}
