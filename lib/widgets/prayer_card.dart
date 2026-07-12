import 'package:flutter/material.dart';

import '../models/prayer.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Tarjeta que resume una oracion en listados (feed, resultados por
/// categoria, etc). Tocarla navega al detalle (lo maneja el llamador).
class PrayerCard extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onTap;
  final bool destacada;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    this.destacada = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: destacada ? AppColors.tealDeep : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: destacada
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppColors.tealLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      PrayerCategories.displayName(prayer.categoria),
                      style: AppTypography.caption.copyWith(
                        color: destacada ? Colors.white : AppColors.tealDeep,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: destacada ? Colors.white70 : AppColors.inkSoft,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${prayer.duracionEstimadaMin} min',
                    style: AppTypography.caption.copyWith(
                      color: destacada ? Colors.white70 : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                prayer.titulo,
                style: AppTypography.title.copyWith(
                  color: destacada ? Colors.white : AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                prayer.texto,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  color: destacada ? Colors.white.withValues(alpha: 0.9) : AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                prayer.referenciaBiblica,
                style: AppTypography.caption.copyWith(
                  fontStyle: FontStyle.italic,
                  color: destacada ? AppColors.amberLight : AppColors.amber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
