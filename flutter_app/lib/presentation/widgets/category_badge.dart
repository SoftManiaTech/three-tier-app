import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 11.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final cleanCategory = category.trim().isEmpty ? 'General' : category.trim();
    final palette = AppColors.getCategoryPalette(cleanCategory);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Text(
        cleanCategory,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.text,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
