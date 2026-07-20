import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

/// Respuestas del embudo emocional (viven solo durante el onboarding).
class FunnelAnswers {
  static String horasCelular = '';
  static String tiempoDios = '';
}

const kFunnelIndigo = Color(0xFF18163A);
const kFunnelEsmeralda = Color(0xFF0A3A30);
const kFunnelDorado = Color(0xFFFFD18C);
const kFunnelMarfil = Color(0xFFF7F3EA);

/// Pantalla del embudo: UNA frase, la ovejita actuando la frase, y
/// opciones grandes. Cero adornos compitiendo con la emocion.
class FunnelScreen extends StatelessWidget {
  final String frase;
  final String? subtitulo;
  final String mascota; // ruta del asset de la ovejita
  final List<(String, VoidCallback)> opciones;
  final bool amanecer; // true = el fondo amanece (momento de gracia)

  const FunnelScreen({
    super.key,
    required this.frase,
    this.subtitulo,
    required this.mascota,
    required this.opciones,
    this.amanecer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: amanecer
                ? [const Color(0xFF2E3A2F), const Color(0xFFB98352)]
                : [kFunnelIndigo, kFunnelEsmeralda],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Center(
                  child: Image.asset(mascota, height: 170,
                      filterQuality: FilterQuality.medium),
                ),
                const Spacer(),
                Text(frase,
                    style: AppTypography.display
                        .copyWith(fontSize: 30, color: kFunnelMarfil)),
                if (subtitulo != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitulo!,
                      style: AppTypography.body.copyWith(
                          color: kFunnelMarfil.withValues(alpha: 0.6))),
                ],
                const SizedBox(height: 24),
                for (final (texto, onTap) in opciones) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            opciones.first.$1 == texto && opciones.length == 1
                                ? kFunnelDorado
                                : kFunnelMarfil.withValues(alpha: 0.94),
                        foregroundColor: const Color(0xFF241F10),
                      ),
                      onPressed: onTap,
                      child: Text(texto, textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
