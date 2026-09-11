import 'package:flutter/material.dart';

import '../data/cancion_semana.dart';
import '../theme/app_typography.dart';

/// La canción de la semana, con nombre y artista a la vista.
///
/// Antes la pantalla prometia "te desbloquee una cancion" y no mostraba
/// ninguna: un regalo que no se ve no se siente como regalo.
///
/// La caratula es arte propio a proposito. Las portadas de disco tienen
/// derechos y no se pueden reproducir, asi que se dibuja aqui un sello con
/// la paleta de la app. Si algun dia hay permiso del sello discografico,
/// se cambia por la real sin tocar nada mas.
class TarjetaCancionSemana extends StatelessWidget {
  const TarjetaCancionSemana({super.key, this.compacta = false});

  /// En el inicio va mas baja que en el onboarding.
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final cancion = cancionDeLaSemana();
    const marfil = Color(0xFFF5F0E4);
    const dorado = Color(0xFFD9A93C);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compacta ? 14 : 16),
      decoration: BoxDecoration(
        color: marfil.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: marfil.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          _Caratula(alto: compacta ? 52 : 62),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NUEVA ESTA SEMANA',
                  style: AppTypography.caption.copyWith(
                    color: dorado,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  cancion.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display.copyWith(
                    fontSize: compacta ? 19 : 21,
                    height: 1.12,
                    color: marfil,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cancion.artista,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 14,
                    color: marfil.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un sello dibujado, no una portada de disco.
class _Caratula extends StatelessWidget {
  const _Caratula({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: alto,
      height: alto,
      decoration: BoxDecoration(
        color: const Color(0xFF16342B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9A93C), width: 1.4),
      ),
      child: const Center(
        child:
            Icon(Icons.graphic_eq_rounded, color: Color(0xFFD9A93C), size: 26),
      ),
    );
  }
}
