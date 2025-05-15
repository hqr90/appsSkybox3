import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontTheme {
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 48,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 34,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.5,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.underline,
      height: 1.4,
      letterSpacing: 0.75,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0.75,
    ),
  );
}