import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1F1F1F);
  static const Color accent = Color(0xFF1DB954);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textDisabled = Colors.white54;
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.accent,
  colorScheme: ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.accent,
    onPrimary: AppColors.textPrimary,
    onSurface: AppColors.textPrimary,
  ),
  textTheme: const TextTheme(
    titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
    bodyMedium: TextStyle(color: AppColors.textPrimary),
    bodySmall: TextStyle(color: AppColors.textSecondary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: AppColors.textPrimary,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: AppColors.textDisabled),
      foregroundColor: AppColors.textPrimary,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, decoration: TextDecoration.underline),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.card,
    hintStyle: TextStyle(color: AppColors.textSecondary),
    labelStyle: TextStyle(color: AppColors.textSecondary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: AppColors.textSecondary,
    type: BottomNavigationBarType.fixed,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
  ),
  iconTheme: IconThemeData(
    color: AppColors.textPrimary,
  ),
);