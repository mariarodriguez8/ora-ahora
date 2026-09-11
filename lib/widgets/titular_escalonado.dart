import 'package:flutter/material.dart';

import '../theme/app_typography.dart';

/// El titular de las pantallas fuertes, escrito como lo escribiria una
/// persona y no una plantilla.
///
/// Tres decisiones, y las tres importan:
///
/// 1. **Nada esta alineado igual.** Cada linea entra un poco mas que la
///    anterior. Una columna pegada al margen izquierdo siempre parece un
///    formulario, por buena que sea la tipografia.
/// 2. **Cada linea cambia de tamano.** La frase respira en vez de leerse
///    como un parrafo.
/// 3. **Una sola palabra lleva el color.** Se marca envolviendola entre
///    asteriscos en el texto: `Ayer le diste *cinco horas* al telefono`.
///    Esa linea va en italica, mas grande y con el color de acento. Una
///    por pantalla, nunca dos.
class TitularEscalonado extends StatelessWidget {
  const TitularEscalonado({
    super.key,
    required this.frase,
    required this.color,
    required this.acento,
    this.base = 30,
  });

  /// El texto, con saltos de linea y opcionalmente *enfasis*.
  final String frase;

  /// Color del texto normal.
  final Color color;

  /// Color de la linea enfatizada.
  final Color acento;

  /// Tamano de referencia; las lineas varian alrededor de el.
  final double base;

  @override
  Widget build(BuildContext context) {
    final lineas = frase.split('\n');
    // Cuanto entra cada linea. Se corta a los 44 para que ni con la letra
    // grande se coma el ancho util.
    double sangria(int i) => (i * 11.0).clamp(0.0, 26.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lineas.length; i++)
          _linea(lineas[i], i, lineas.length, sangria(i)),
      ],
    );
  }

  Widget _linea(String texto, int i, int total, double sangria) {
    final vacia = texto.trim().isEmpty;
    if (vacia) return const SizedBox(height: 10);

    final destacada = texto.contains('*');
    final limpio = texto.replaceAll('*', '');

    // Las lineas del medio bajan un punto y las ultimas se apagan: asi la
    // frase tiene relieve en vez de ser un bloque uniforme.
    double tamano = base;
    if (destacada) {
      tamano = base + 4;
    } else if (i > 0 && i == total - 1) {
      tamano = base - 3;
    } else if (i > 0) {
      tamano = base - 1.5;
    }

    return Padding(
      padding: EdgeInsets.only(left: sangria, bottom: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            limpio,
            maxLines: 1,
            softWrap: false,
            style: AppTypography.display.copyWith(
              fontSize: tamano,
              height: 1.14,
              fontStyle: destacada ? FontStyle.italic : FontStyle.normal,
              color: destacada ? acento : color,
            ),
          ),
        ),
      ),
    );
  }
}
