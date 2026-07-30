import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.dmSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 56,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
        height: 1.02,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 42,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
        height: 1.06,
      ),
      headlineLarge: GoogleFonts.dmSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
        height: 1.08,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
        height: 1.08,
      ),
      headlineSmall: GoogleFonts.dmSans(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
        height: 1.08,
      ),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      titleSmall: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: AppColors.primaryText,
      ),
      labelMedium: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryText,
      ),
      labelSmall: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: AppColors.secondaryText,
      ),
      bodyLarge: GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryText,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryText,
        height: 1.45,
      ),
    );
  }
}
