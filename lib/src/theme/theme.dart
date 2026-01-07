// theme.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppText {
  // Headings
  static TextStyle headingLarge = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.ellipsis),
    fontSize: 22.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textColorPrimary,
  );

  static TextStyle headingMedium = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.ellipsis),
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textColorPrimary,
  );

  static TextStyle headingSmall = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.ellipsis),
    fontSize: 14.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.textColorPrimary,
  );

  // Body Text
  static TextStyle bodyLarge = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.clip),
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textColorPrimary,
  );

  static TextStyle bodyMedium = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.clip),
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textColorSecondary,
  );

  static TextStyle bodySmall = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.clip),
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textColorSecondary,
  );

  // Labels / Captions
  static TextStyle labelLarge = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.clip),
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textColorPrimary,
  );

  static TextStyle labelMedium = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.clip),
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textColorPrimary,
  );

  static TextStyle labelSmall = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.clip),
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.textColorSecondary,
  );

  // Buttons
  static TextStyle button = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.ellipsis),
    fontSize: 16.sp,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // Links / Action Text
  static TextStyle link = GoogleFonts.poppins(
    textStyle: TextStyle(overflow: TextOverflow.ellipsis),
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );
}
