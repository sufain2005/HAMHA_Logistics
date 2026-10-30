import 'package:flutter/material.dart';

/// HAMHA Logistics Design System (Redesigned: Warm Cream & Crisp White)
/// - Background / Scaffold: Warm Cream (#FBF9F5) & Soft Ivory (#F5F2EB)
/// - Cards & Surfaces: Crisp Pure White (#FFFFFF)
/// - Primary Action & Accents: Vibrant Crimson Red (#DC2626 / #E50914)
/// - Strategic Deep Black (#111827 / #0A0A0A): Headers, badges, borders, and typography
class HamhaTheme {
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
  static const Color richBlack = Color(0xFF1E293B);
  static const Color headerBlack = Color(0xFF0A0A0C);
  static const Color borderSubtle = Color(0xFFE5E0D8);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDark = Color(0xFF0F172A);

  // Status Colors
  static const Color statusPending = Color(0xFFD97706);
  static const Color statusTransit = Color(0xFF2563EB);
  static const Color statusDelivered = Color(0xFF059669);

  // Primary Warm Cream & White Theme
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
        elevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: deepBlack),
        titleTextStyle: TextStyle(
          color: deepBlack,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: crispWhite,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: crimsonRed,
          foregroundColor: crispWhite,
          elevation: 3,
          shadowColor: crimsonRed.withAlpha(90),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.6),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: crispWhite,
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderSubtle, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: crimsonRed, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: crimsonLight, width: 1.5),
        ),
      ),
    );
  }
}
