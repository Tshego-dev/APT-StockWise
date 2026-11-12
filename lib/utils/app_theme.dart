import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF6C3FC5);
  static const secondary = Color(0xFFE91E8C);
  static const surface = Color(0xFFF8F4FF);
  static const cardBg = Colors.white;

  static const lowStockColor = Color(0xFFFF6B35);
  static const expiryColor = Color(0xFFFF3B30);
  static const safeColor = Color(0xFF34C759);
  static const warningColor = Color(0xFFFF9500);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          secondary: secondary,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: secondary,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardTheme(
          color: cardBg,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
}
