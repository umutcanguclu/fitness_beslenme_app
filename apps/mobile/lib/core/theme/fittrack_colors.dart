import 'package:flutter/material.dart';

/// Semantic color tokens that are not covered by [ColorScheme].
///
/// Access via `Theme.of(context).extension<FitTrackColors>()!`.
@immutable
class FitTrackColors extends ThemeExtension<FitTrackColors> {
  const FitTrackColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.textDim,
    required this.primary,
    required this.primaryForeground,
    required this.accent,
    required this.accentForeground,
    required this.danger,
    required this.warning,
    required this.success,
  });

  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color textDim;
  final Color primary;
  final Color primaryForeground;
  final Color accent;
  final Color accentForeground;
  final Color danger;
  final Color warning;
  final Color success;

  static const dark = FitTrackColors(
    background: Color(0xFF0B0F14),
    surface: Color(0xFF121821),
    surfaceAlt: Color(0xFF1A2230),
    border: Color(0xFF25303F),
    textPrimary: Color(0xFFE6EEF7),
    textMuted: Color(0xFF8AA0B8),
    textDim: Color(0xFF5C718A),
    primary: Color(0xFFC6FF3D),
    primaryForeground: Color(0xFF0B0F14),
    accent: Color(0xFF1BE1C1),
    accentForeground: Color(0xFF0B0F14),
    danger: Color(0xFFFF5D73),
    warning: Color(0xFFFFB020),
    success: Color(0xFF31D17B),
  );

  @override
  FitTrackColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? textDim,
    Color? primary,
    Color? primaryForeground,
    Color? accent,
    Color? accentForeground,
    Color? danger,
    Color? warning,
    Color? success,
  }) {
    return FitTrackColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textDim: textDim ?? this.textDim,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      accent: accent ?? this.accent,
      accentForeground: accentForeground ?? this.accentForeground,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      success: success ?? this.success,
    );
  }

  @override
  FitTrackColors lerp(ThemeExtension<FitTrackColors>? other, double t) {
    if (other is! FitTrackColors) return this;
    return FitTrackColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground: Color.lerp(primaryForeground, other.primaryForeground, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentForeground: Color.lerp(accentForeground, other.accentForeground, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
    );
  }
}
