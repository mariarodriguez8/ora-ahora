import 'package:flutter/material.dart';

import '../models/prayer.dart';
import '../theme/app_typography.dart';

/// Tarjeta que resume una oracion en listados (feed, resultados por
/// categoria, etc). Tocarla navega al detalle (lo maneja el llamador).
///
/// Dos variantes:
/// - normal: tarjeta clara sobre el fondo papel, titulo serif.
/// - [destacada]: version "hero" sobre fondo primario profundo, usada
///   dentro de la seccion Oracion del dia del inicio.
class PrayerCard extends StatelessWidget {
  final Prayer prayer;
  final VoidCallback onTap;
  final bool destacada;

  /// Si es `true`, la tarjeta se muestra atenuada con un candadito
  /// (contenido de Plus); el `onTap` del llamador abre el paywall.
  final bool bloqueada;

  /// Insignia opcional (ej. "🎙️ Órala en voz alta").
  final String? insignia;

  const PrayerCard({
    super.key,
    required this.prayer,
    required this.onTap,
    this.destacada = false,
    this.bloqueada = false,
    this.insignia,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color cardColor = destacada
        ? scheme.primary
        : (scheme.brightness == Brightness.dark
            ? scheme.surfaceContainerHighest
            : Colors.white.withValues(alpha: 0.72));
    final Color titleColor = destacada ? scheme.onPrimary : scheme.onSurface;
    final Color bodyColor = destacada
        ? scheme.onPrimary.withValues(alpha: 0.82)
        : scheme.onSurfaceVariant;
    final Color labelColor = destacada
        ? scheme.onPrimary.withValues(alpha: 0.85)
        : scheme.primary;
    final Color labelBg = destacada
        ? scheme.onPrimary.withValues(alpha: 0.14)
        : scheme.primaryContainer.withValues(alpha: 0.6);
    final Color quoteColor =
        destacada ? scheme.tertiaryContainer : scheme.secondary;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: destacada
                ? null
                : Border.all(color: scheme.outlineVariant, width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Opacity(
            opacity: bloqueada ? 0.55 : 1.0,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: labelBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      bloqueada
                          ? '🔒 CON PLUS'
                          : PrayerCategories.displayName(prayer.categoria)
                              .toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        fontSize: 10.5,
                        color: labelColor,
                      ),
                    ),
                  ),
                  if (insignia != null && !bloqueada) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        insignia!,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.schedule_rounded, size: 14, color: bodyColor),
                  const SizedBox(width: 4),
                  Text(
                    '${prayer.duracionEstimadaMin} min',
                    style: AppTypography.caption.copyWith(
                      letterSpacing: 0.3,
                      color: bodyColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                prayer.titulo,
                style: AppTypography.headline.copyWith(
                  fontSize: 20,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                prayer.texto,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body.copyWith(
                  fontSize: 14.5,
                  color: bodyColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                prayer.referenciaBiblica,
                style: AppTypography.quote.copyWith(
                  fontSize: 14,
                  color: quoteColor,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}
