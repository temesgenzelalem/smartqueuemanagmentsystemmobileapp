import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color background = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF121212);

  static ThemeData light() { // Light theme configuration
    // Light theme configuration
    // Light theme configuration
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: primaryGold,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        secondary: primaryGold,
        surface: Colors.black,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
