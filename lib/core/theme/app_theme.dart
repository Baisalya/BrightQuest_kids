import 'package:flutter/material.dart';

class AppTheme {
  static const Color sky = Color(0xFF4CB7FF);
  static const Color skyLight = Color(0xFFBDEBFF);
  static const Color navy = Color(0xFF183559);
  static const Color inkMuted = Color(0xFF64748B);
  static const Color purple = Color(0xFF6D4BE8);
  static const Color purpleDeep = Color(0xFF4D2FC5);
  static const Color green = Color(0xFF5BCB63);
  static const Color orange = Color(0xFFFFA63D);
  static const Color pink = Color(0xFFFF5CA8);
  static const Color cream = Color(0xFFFFFAF0);
  static const Color surfaceBlue = Color(0xFFF3FAFF);
  static const Color surfaceLavender = Color(0xFFF7F3FF);

  static ThemeData light({bool highContrast = false}) {
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
      scaffoldBackgroundColor: highContrast ? const Color(0xFFF7F7F7) : const Color(0xFFF4FAFF),
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.1,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: navy,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.25,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: navy,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: navy, height: 1.35),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: navy, height: 1.35),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white.withValues(alpha: highContrast ? 1 : 0.96),
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x220C3356),
        shape: RoundedRectangleBorder(
          side: highContrast
              ? const BorderSide(color: Color(0xFF263238), width: 1.2)
              : const BorderSide(color: Color(0x12FFFFFF)),
          borderRadius: const BorderRadius.all(Radius.circular(26)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.28), width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0x14000000)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: scheme.primary.withValues(alpha: highContrast ? 0.2 : 0.13),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected) ? purpleDeep : inkMuted,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w900 : FontWeight.w700,
            fontSize: 11,
          );
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: purple,
        linearTrackColor: purple.withValues(alpha: 0.1),
      ),
      dividerTheme: const DividerThemeData(color: Color(0x12000000), thickness: 1),
    );
  }
}
