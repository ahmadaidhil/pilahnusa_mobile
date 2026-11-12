import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CategoryBadge extends StatelessWidget {
  final String category;
  final bool isLarge;

  const CategoryBadge({
    super.key,
    required this.category,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getCategoryColor(category);
    final bg = AppColors.getCategoryBg(category);
    final border = AppColors.getCategoryBorder(category);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 14 : 10,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLarge ? 10 : 8,
            height: isLarge ? 10 : 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            category.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: isLarge ? 13 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

