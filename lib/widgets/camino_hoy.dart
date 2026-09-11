import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/prefs_service.dart';
import '../theme/app_typography.dart';

/// El camino que la persona firmo en el pacto, vivo dentro de la app.
///
/// Antes el camino era una pantalla del onboarding que ensenaba una fecha
/// y no volvia a aparecer nunca. Aqui se convierte en el hilo que sostiene
/// el dia: cuantas veces se detuvo hoy, y por que dia del camino va.
///
/// El tono importa tanto como el dato. Esto no es una cuota ni una
/// auditoria: cuando el dia esta cumplido, la app se calla el resto del
/// dia y se lo dice como lo que es, un regalo. Nunca senala lo que falta.
class CaminoHoy extends StatelessWidget {
  const CaminoHoy({super.key});

  @override
  Widget build(BuildContext context) {
    // PrefsService no es un notificador: se lee al reconstruir, y el
    // inicio ya recarga del disco antes de pintar.
    final prefs = context.read<PrefsService>();
    final scheme = Theme.of(context).colorScheme;

    // Quien no ha firmado el pacto todavia no tiene camino que mostrar.
    if (prefs.caminoInicio == 0) return const SizedBox.shrink();

    final hechas = prefs.pausasHoy;
    final tope = prefs.topePausas;
    final cumplido = hechas >= tope;
    final dia = _diaDelCamino(prefs.caminoInicio);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: cumplido
            ? scheme.tertiaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Día $dia de tu camino',
            style: AppTypography.caption.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(tope, (i) {
              final lleno = i < hechas;
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  color: lleno
                      ? scheme.secondary
                      : scheme.onSurfaceVariant.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _frase(hechas, tope),
            style: AppTypography.body.copyWith(
              fontSize: 14.5,
              height: 1.35,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Que dia del camino es hoy, contando desde el dia que lo firmo.
  int _diaDelCamino(int inicioYyyymmdd) {
    final y = inicioYyyymmdd ~/ 10000;
    final m = (inicioYyyymmdd % 10000) ~/ 100;
    final d = inicioYyyymmdd % 100;
    final inicio = DateTime(y, m, d);
    final hoy = DateTime.now();
    final dias = DateTime(hoy.year, hoy.month, hoy.day).difference(inicio).inDays;
    return dias < 0 ? 1 : dias + 1;
  }

  /// Nunca se nombra lo que falta. Solo lo que ya pasó.
  ///
  /// Se dice "oraste" y no "te detuviste": lo segundo suena a traduccion,
  /// y en Colombia "parar" se entiende como ponerse de pie.
  String _frase(int hechas, int tope) {
    if (hechas >= tope) {
      return 'Ya está el día.\nLo que queda es tuyo.';
    }
    if (hechas == 0) {
      return 'Cuando abras algo que te distrae,\naquí estoy.';
    }
    if (hechas == 1) return 'Hoy oraste 1 vez.';
    return 'Hoy oraste $hechas veces.';
  }
}
