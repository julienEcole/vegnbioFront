import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF1F8E9),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32), // Vert feuille profond
        primary: const Color(0xFF2E7D32), // Vert feuille principal
        secondary: const Color(0xFF4CAF50), // Vert légume
        tertiary: const Color(0xFFA5D6A7), // Vert feuille clair
        background: const Color(0xFFF1F8E9), // Vert très pâle, presque blanc
        surface: const Color(0xFFFAFAFA), // Blanc cassé
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        color: Color(0xFFFAFAFA), // Blanc cassé doux
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2E7D32), // Vert feuille profond
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: GoogleFonts.roboto(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF2E7D32), // Vert feuille profond
        indicatorColor: Colors.white.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        headlineLarge: GoogleFonts.roboto(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        headlineMedium: GoogleFonts.roboto(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: GoogleFonts.roboto(
          color: const Color(0xFF1B5E20),
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.roboto(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.roboto(
          color: const Color(0xFF333333),
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.roboto(
          color: const Color(0xFF666666),
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32), // Vert feuille profond
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.roboto(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}