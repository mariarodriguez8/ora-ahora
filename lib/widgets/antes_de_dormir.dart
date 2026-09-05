import 'package:flutter/material.dart';

import '../screens/oracion/oracion_inmersiva_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// El cierre del día.
///
/// La app decía qué hacer al empezar la mañana, pero no daba ninguna razón
/// para volver de noche — que es justo la hora en que la gente abre el
/// teléfono buscando algo y termina en otra parte. Este bloque solo existe
/// a partir de las nueve, y lleva derecho a la oración a oscuras.
class AntesDeDormir extends StatelessWidget {
  /// La oración que se entrega esta noche.
  final String oracion;
  final String? referencia;

  const AntesDeDormir({
    super.key,
    required this.oracion,
    this.referencia,
  });

  /// Solo de noche. De día no tiene sentido y estorba.
  static bool esHora() {
    final h = DateTime.now().hour;
    return h >= 21 || h < 4;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => OracionInmersivaScreen(
            lineas: OracionInmersivaScreen.partir(oracion),
            referencia: referencia,
          ),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF18163A), AppColors.tealDeep],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              child: const Icon(Icons.nightlight_round,
                  color: AppColors.amberLight, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Antes de dormir',
                      style: AppTypography.title.copyWith(
                        color: AppColors.cream,
                        fontSize: 17,
                      )),
                  const SizedBox(height: 4),
                  Text('Un minuto a oscuras, antes de apagar.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.cream.withValues(alpha: 0.72),
                        height: 1.3,
                      )),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.cream.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}
