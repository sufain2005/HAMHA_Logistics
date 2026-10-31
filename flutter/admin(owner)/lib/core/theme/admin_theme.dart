import 'package:flutter/material.dart';

/// HAMHA Logistics — Owner & Command Tower Design System
/// Harmonized with Customer & Driver Design System:
/// - Background / Scaffold: Warm Cream (#FBF9F5) & Soft Ivory (#F3EFE6)
/// - Cards, Split-panes & Surfaces: Crisp Pure White (#FFFFFF)
/// - Primary Action & Accents: Vibrant Crimson Red (#DC2626)
/// - Strategic Deep Black (#0F172A / #0A0A0C): Headers, Badges, Typography
/// - Subtle Warm Borders: (#E5E0D8 / #E2E8F0)
class AdminTheme {
  // Brand Color Palette (Cohesive with Customer & Driver)
  static const Color warmCream = Color(0xFFFBF9F5);
  static const Color softIvory = Color(0xFFF3EFE6);
  static const Color crispWhite = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color canvasBg = Color(0xFFFBF9F5);

  // Strategic Deep Black Accents & Typography
  static const Color deepBlack = Color(0xFF0F172A);
  static const Color richBlack = Color(0xFF1E293B);
  static const Color headerBlack = Color(0xFF0A0A0C);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Surfaces & Borders
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarBlack = crispWhite;
  static const Color surfaceBlack = warmCream;
  static const Color borderBlack = borderSubtle;
  static const Color borderSubtle = Color(0xFFE5E0D8);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color borderMedium = Color(0xFFCBD5E1);

  // Crimson Red Accents & Primary Actions
  static const Color crimsonRed = Color(0xFFDC2626);
  static const Color crimsonDark = Color(0xFF991B1B);
  static const Color crimsonLight = Color(0xFFEF4444);
  static const Color crimsonTint = Color(0xFFFEF2F2);

  // Status & Telemetry Colors
  static const Color statusOnline = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFF59E0B);
  static const Color statusBusy = Color(0xFFDC2626);
  static const Color statusOffline = Color(0xFF64748B);

  static ThemeData get theme {
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
        centerTitle: false,
        iconTheme: IconThemeData(color: deepBlack),
        titleTextStyle: TextStyle(
          color: deepBlack,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: crispWhite,
        elevation: 2,
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
          elevation: 2.5,
          shadowColor: crimsonRed.withAlpha(80),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlack,
          side: const BorderSide(color: borderSubtle, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        hintStyle: const TextStyle(color: textMuted, fontSize: 13.5),
        labelStyle: const TextStyle(color: textDark, fontSize: 13.5, fontWeight: FontWeight.w700),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: crimsonRed, width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: crimsonLight, width: 1.5),
        ),
      ),
    );
  }
}

