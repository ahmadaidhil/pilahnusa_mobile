import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ConfidenceBar extends StatelessWidget {
  final double confidence; // e.g. 88.50%
  final String category;

  const ConfidenceBar({
    super.key,
    required this.confidence,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (confidence / 100.0).clamp(0.0, 1.0);
    final color = AppColors.getCategoryColor(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tingkat Keyakinan AI',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${confidence.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

