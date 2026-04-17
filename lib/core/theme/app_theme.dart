import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({
    Color seedColor = const Color(0xFF7C5CBF),
    double fontScale = 1.0,
  }) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    textTheme: _buildTextTheme(fontScale, Brightness.light),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static ThemeData dark({
    Color seedColor = const Color(0xFF7C5CBF),
    double fontScale = 1.0,
  }) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    textTheme: _buildTextTheme(fontScale, Brightness.dark),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );

  // Font boyutunu ölçekle
  static TextTheme _buildTextTheme(double scale, Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white;

    return TextTheme(
      displayLarge: TextStyle(fontSize: 57 * scale, color: baseColor),
      displayMedium: TextStyle(fontSize: 45 * scale, color: baseColor),
      displaySmall: TextStyle(fontSize: 36 * scale, color: baseColor),
      headlineLarge: TextStyle(fontSize: 32 * scale, color: baseColor),
      headlineMedium: TextStyle(fontSize: 28 * scale, color: baseColor),
      headlineSmall: TextStyle(fontSize: 24 * scale, color: baseColor),
      titleLarge: TextStyle(fontSize: 22 * scale, color: baseColor),
      titleMedium: TextStyle(fontSize: 16 * scale, color: baseColor),
      titleSmall: TextStyle(fontSize: 14 * scale, color: baseColor),
      bodyLarge: TextStyle(fontSize: 16 * scale, color: baseColor),
      bodyMedium: TextStyle(fontSize: 14 * scale, color: baseColor),
      bodySmall: TextStyle(fontSize: 12 * scale, color: baseColor),
    );
  }
}
