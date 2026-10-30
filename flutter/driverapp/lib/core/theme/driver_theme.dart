import 'package:flutter/material.dart';

/// HAMHA Logistics — Driver Design System (Cohesive with Customer & Admin)
/// - Background / Scaffold: Warm Cream (#FBF9F5) & Soft Ivory (#F3EFE6)
/// - Cards & Floating Surfaces: Crisp Pure White (#FFFFFF)
/// - Primary Action & Accents: Vibrant Crimson Red (#DC2626)
/// - Strategic Deep Black (#0F172A / #1E293B): Text labels, borders, headers
/// - Ergonomics: High-contrast, large tap targets (minimum 56px) for driver safety
class DriverTheme {
  // Brand Color Palette
  static const Color warmCream = Color(0xFFFBF9F5);
  static const Color softIvory = Color(0xFFF3EFE6);
  static const Color crispWhite = Color(0xFFFFFFFF);
  
  // Crimson Red Accents & Primary Actions
  static const Color crimsonRed = Color(0xFFDC2626);
  static const Color crimsonDark = Color(0xFF991B1B);
  static const Color crimsonLight = Color(0xFFEF4444);
  static const Color crimsonTint = Color(0xFFFEF2F2);

  // Strategic Deep Black Accents & Typography
  static const Color deepBlack = Color(0xFF0F172A);
  static const Color surfaceBlack = Color(0xFF1E293B);
  static const Color headerBlack = Color(0xFF0A0A0C);
  static const Color borderSubtle = Color(0xFFE5E0D8);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  // Status & Telemetry Colors
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusOffline = Color(0xFF64748B);
  static const Color statusWarning = Color(0xFFF59E0B);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmCream,
      primaryColor: crimsonRed,
      colorScheme: const ColorScheme.light(
        primary: crimsonRed,
        secondary: deepBlack,
        surface: crispWhite,
        onSurface: textDark,
      ),
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: crispWhite,
        elevation: 0.8,
        centerTitle: true,
        iconTheme: IconThemeData(color: deepBlack),
        titleTextStyle: TextStyle(
          color: deepBlack,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: crispWhite,
        elevation: 3,
        shadowColor: Colors.black.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderSubtle, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonRed,
          foregroundColor: crispWhite,
          elevation: 3,
          shadowColor: crimsonRed.withAlpha(80),
          minimumSize: const Size.fromHeight(56), // Large tap target for drivers
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlack,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: borderSubtle, width: 1.8),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: crispWhite,
        hintStyle: const TextStyle(color: textMuted, fontSize: 15),
        labelStyle: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSubtle, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSubtle, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: crimsonRed, width: 2.2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: crimsonLight, width: 1.8),
        ),
      ),
    );
  }
}
