import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Headings
  static TextStyle get heading1 => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.1,
    color: Colors.white,
  );

  static TextStyle get heading2 => GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get heading3 => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Body
  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 18, height: 1.5, color: AppColors.textLight);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 16, color: AppColors.textMuted);

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.textSecondary, // General readable dark gray
  );

  // Labels & Helpers
  static TextStyle get label =>
      GoogleFonts.inter(fontSize: 12, color: AppColors.textLight);

  static TextStyle get labelBold => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static TextStyle get buttonText => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle get inputLabel => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}
