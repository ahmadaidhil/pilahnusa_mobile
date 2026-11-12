import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF22C55E);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primaryDarker = Color(0xFF15803D);
  static const Color primaryLight = Color(0xFF86EFAC);
  static const Color primaryBg = Color(0xFFF0FDF4);
  static const Color primaryBgMd = Color(0xFFDCFCE7);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFF8FAFC);
  static const Color bgSecondary = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Waste Category Colors
  static const Color organik = Color(0xFF22C55E);
  static const Color organikBg = Color(0xFFF0FDF4);
  static const Color organikBorder = Color(0xFFDCFCE7);

  static const Color anorganik = Color(0xFF3B82F6);
  static const Color anorganikBg = Color(0xFFEFF6FF);
  static const Color anorganikBorder = Color(0xFFDBEAFE);

  static const Color b3 = Color(0xFFEF4444);
  static const Color b3Bg = Color(0xFFFEF2F2);
  static const Color b3Border = Color(0xFFFEE2E2);

  // Dark Mode / Scanner
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF222222);
  static const Color darkBorder = Color(0xFF333333);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'organik':
        return organik;
      case 'anorganik':
        return anorganik;
      case 'b3':
        return b3;
      default:
        return primary;
    }
  }

  static Color getCategoryBg(String category) {
    switch (category.toLowerCase()) {
      case 'organik':
        return organikBg;
      case 'anorganik':
        return anorganikBg;
      case 'b3':
        return b3Bg;
      default:
        return primaryBg;
    }
  }

  static Color getCategoryBorder(String category) {
    switch (category.toLowerCase()) {
      case 'organik':
        return organikBorder;
      case 'anorganik':
        return anorganikBorder;
      case 'b3':
        return b3Border;
      default:
        return border;
    }
  }
}

