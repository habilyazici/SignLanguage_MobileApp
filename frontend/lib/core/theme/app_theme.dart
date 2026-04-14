import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryStatusGreen = Color(0xFF22C55E); // Confidence > 90%
  static const Color primaryStatusYellow = Color(0xFFF59E0B);
  static const Color primaryStatusRed = Color(0xFFEF4444); // Error / Emergency

  static const Color primaryBlue = Color(0xFF1E3A5F);
  static const Color secondaryBlue = Color(0xFF4DA8DA);
  static const Color softGrey = Color(0xFFF2F4F7);
  static const Color midGrey = Color(0xFF8A94A6);
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);

  // Light Theme Definition
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: softGrey,
      colorScheme: const ColorScheme.light(
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: Colors.white,
        error: primaryStatusRed,
      ),
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: primaryBlue,
        ),
        bodyLarge: GoogleFonts.montserrat(fontSize: 16, color: darkBg),
        bodyMedium: GoogleFonts.montserrat(fontSize: 14, color: darkBg),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          minimumSize: const Size(
            double.infinity,
            56,
          ), // Large accessible touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Dark Theme Definition
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary:
            secondaryBlue, // Using lighter blue as primary on dark theme for contrast
        secondary: secondaryBlue,
        surface: darkSurface,
        error: primaryStatusRed,
      ),
      textTheme:
          GoogleFonts.montserratTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            displayMedium: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            titleLarge: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: GoogleFonts.montserrat(fontSize: 16, color: softGrey),
            bodyMedium: GoogleFonts.montserrat(fontSize: 14, color: softGrey),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryBlue,
          foregroundColor: darkBg,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
