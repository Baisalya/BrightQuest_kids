import 'package:flutter/material.dart';

class AppTheme {
  static const Color sky = Color(0xFF43B8FF);
  static const Color skyLight = Color(0xFFC7EEFF);
  static const Color navy = Color(0xFF17375E);
  static const Color navyDeep = Color(0xFF102A49);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color purple = Color(0xFF6D4BE8);
  static const Color purpleDeep = Color(0xFF4D2FC5);
  static const Color green = Color(0xFF55C96A);
  static const Color orange = Color(0xFFFFA43B);
  static const Color pink = Color(0xFFFF5CA8);
  static const Color yellow = Color(0xFFFFD54A);
  static const Color cream = Color(0xFFFFFAF0);
  static const Color surfaceBlue = Color(0xFFF1F9FF);
  static const Color surfaceLavender = Color(0xFFF7F3FF);
  static const Color surfaceMint = Color(0xFFF0FBF4);

  static const double radiusSmall = 14;
  static const double radiusMedium = 20;
  static const double radiusLarge = 28;
  static const double radiusHero = 34;

  static ThemeData light({
    bool highContrast = false,
    bool dyslexiaFriendlySpacing = false,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: highContrast ? const Color(0xFF4224BD) : purple,
      brightness: Brightness.light,
      primary: highContrast ? const Color(0xFF4224BD) : purple,
      secondary: highContrast ? const Color(0xFF0067A8) : sky,
      surface: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          highContrast ? const Color(0xFFF7F7F7) : const Color(0xFFF4FAFF),
    );

    final letterSpacing = dyslexiaFriendlySpacing ? 0.35 : null;

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: dyslexiaFriendlySpacing ? 0.4 : -1.1,
          height: 1.05,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: dyslexiaFriendlySpacing ? 0.35 : -0.6,
          height: 1.08,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: letterSpacing,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: dyslexiaFriendlySpacing ? 0.3 : -0.25,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: letterSpacing,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w600,
          height: dyslexiaFriendlySpacing ? 1.55 : 1.35,
          letterSpacing: letterSpacing,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w600,
          height: dyslexiaFriendlySpacing ? 1.5 : 1.3,
          letterSpacing: letterSpacing,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: inkMuted,
          fontWeight: FontWeight.w600,
          height: dyslexiaFriendlySpacing ? 1.45 : 1.25,
          letterSpacing: letterSpacing,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white.withValues(alpha: 0.96),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: Color(0xD9FFFFFF), width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          side: const BorderSide(width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: purple,
        linearTrackColor: Color(0xFFE8E9F6),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x120C3356),
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
