import 'package:flutter/material.dart';

/// HAMHA Logistics Design System
/// - Deep Black (Scaffold / Headers / Auth)
/// - Crisp White (Cards / Inputs / Typography on Dark)
/// - Crimson Red (Primary Actions / Accents / Logos / Map Lines)
class HamhaTheme {
  // Brand Colors
  static const Color deepBlack = Color(0xFF0D0D0F);
  static const Color cardBlack = Color(0xFF16161A);
  static const Color crimsonRed = Color(0xFFDC2626);
  static const Color crimsonDark = Color(0xFF991B1B);
  static const Color crimsonLight = Color(0xFFEF4444);
  static const Color crispWhite = Color(0xFFFFFFFF);
  static const Color surfaceWhite = Color(0xFFF8FAFC);
  static const Color lightGrey = Color(0xFFF1F5F9);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF0F172A);

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusTransit = Color(0xFF3B82F6);
  static const Color statusDelivered = Color(0xFF10B981);

  // Dark Theme (Auth & Splash)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: deepBlack,
      primaryColor: crimsonRed,
      colorScheme: const ColorScheme.dark(
        primary: crimsonRed,
        secondary: crimsonLight,
        surface: cardBlack,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: crispWhite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: crispWhite),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonRed,
          foregroundColor: crispWhite,
          elevation: 4,
          shadowColor: crimsonRed.withAlpha(100),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBlack,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: crispWhite, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF27272A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: crimsonRed, width: 2),
        ),
      ),
    );
  }

  // Light/Layered Form Theme (Shipment Creation & Data Tables)
  static ThemeData get lightFormTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      primaryColor: crimsonRed,
      colorScheme: const ColorScheme.light(
        primary: crimsonRed,
        secondary: crimsonDark,
        surface: crispWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: crispWhite,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: crispWhite),
      ),
      cardTheme: CardThemeData(
        color: crispWhite,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonRed,
          foregroundColor: crispWhite,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: crispWhite,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: crimsonRed, width: 2),
        ),
      ),
    );
  }
}
