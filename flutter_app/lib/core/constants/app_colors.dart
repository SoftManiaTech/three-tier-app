import 'package:flutter/material.dart';

/// Central theme colors matching the Product Manager design system
class AppColors {
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryLight = Color(0xFFF0EFFF);
  static const Color secondary = Color(0xFFFF6584);
  static const Color background = Color(0xFFF0F2F5);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color borderColor = Color(0xFFE5E7EB);

  // Palette generator for category badges
  static final List<CategoryColorPalette> categoryPalettes = [
    const CategoryColorPalette(
      bg: Color(0xFFEEF2FF),
      text: Color(0xFF4F46E5),
      border: Color(0xFFC7D2FE),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFFDF2F8),
      text: Color(0xFFDB2777),
      border: Color(0xFFFBCFE8),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFECFDF5),
      text: Color(0xFF059669),
      border: Color(0xFFA7F3D0),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFFFFBEB),
      text: Color(0xFFD97706),
      border: Color(0xFFFDE68A),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFF5F3FF),
      text: Color(0xFF7C3AED),
      border: Color(0xFFDDD6FE),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFEFF6FF),
      text: Color(0xFF2563EB),
      border: Color(0xFFBFDBFE),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFF0FDFA),
      text: Color(0xFF0D9488),
      border: Color(0xFF99F6E4),
    ),
    const CategoryColorPalette(
      bg: Color(0xFFFFF1F2),
      text: Color(0xFFE11D48),
      border: Color(0xFFFECDD3),
    ),
  ];

  static CategoryColorPalette getCategoryPalette(String category) {
    if (category.trim().isEmpty) return categoryPalettes[0];
    int hash = 0;
    for (int i = 0; i < category.length; i++) {
      hash = category.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final int index = hash.abs() % categoryPalettes.length;
    return categoryPalettes[index];
  }
}

class CategoryColorPalette {
  final Color bg;
  final Color text;
  final Color border;

  const CategoryColorPalette({
    required this.bg,
    required this.text,
    required this.border,
  });
}
