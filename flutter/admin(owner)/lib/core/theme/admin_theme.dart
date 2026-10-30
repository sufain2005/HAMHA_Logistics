import 'package:flutter/material.dart';

/// HAMHA Logistics — Owner & Command Tower Design System (Web & Desktop Optimized)
/// - Base Backgrounds & Sidebars: Deep Black (#0B0B0E, #111116)
/// - Cards, Split-panes & Surfaces: Crisp White (#FFFFFF) & Soft Slate (#F8FAFC)
/// - Primary Action & Accents: Vibrant Crimson Red (#DC2626)
/// - High-Density Typography & Borders: Deep Black (#0F172A) & Slate (#334155)
class AdminTheme {
  // Brand Palette
  static const Color deepBlack = Color(0xFF0B0B0E);
  static const Color sidebarBlack = Color(0xFF111116);
  static const Color surfaceBlack = Color(0xFF181820);
  static const Color borderBlack = Color(0xFF262632);

  static const Color crispWhite = Color(0xFFFFFFFF);
  static const Color canvasBg = Color(0xFFF4F6F9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  static const Color crimsonRed = Color(0xFFDC2626);
  static const Color crimsonDark = Color(0xFF991B1B);
  static const Color crimsonLight = Color(0xFFEF4444);
  static const Color crimsonTint = Color(0xFFFEF2F2);

  // Status Colors
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusBusy = Color(0xFFDC2626);
  static const Color statusOffline = Color(0xFF64748B);

  // Typography
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvasBg,
      primaryColor: crimsonRed,
      colorScheme: const ColorScheme.light(
        primary: crimsonRed,
        secondary: deepBlack,
        surface: crispWhite,
        onSurface: textDark,
      ),
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlack,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: crispWhite),
        titleTextStyle: TextStyle(
          color: crispWhite,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: crispWhite,
        elevation: 1.5,
        shadowColor: Colors.black.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonRed,
          foregroundColor: crispWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlack,
          side: const BorderSide(color: borderMedium, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: crispWhite,
        hintStyle: const TextStyle(color: textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: crimsonRed, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: crimsonLight, width: 1.5),
        ),
      ),
    );
  }
}

