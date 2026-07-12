import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Insignia compacta que muestra la racha actual de dias orando.
class StreakBadge extends StatelessWidget {
  final int streak;
  final bool atRisk;

  const StreakBadge({super.key, required this.streak, this.atRisk = false});

  @override
  Widget build(BuildContext context) {
    final color = atRisk ? AppColors.danger : AppColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            '$streak ${streak == 1 ? 'día' : 'días'} seguidos',
            style: AppTypography.caption.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
