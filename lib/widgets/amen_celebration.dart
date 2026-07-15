import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_typography.dart';

/// Momento "Amén" cinematográfico: celebración a pantalla completa al
/// registrar la oración del día. Diseñado para emocionar (y para que un
/// video vertical de la pantalla se vea precioso): resplandor dorado que
/// crece, "Amén" en serif gigante, versículo y racha. Se cierra al tocar.
Future<void> showAmenCelebration(
  BuildContext context, {
  required int streak,
  required String referencia,
}) {
  HapticFeedback.heavyImpact();
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Amén',
    barrierColor: const Color(0xEE10231C),
    transitionDuration: const Duration(milliseconds: 450),
    transitionBuilder: (context, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
      child: child,
    ),
    pageBuilder: (context, _, __) => _AmenOverlay(
      streak: streak,
      referencia: referencia,
    ),
  );
}

class _AmenOverlay extends StatelessWidget {
  final int streak;
  final String referencia;
  const _AmenOverlay({required this.streak, required this.referencia});

  @override
  Widget build(BuildContext context) {
    const dorado = Color(0xFFD9B37C);
    const marfil = Color(0xFFF7F3EA);
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Resplandor dorado que respira
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1.0),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Container(
                width: 340 * v,
                height: 340 * v,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      dorado.withValues(alpha: 0.55 * v),
                      dorado.withValues(alpha: 0.18 * v),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.elasticOut,
                    builder: (context, v, child) =>
                        Transform.scale(scale: v, child: child),
                    child: Text(
                      'Amén',
                      style: AppTypography.display.copyWith(
                        fontSize: 56,
                        color: marfil,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(width: 34, height: 2, color: dorado),
                  const SizedBox(height: 18),
                  Text(
                    referencia,
                    textAlign: TextAlign.center,
                    style: AppTypography.quote.copyWith(
                      fontSize: 16,
                      color: marfil.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: dorado.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: dorado.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      streak == 1
                          ? '🔥 Día 1 de tu racha'
                          : '🔥 $streak días seguidos con Dios',
                      style: AppTypography.title.copyWith(
                        fontSize: 15,
                        color: marfil,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Toca para continuar',
                    style: AppTypography.caption.copyWith(
                      color: marfil.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
