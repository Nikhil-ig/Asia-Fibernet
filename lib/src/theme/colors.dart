import 'package:flutter/material.dart';

class AppColors {
  // Primary Orange Colors (dominant color from logo)
  static const Color primary = Color(0xFFF57C00); // Vibrant orange
  static const Color primaryDark = Color(0xFFBB4D00); // Darker orange
  static const Color primaryLight = Color(0xFFFFAD42); // Lighter orange

  // Secondary Colors (complementary blues)
  static const Color secondary = Color(0xFF1976D2); // Rich blue
  static const Color secondaryDark = Color(0xFF004BA0);
  static const Color secondaryLight = Color(0xFF63A4FF);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA); // Very light grey
  static const Color backgroundDark = Color(0xFF121212); // For dark mode
  static const Color backgroundGradientStart = Color(
    0xFFF57C00,
  ); // Primary orange
  static const Color backgroundGradientEnd = Color(
    0xFFEF6C00,
  ); // Slightly darker orange

  // Surface Colors
  static const Color cardBackground = Colors.white;
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);

  // Input Fields
  static const Color inputBackground = Color(0xFFEEEEEE);
  static const Color inputBackgroundDark = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textColorPrimary = Color(0xFF212121); // Near black
  static const Color textColorSecondary = Color(0xFF757575); // Medium grey
  static const Color textColorHint = Color(0xFFBDBDBD); // Light grey
  static const Color textColorLight = Colors.white; // For dark backgrounds

  // Status Colors
  static const Color success = Color(0xFF43A047); // Softer green
  static const Color successDark = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFFFA000); // Amber warning
  static const Color error = Color(0xFFE53935); // Red error
  static const Color info = Color(0xFF1E88E5); // Blue info

  // Divider
  static const Color dividerColor = Color(0xFFE0E0E0);
  static const Color dividerColorDark = Color(0xFF424242);
  static const Color borderColor = Color(0xFF424242);

  // Accent Colors
  static const Color accent1 = Color(0xFFFDD835); // Yellow accent
  static const Color accent2 = Color(0xFF5C6BC0); // Indigo accent
}
